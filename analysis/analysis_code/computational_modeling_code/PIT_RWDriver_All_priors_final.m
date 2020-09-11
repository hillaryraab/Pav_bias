%%
%Hillary Raab
%2/21/20

%Code that fits RL models to data from a Go/No-Go task in which valence and action are orthogonalized.
%Free parameters include a learning rate, lapse rate (or squashed softmax),
%go bias, pavlovian bias, and reinforcement sensitivity terms.

%Calls RWFit.m

%% Set subjects and parameters

%participant IDs
studyIDAll = [1,2,3,4,5,7,8,9,10,12,13,14,16:27,32,33,36:40,42:44,46:49,51:56,58,131,147:150,154,156,159:167];
Nsubjects = length(studyIDAll);

%set of all models to be fitted
models.headers = {'AlphaPos' 'AlphaNeg' 'Beta' 'squashedSoftmax' 'GoBias' 'PavBias' 'PosRewardSensitivity' 'NegRewardSensitivity' 'LapseRate'};
models.parms(1,:) = [1 0 0 1 0 0 0 0 0]; %LR + squashed softmax
models.parms(2,:) = [1 0 0 1 1 0 0 0 0]; %LR + squashed softmax + Go
models.parms(3,:) = [1 0 0 1 0 1 0 0 0]; %LR + squashed softmax + Pav
models.parms(4,:) = [1 0 0 1 1 1 0 0 0]; %LR + squashed softmax + Go + Pav
models.parms(5,:) = [1 0 0 1 0 0 1 0 0]; %LR + squashed softmax + RewSens
models.parms(6,:) = [1 0 0 1 1 0 1 0 0]; %LR + squashed softmax + Go + RewSens
models.parms(7,:) = [1 0 0 1 0 1 1 0 0]; %LR + squashed softmax + Pav + RewSens
models.parms(8,:) = [1 0 0 1 1 1 1 0 0]; %LR + squashed softmax + Go + Pav + RewSens
models.parms(9,:) = [1 0 0 1 1 1 1 1 0]; %LR + squashed softmax + Go + Pav + RewSens

for numModels = 1:size(models.parms,2)
    
    %choice fxn
    % if beta == 1
    %     choicefxn = 1;
    % elseif squashedSoftmax == 1
    choicefxn = 0;
    %end
    
    LR = sum(models.parms(numModels,1:2));
    RS = sum(models.parms(numModels,7:8));
    
    %add priors? 0=no, 1=yes
    priorsYN=1;
    
    priors = {'log(betapdf(alphaPos,1.1,1.1))','log(betapdf(alphaNeg,1.1,1.1))','log(gampdf(beta,2,3))', ...
        'log(betapdf(squashedSoftmax,1.1,1.1))','log(normpdf(gobias,0,1))','log(gampdf(pavbias,2,3))','log(gampdf(posRewardSens,2,3))', ...
        'log(gampdf(negRewardSens,2,3))','log(betapdf(irrNoise,1.1,1.1))'};
    
    input.parms=models.parms(numModels,:);
    input.parmsName={'AlphaPos' 'AlphaNeg' 'Beta' 'squashedSoftmax' 'GoBias' 'PavBias' 'PosRewardSensitivity' 'NegRewardSensitivity' 'LapseRate'};
    
    %remove name for parameters that are not being fit
    input.parmsName(input.parms==0)=[];
    
    %if only 1 learning rate, then call it Alpha rather than AlphaPos
    if models.parms(numModels,2)==0
        input.parmsName{1}='Alpha'
    end
    
    
    Model{numModels}.Fit.Nparms = sum(input.parms);
    
    %mathematical bounds
    %alphaPos alphaNeg beta squashedSoftmax GoBias PavBias PosRewSens
    %NegRewSens LapseRate
    Model{numModels}.Fit.LB = [0 0 1e-6 0 -inf 0 0 0 0];
    Model{numModels}.Fit.UB = [1 1 inf 1 inf inf inf inf .5];
    
    %plausible bounds that determine initialization values
    Model{numModels}.Fit.pLB = [0 0 1e-6 0 -1 0 0 0 0];
    Model{numModels}.Fit.pUB = [1 1 30 1 2 2 2 2 .5];
    
    %remove any bounds for parameters that are not being fit
    Model{numModels}.Fit.LB(input.parms==0)=[];
    Model{numModels}.Fit.pLB(input.parms==0)=[];
    Model{numModels}.Fit.UB(input.parms==0)=[];
    Model{numModels}.Fit.pUB(input.parms==0)=[];
    
    %remove any priors for parameters that are not being fit
    priors(input.parms==0)=[];
    
    %create input for fmincon that determines if parameter will be fit or not
    fminInput=cell(1,length(input.parms));
    
    count=1;
    for parms=1:length(input.parms)
        if input.parms(parms)==0
            fminInput{parms}='0'; %do not fit parameter
        else
            fminInput{parms}=['x(' num2str(count) ')']; %fit parameter
            count=count+1;
        end
    end
    
    
    clear TaskDataLearning
    %%
    %initialize model comparison if does not already exist
    try modelComparison;
    catch
        modelComparison={};
        modelComparison.bic = [];
        modelComparison.pseudor2=[];
        modelComparison.model={};
        modelComparison.chance = [];
    end
    
    [x, y] = size(modelComparison.bic); %find y dimension so can add a column to modelComparison
    
    cd('~/Box Sync/HartleyLab_SHARED/1_STUDIES/PIT_HillaryShivani/DATA/PIT/')
    
    for s = 1:Nsubjects
        %load participant data
        load([num2str(studyIDAll(s)) 'PIT/' num2str(studyIDAll(s)) '_TaskDataLearning_Session1.mat'])
        TaskDataLearning(find(TaskDataLearning(:,11)==5),:) = []; %remove any trials where responded too early
        
        % run iter times from random initial conditions, to get best fit
        fprintf('Fitting subject %d out of %d...\n',s,Nsubjects)
        for iter = 1:10
            fprintf('Iteration %d...\n',iter)
            
            % determining initial condition
            Model{numModels}.Fit.init(s,iter,:) = rand(1,length(Model{numModels}.Fit.pLB)).*(Model{numModels}.Fit.pUB-Model{numModels}.Fit.pLB)+Model{numModels}.Fit.pLB; % random initialization
            
            % running fmincon to fit the free parameters of the model
            [res,nll] = ...
                fmincon(@(x) PIT_RWFit_All_priors_final(TaskDataLearning,priorsYN,priors,choicefxn,LR,RS,eval(fminInput{1}),eval(fminInput{2}),eval(fminInput{3}),eval(fminInput{4}),eval(fminInput{5}),eval(fminInput{6}),eval(fminInput{7}),eval(fminInput{8}),eval(fminInput{9})),...
                squeeze(Model{numModels}.Fit.init(s,iter,:)),[],[],[],[],Model{numModels}.Fit.LB,Model{numModels}.Fit.UB,[],...
                optimset('maxfunevals',5000,'maxiter',2000,'GradObj','off','DerivativeCheck','off','LargeScale','on','Algorithm','active-set'));
            % GradObj = 'on' to use gradients, 'off' to not use them *** ask us about this if you are interested ***
            % DerivativeCheck = 'on' to have fminsearch compute derivatives numerically and check the ones I supply
            % LargeScale = 'on' to use large scale methods, 'off' to use medium
            
            
            for parms=1:Model{numModels}.Fit.Nparms
                Model{numModels}.Fit.Result.(input.parmsName{parms})(s,iter) = res(parms);
            end
            
            
            Model{numModels}.Fit.Result.Lik(s,iter) = nll;
            Model{numModels}.Fit.Result.Lik  % to view progress so far
        end
        [a, b] = min(Model{numModels}.Fit.Result.Lik(s, :));
        
        Model{numModels}.Fit.Result.BestFit(s,1) = s;
        
        for parms=1:Model{numModels}.Fit.Nparms
            Model{numModels}.Fit.Result.BestFit(s,parms+1) = [Model{numModels}.Fit.Result.(input.parmsName{parms})(s,b)];
        end
        
        Model{numModels}.Fit.Result.BestFit(s,parms+2) = [Model{numModels}.Fit.Result.Lik(s,b)];
        
        
        useLogLik = Model{numModels}.Fit.Result.BestFit(s,end);
        % When computing AIC/BIC we have to take back out the prior
        % probabilities of the parameters and convert from maximum a posterior to lik.
        if priorsYN == 1
            count = 1;
            
            if input.parms(1) == 1
                if (~isinf(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))) && ~isnan(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))))
                    useLogLik = useLogLik + log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1));
                end
                count= 1 + count;
            end
            if input.parms(2) == 1
                if (~isinf(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))) && ~isnan(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))))
                    useLogLik = useLogLik + log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1));
                end
                count= 1 + count;
            end
            if input.parms(3) == 1
                if (~isinf(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))) && ~isnan(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))))
                    useLogLik = useLogLik + log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3));
                end
                count= 1 + count;
            end
            if input.parms(4) == 1
                if (~isinf(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))) && ~isnan(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))))
                    useLogLik = useLogLik + log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1));
                end
                count= 1 + count;
            end
            if input.parms(5) == 1
                if (~isinf(log(normpdf(Model{numModels}.Fit.Result.BestFit(s,count+1),0,1))) && ~isnan(log(normpdf(Model{numModels}.Fit.Result.BestFit(s,count+1),0,1))))
                    useLogLik = useLogLik + log(normpdf(Model{numModels}.Fit.Result.BestFit(s,count+1),0,1));
                end
                count= 1 + count;
            end
            if input.parms(6) == 1
                if (~isinf(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))) && ~isnan(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))))
                    useLogLik = useLogLik + log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3));
                end
                count= 1 + count;
            end
            if input.parms(7) == 1
                if (~isinf(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))) && ~isnan(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))))
                    useLogLik = useLogLik + log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3));
                end
                count= 1 + count;
            end
            if input.parms(8) == 1
                if (~isinf(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))) && ~isnan(log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3))))
                    useLogLik = useLogLik + log(gampdf(Model{numModels}.Fit.Result.BestFit(s,count+1),2,3));
                end
                count= 1 + count;
            end
            if input.parms(9) == 1
                if (~isinf(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))) && ~isnan(log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1))))
                    useLogLik = useLogLik + log(betapdf(Model{numModels}.Fit.Result.BestFit(s,count+1),1.1,1.1));
                end
                count= 1 + count;
            end
            
        end
        
        %logLik(s,1) = useLogLik; % useLogLik is posterior and
        %logLik is logLikelihood; can use this to extract log
        %likelihood from log posterior
        
        %Compare model fits and compare to null (random chooser)
        nObs = length(TaskDataLearning);
        modelComparison.bic(s,y+1) = log(nObs)*(Model{numModels}.Fit.Nparms)-2*(-1*useLogLik);
        modelComparison.aic(s,y+1) = 2*(Model{numModels}.Fit.Nparms)-2*(-1*useLogLik);
        ll_null = log(.5)*nObs;
        modelComparison.pseudor2(s,y+1) = 1 - (-1*useLogLik)/ll_null; %variance above and beyond null model
        clear TaskDataLearning
    end
    
    
    if priorsYN~=1
        modelComparison.model(end+1) = {strjoin(input.parmsName,'+')};
    elseif priorsYN==1
        modelComparison.model(end+1) = strcat({strjoin(input.parmsName,'+')},{'_priors'});
    end
    Model{numModels}.Fit.Result.BestFit;
    
    
end
%% Simulate Data for Child Friendly Go/No Go Task for which Action and Valence are Orthogonalized
%Hillary Raab
%07.02.19

%% Simulation, Choice Behavior Generation, and Model Fitting
%output: 
%   Simulation.Model: simulated parameters 
%   Simulation.TaskDataLearning: simulated choice behavior from those parameters
%   Simulation.Fit: fit simulated choice behavior to all 9 models
%input: 
%   numSimulations: how many simulations do you want to run
%   subjParms: the parameter estimates that you want to use to boot-strap samples from
%   simModel: from which model do you want to generate parameters
%   fitModels: how many models you want to fit but must be in order listed
%   below


function [Simulation] = PIT_taskSimulation_Driver_subjParms(numSimulations,subjParms,simModel,fitModels)

%%%%%%%%%%%%%%%%%%
%modify parameters
%%%%%%%%%%%%%%%%%%
%make sure the random number generator is shuffled
rng('shuffle')

%all possible models
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



%simulations are boot-strapped from participant parameter estimates
%(subjFit)
%Simulation.Model.simDistribution = {'betarnd(1.1,1.1,[numSimulations,1])','betarnd(1.1,1.1,[numSimulations,1])','gamrnd(2,3,[numSimulations,1])', ...
%    'betarnd(1.1,1.1,[numSimulations,1])','normrnd(0,1,[numSimulations,1])','gamrnd(2,3,[numSimulations,1])','gamrnd(2,3,[numSimulations,1])', ...
%    'gamrnd(2,3,[numSimulations,1])','betarnd(1.1,1.1,[numSimulations,1])'};

%create list of parameters
Simulation.Model.parmsHeader = models.headers;
Simulation.Model.parms=models.parms(simModel,:);
Simulation.Model.parmsName={'AlphaPos' 'AlphaNeg' 'Beta' 'squashedSoftmax' 'GoBias' 'PavBias' 'PosRewardSensitivity' 'NegRewardSensitivity' 'LapseRate'};

%remove name for parameters that are not being fit
Simulation.Model.parmsName(Simulation.Model.parms==0)=[];
%Simulation.Model.simDistribution(Simulation.Model.parms==0) = [];

%if only 1 learning rate, then call it Alpha rather than AlphaPos
if models.parms(simModel,2)==0
    Simulation.Model.parmsName{1}='Alpha';
end

%Total number of parameters being fit
Simulation.Model.Nparms = sum(models.parms(simModel,:));

%starts at 2 b/c subjID is column 1
counter = 2;

%boot-strap the parameters estimated from subjs
for numParms = 1:length(Simulation.Model.parms)
    if Simulation.Model.parms(numParms) == 1
        Simulation.Model.simParmValues(:,numParms) = datasample(subjParms.Result.BestFit(:,counter),numSimulations);
        counter = 1 + counter;
    else
        Simulation.Model.simParmValues(:,numParms) = zeros(numSimulations,1);
    end
end




%set options: 0=off; 1=on
fitData = 1; %fits data from choice behavior simulation; choice Behavior must be set to 1
priorsYN=1; %adds priors to the model fitting

%LR is learning rate and RS is reinforcement sensitivity
%are there 1 or 2 of these? input this into fitting script
LR = sum(models.parms(simModel,1:2));
RS = sum(models.parms(simModel,7:8));


%%%%%%%%%%%%%
%Run choice simulation
%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% simulate choice behavior for each set of parameters %%%%%%%%%%

for count=1:numSimulations
    
    [TaskDataLearning_sim, V, q] = PIT_taskSimulation(LR,RS,Simulation.Model.simParmValues(count,1), ...
        Simulation.Model.simParmValues(count,2),Simulation.Model.simParmValues(count,3),Simulation.Model.simParmValues(count,4), ...
        Simulation.Model.simParmValues(count,5), Simulation.Model.simParmValues(count,6),Simulation.Model.simParmValues(count,7), ...
        Simulation.Model.simParmValues(count,8), Simulation.Model.simParmValues(count,9));
    
    Simulation.TaskDataLearning{count} = TaskDataLearning_sim;
    
    clear TaskDataLearning_sim
end

%%%%%%%%%%%%%%%%% now fit all 9 models to simulated choice behavior %%%%%%%%%%

for numModelFit = 1:fitModels %model to which data is fit
    if fitData==1
        
        %choicefxn = 0 is squashed softmax
        choicefxn = 0;
        LR = sum(models.parms(numModelFit,1:2));
        RS = sum(models.parms(numModelFit,7:8));
        
        %add priors? 0=no, 1=yes
        priorsYN=1;
        
        priors = {'log(betapdf(alphaPos,1.1,1.1))','log(betapdf(alphaNeg,1.1,1.1))','log(gampdf(beta,2,3))', ...
            'log(betapdf(squashedSoftmax,1.1,1.1))','log(normpdf(gobias,0,1))','log(gampdf(pavbias,2,3))','log(gampdf(posRewardSens,2,3))', ...
            'log(gampdf(negRewardSens,2,3))','log(betapdf(irrNoise,1.1,1.1))'};
        
        input.parms=models.parms(numModelFit,:);
        input.parmsName={'AlphaPos' 'AlphaNeg' 'Beta' 'squashedSoftmax' 'GoBias' 'PavBias' 'PosRewardSensitivity' 'NegRewardSensitivity' 'LapseRate'};
        
        %remove name for parameters that are not being fit
        input.parmsName(input.parms==0)=[];
        
        %if only 1 learning rate, then call it Alpha rather than AlphaPos
        if models.parms(numModelFit,2)==0
            input.parmsName{1}='Alpha';
        end
        
        
        Simulation.Fit{numModelFit}.Nparms = sum(input.parms);
        
        %mathematical bounds
        %alphaPos alphaNeg beta squashedSoftmax GoBias PavBias PosRewSens
        %NegRewSens LapseRate
        Simulation.Fit{numModelFit}.LB = [0 0 1e-6 0 -inf 0 0 0 0];
        Simulation.Fit{numModelFit}.UB = [1 1 inf 1 inf inf inf inf .5];
        
        %plausible bounds that determine initialization values
        Simulation.Fit{numModelFit}.pLB = [0 0 1e-6 0 -1 0 0 0 0];
        Simulation.Fit{numModelFit}.pUB = [1 1 30 1 2 2 2 2 .5];
        
        %remove any bounds for parameters that are not being fit
        Simulation.Fit{numModelFit}.LB(input.parms==0)=[];
        Simulation.Fit{numModelFit}.pLB(input.parms==0)=[];
        Simulation.Fit{numModelFit}.UB(input.parms==0)=[];
        Simulation.Fit{numModelFit}.pUB(input.parms==0)=[];
        
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
        
        
        % initialize model comparison if does not already exist
        try Simulation.modelComparison;
        catch
            Simulation.modelComparison={};
            Simulation.modelComparison.bic = [];
            Simulation.modelComparison.pseudor2=[];
            Simulation.modelComparison.model={};
            Simulation.modelComparison.chance = [];
        end
        
        [x, y] = size(Simulation.modelComparison.bic); %find y dimension so can add a column to modelComparison
        
        for sim = 1:numSimulations
            
            %load each simulated participant
            TaskDataLearning = Simulation.TaskDataLearning{sim};
            
            % run iter times from random initial conditions, to get best fit
            fprintf('Fitting simulation %d out of %d...\n',sim,numSimulations)
            for iter = 1:10
                fprintf('Iteration %d...\n',iter)
                
                % determining initial condition
                Simulation.Fit{numModelFit}.init(sim,iter,:) = rand(1,length(Simulation.Fit{numModelFit}.pLB)).*(Simulation.Fit{numModelFit}.pUB-Simulation.Fit{numModelFit}.pLB)+Simulation.Fit{numModelFit}.pLB; % random initialization
                
                % running fmincon to fit the free parameters of the model
                [res,nll] = ...
                    fmincon(@(x) PIT_RWSimFit_All_priors(TaskDataLearning,priorsYN,priors,choicefxn,LR,RS,eval(fminInput{1}),eval(fminInput{2}),eval(fminInput{3}),eval(fminInput{4}),eval(fminInput{5}),eval(fminInput{6}),eval(fminInput{7}),eval(fminInput{8}),eval(fminInput{9})),...
                    squeeze(Simulation.Fit{numModelFit}.init(sim,iter,:)),[],[],[],[],Simulation.Fit{numModelFit}.LB,Simulation.Fit{numModelFit}.UB,[],...
                    optimset('maxfunevals',5000,'maxiter',2000,'GradObj','off','DerivativeCheck','off','LargeScale','on','Algorithm','active-set'));
                % GradObj = 'on' to use gradients, 'off' to not use them *** ask us about this if you are interested ***
                % DerivativeCheck = 'on' to have fminsearch compute derivatives numerically and check the ones I supply
                % LargeScale = 'on' to use large scale methods, 'off' to use medium
                
                
                for parms=1:Simulation.Fit{numModelFit}.Nparms
                    Simulation.Fit{numModelFit}.Result.(input.parmsName{parms})(sim,iter) = res(parms);
                end
                
                Simulation.Fit{numModelFit}.Result.Lik(sim,iter) = nll;
                Simulation.Fit{numModelFit}.Result.Lik;
            end
            [a, b] = min(Simulation.Fit{numModelFit}.Result.Lik(sim, :));
            
            Simulation.Fit{numModelFit}.Result.BestFit(sim,1) = sim;
            
            for parms=1:Simulation.Fit{numModelFit}.Nparms
                Simulation.Fit{numModelFit}.Result.BestFit(sim,parms+1) = [Simulation.Fit{numModelFit}.Result.(input.parmsName{parms})(sim,b)];
            end
            
            Simulation.Fit{numModelFit}.Result.BestFit(sim,parms+2) = [Simulation.Fit{numModelFit}.Result.Lik(sim,b)];
            
            
            useLogLik = Simulation.Fit{numModelFit}.Result.BestFit(sim,end);
            
            % When computing AIC/BIC we have to take back out the prior
            % probabilities of the parameters and convert from maximum a posterior to lik.
            if priorsYN == 1
                count = 1;
                
                if input.parms(1) == 1
                    if (~isinf(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))) && ~isnan(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))))
                        useLogLik = useLogLik + log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1));
                    end
                    count= 1 + count;
                end
                if input.parms(2) == 1
                    if (~isinf(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))) && ~isnan(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))))
                        useLogLik = useLogLik + log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1));
                    end
                    count= 1 + count;
                end
                if input.parms(3) == 1
                    if (~isinf(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))) && ~isnan(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))))
                        useLogLik = useLogLik + log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3));
                    end
                    count= 1 + count;
                end
                if input.parms(4) == 1
                    if (~isinf(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))) && ~isnan(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))))
                        useLogLik = useLogLik + log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1));
                    end
                    count= 1 + count;
                end
                if input.parms(5) == 1
                    if (~isinf(log(normpdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),0,1))) && ~isnan(log(normpdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),0,1))))
                        useLogLik = useLogLik + log(normpdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),0,1));
                    end
                    count= 1 + count;
                end
                if input.parms(6) == 1
                    if (~isinf(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))) && ~isnan(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))))
                        useLogLik = useLogLik + log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3));
                    end
                    count= 1 + count;
                end
                if input.parms(7) == 1
                    if (~isinf(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))) && ~isnan(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))))
                        useLogLik = useLogLik + log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3));
                    end
                    count= 1 + count;
                end
                if input.parms(8) == 1
                    if (~isinf(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))) && ~isnan(log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3))))
                        useLogLik = useLogLik + log(gampdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),2,3));
                    end
                    count= 1 + count;
                end
                if input.parms(9) == 1
                    if (~isinf(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))) && ~isnan(log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1))))
                        useLogLik = useLogLik + log(betapdf(Simulation.Fit{numModelFit}.Result.BestFit(sim,count+1),1.1,1.1));
                    end
                    count = 1 + count;
                end
                
            end
            
            %logLik(sim,1) = useLogLik; % useLogLik is posterior and
            %logLik is logLikelihood; can use this to extract log
            %likelihood from log posterior
            
            %Compare model fits and compare to null (random chooser)
            nObs = length(TaskDataLearning);
            Simulation.modelComparison.bic(sim,y+1) = log(nObs)*(Simulation.Fit{numModelFit}.Nparms)-2*(-1*useLogLik);
            Simulation.modelComparison.aic(sim,y+1) = 2*(Simulation.Fit{numModelFit}.Nparms)-2*(-1*useLogLik);
            ll_null = log(.5)*nObs;
            Simulation.modelComparison.chance(sim,y+1) = ll_null;
            Simulation.modelComparison.pseudor2(sim,y+1) = 1 - (-1*useLogLik)/ll_null; %variance above and beyond null model
            
            clear TaskDataLearning
        end
        
        if priorsYN~=1
            Simulation.modelComparison.model(end+1) = {strjoin(input.parmsName,'+')};
        elseif priorsYN==1
            Simulation.modelComparison.model(end+1) = strcat({strjoin(input.parmsName,'+')},{'_priors'});
        end
        Simulation.Fit{numModelFit}.Result.BestFit;
        
        
    end
    
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%functions for RW_Driver and RW_Fit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%
%simulated model fitting
%%%%%%%%%%%%%%%

function [nll, V] = PIT_RWSimFit_All_priors(TaskDataLearning,priorsYN,priors,choicefxn,LR,RS,alphaPos,alphaNeg,beta,squashedSoftmax,gobias,pavbias,posRewardSens,negRewardSens,irrNoise)
if LR==1
    alphaNeg=alphaPos;
end

if RS==1
    negRewardSens=posRewardSens;
end

lik = 0;   % log likelihood

%Stimuli, response, outcome
stimType=TaskDataLearning(:,1); %stimuli type from (1:4)
response=(TaskDataLearning(:,2)); %response: go (1) or no go (2)
outcome=TaskDataLearning(:,3); %outcome: reward (1), nothing (0), lose (-1)

V = zeros(1,length(unique(stimType)));  % initialize stimuli values
q = zeros(length(unique(stimType)),length(unique(response))); % initialize q values
w = zeros(length(unique(stimType)),length(unique(response))); % initialize combined w values

for i = 1:length(TaskDataLearning)
    %n=find(not(stimType(i)==(1:4))); %nonchosen stim
    
    wt = [w(stimType(i),response(i)); w(stimType(i),3-response(i))]; % wt = [w(chosen); w(unchosen)]
    if choicefxn == 1
        x = irrNoise + (1-2*irrNoise).* exp(beta*wt(1))/sum(exp(beta*wt)); %economides et al 2015; lapse rate between 0 and .5; 0 not applied; .5 at chance performance
    elseif choicefxn == 0
        x = exp(wt(1))/sum(exp(wt)) .* (1-squashedSoftmax) + (squashedSoftmax./2); %squashed softmax; lapse rate between 0 and 1; 0 not applied; 1 at chance performance
    end
    lik = lik + log(x);
    
    
    if RS == 0 || outcome(i) == 0 %no reward sensitivity parameter
        % updating the value of the chosen stimulus according to the reward received (on choice as well as single trials)
        vPE = outcome(i) - V(stimType(i)); %pavlovian PE
        qPE = outcome(i) - q(stimType(i),response(i)); %instrumental PE
    elseif RS == 1 && outcome(i)==1 || RS == 1 && outcome(i)==-1 % reward sensitivity parameter
        % updating the value of the chosen stimulus according to the reward received (on choice as well as single trials)
        vPE = posRewardSens.*outcome(i) - V(stimType(i)); %pavlovian PE
        qPE = posRewardSens.*outcome(i) - q(stimType(i),response(i)); %instrumental PE
    elseif RS == 2 %reward sensitivity parameter for rewards and a reward sensitivity for punishment
        if outcome(i) == 1
            vPE = posRewardSens * outcome(i) - V(stimType(i)); %pavlovian PE
            qPE = posRewardSens * outcome(i) - q(stimType(i),response(i)); %instrumental PE
        elseif outcome(i) == -1
            vPE = negRewardSens * outcome(i) - V(stimType(i)); %pavlovian PE
            qPE = negRewardSens * outcome(i) - q(stimType(i),response(i)); %instrumental P
        end
    end
    
    if vPE > 0 %learning rate
        V(stimType(i)) = V(stimType(i)) + alphaPos*vPE; %pavlovian update
    elseif vPE < 0
        V(stimType(i)) = V(stimType(i)) + alphaNeg*vPE;
    end
    
    if qPE > 0 % Pos PE
        q(stimType(i),response(i)) = q(stimType(i),response(i))+ alphaPos*qPE; %instrumental update
    elseif qPE < 0 % Neg PE
        q(stimType(i),response(i)) = q(stimType(i),response(i))+ alphaNeg*qPE; %instrumental update
    end
    
    
    if (response(i) == 1)
        w(stimType(i),response(i)) = q(stimType(i),response(i)) + gobias + pavbias*V(stimType(i));
    else
        w(stimType(i),response(i)) = q(stimType(i),response(i)); %included + pavbias*V(stimType(i)) here and for go; included + pavbias*V(stimType(i)) here instead of go but both ways did not provide a better fit
    end
end

% % OPTIONAL: putting a prior on the parameters
if priorsYN==1
    %for any parameters with the range 0 to 1, betapdf(x,1.1,1.1)
    %for any parameters with the range -inf to inf, normpdf(x,0,1)
    %for any parameters with the range 0 to inf, gampdf(x,2,3)
    for numPriors = 1:length(priors)
        lik = lik + eval(priors{numPriors});
    end
end

nll = -lik;  % so we can minimize the function rather than maximize so changing a negative number (lik) into a positive number (nll)
%if we have priors, the lik is actually the maximum a posteriori.
end
end
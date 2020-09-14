%% Hillary Raab
% September 5, 2019
% Use parameter values estimated from participant behavior to then simulate
% choice data and get accuracy for each of the 9 models

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

simAccuracy_all = [];

for numModels = 1:length(models.parms)
    
    %create list of parameters
    Simulation.Model.parmsHeader = models.headers;
    Simulation.Model.parms=models.parms(numModels,:);
    Simulation.Model.parmsName={'AlphaPos' 'AlphaNeg' 'Beta' 'squashedSoftmax' 'GoBias' 'PavBias' 'PosRewardSensitivity' 'NegRewardSensitivity' 'LapseRate'};
    
    %remove name for parameters that are not being fit
    Simulation.Model.parmsName(Simulation.Model.parms==0)=[];
    
    %if only 1 learning rate, then call it Alpha rather than AlphaPos
    if models.parms(numModels,2)==0
        Simulation.Model.parmsName{1}='Alpha';
    end
    
    %Total number of parameters being fit
    Simulation.Model.Nparms = sum(models.parms(numModels,:));
    
    %load participant fit data
    subjFits = load('../../../data/computational_model_fits/Fits_n61_infinite_priors.mat');
    fnames = fieldnames(subjFits);
    
    counter = 2;
    
    for numParms = 1:length(Simulation.Model.parms)
        if Simulation.Model.parms(numParms) == 1
            eval(['Simulation.Model.simParmValues(:,numParms) = subjFits.' fnames{numModels+9} '.Result.BestFit(:,counter)'])
            counter = 1 + counter;
        else
            eval(['Simulation.Model.simParmValues(:,numParms) = zeros(length(subjFits.' fnames{numModels+9} '.Result.BestFit),1)'])
        end
    end
    
    %set options: 0=off; 1=on
    fitData = 0; %fits data from choice behavior simulation; choice Behavior must be set to 1
    priorsYN=1; %adds priors to the model fitting
    
    LR = sum(models.parms(numModels,1:2));
    RS = sum(models.parms(numModels,7:8));
    
    
    %%%%%%%%%%%%%
    %Run choice simulation
    %%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%% simulate choice behavior for each set of parameters %%%%%%%%%%
    for count=1:length(Simulation.Model.simParmValues)
        
        [TaskDataLearning_sim, V, q] = PIT_taskSimulation(LR,RS,Simulation.Model.simParmValues(count,1), ...
            Simulation.Model.simParmValues(count,2),Simulation.Model.simParmValues(count,3),Simulation.Model.simParmValues(count,4), ...
            Simulation.Model.simParmValues(count,5), Simulation.Model.simParmValues(count,6),Simulation.Model.simParmValues(count,7), ...
            Simulation.Model.simParmValues(count,8), Simulation.Model.simParmValues(count,9));
        
        Simulation.TaskDataLearning{numModels}{count} = TaskDataLearning_sim;
        
        %note accurate responses
        %for sim = 1:length(Simulation.TaskDataLearning)
        model = ones(180,1)*numModels;
        simNum = ones(180,1)*count;
        trialType = TaskDataLearning_sim(:,1); %{sim}(:,1);
        trialNum = [1:180]';
        corrResp = NaN(180,1);
        
        %correct response Go (response = 1) on trial types 1 or 2 (GW, GAL)
        corrResp(:,1) = double(TaskDataLearning_sim(:,1)==1 & TaskDataLearning_sim(:,2)==1);
        corrResp(:,2) = double(TaskDataLearning_sim(:,1)==2 & TaskDataLearning_sim(:,2)==1);
        %correct response NoGo (response = 2) on trial types 3 or 4 (NGW, NGAL)
        corrResp(:,3) = double(TaskDataLearning_sim(:,1)==3 & TaskDataLearning_sim(:,2)==2);
        corrResp(:,4) = double(TaskDataLearning_sim(:,1)==4 & TaskDataLearning_sim(:,2)==2);
        
        %do this for model,
        simAccuracy = [model, simNum, trialNum, trialType, sum(corrResp,2)];
        simAccuracy_all = [simAccuracy_all; simAccuracy];
        simAccuracy = [];
        clear TaskDataLearning_sim
    end
end

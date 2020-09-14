%% Simulate Data for Child Friendly Go/No Go Task for which Action and Valence are Orthogonalized
%Hillary Raab
%12.01.17

function [TaskDataLearning_sim, V, q] = PIT_taskSimulation(LR,RS,alphaPos,alphaNeg,beta,squashedSoftmax,gobias,pavbias,posRewardSens,negRewardSens,irrNoise)
%%% StimType is a vector of n trials filled with 1-4 to note which trial
%%% type. 1 Go to Win. 2 Go to Avoid Losing. 3 No Go to Win. 4 No
%%% Go to Avoid Losing. OutcomeValidFoil is a matrix of 1 and 2 for valid
%%% outcome or foil for each of the four stimulus types.


%%%%%%%%%%%%%%%%%%%% Modify if task design differs
numTotalTrials = 180;
numBlocks = 3;
numResponses=2; %either go or no go

if LR==1
    alphaNeg=alphaPos;
end
%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%
%Create trial structure and probabilistic outcome structure
%%%%%%%%%%%%%%%%%%

%%% Trial type matrix
TrialTypeLearning = [];
RandTrialTypeLearning = [];
for blocks = 1:numBlocks %distribute trial types evenly across 3 blocks (each block 60 trials)
    TrialTypeLearning1=repmat([1 2 3 4],[1,(numTotalTrials/(numBlocks*4))]);  % 1 go reward; 2 go punishment; 3 no-go reward; 4 no-go punishment;
    TrialTypeLearning=[TrialTypeLearning TrialTypeLearning1];
    RandTrialTypeLearning1=TrialTypeLearning1(randperm(size(TrialTypeLearning1,2)));
    RandTrialTypeLearning = [RandTrialTypeLearning RandTrialTypeLearning1]; %matrix of trial types 1 Go Win 2 Go Avoid Losing 3 No Go Win 4 No Go Avoid Losing
end
clear TrialTypeLearning1 RandTrialTypeLearning1 TrialTypeLearning

%%% Probabilistic outcome matrix
Pmat = [];
PmatAllRob = [];
for robots = 1:4
    for blocks = 1:numBlocks
        PmatTemp = [zeros(12,1)+1; ones(3,1)+1];
        PmatTemp = PmatTemp(randperm(numTotalTrials/(numBlocks*4)));
        Pmat = [Pmat; PmatTemp];
    end
    PmatAllRob = [PmatAllRob Pmat]; %matrix of outcomes 1 is actual; 2 is foil
    Pmat = [];
end
clear PmatTemp Pmat

stimType=RandTrialTypeLearning';
outcomeValidFoil=PmatAllRob;


%%%%%%%%%%%%%%%%% 
%value and action weight computations
%%%%%%%%%%%%%%%%% 
%lik = 0;   % log likelihood

%initialize variables
V = zeros(1,length(unique(stimType)));  % initialize stimuli values
q = zeros(length(unique(stimType)),numResponses); % initialize q values
w = zeros(length(unique(stimType)),numResponses); % initialize combined w values
numTrials = [1 1 1 1];
response = zeros(length(stimType),1);
outcome = zeros(length(stimType),1);

%simulate choice
for i = 1:length(stimType)

    % combine the weighted responses
    wt = [w(stimType(i),1); w(stimType(i),2)]; % wt = [w(Go); w(No-Go)]

    %squashed softmax equation to figure out which choice
    x = exp(wt(1))/sum(exp(wt)) .* (1-squashedSoftmax) + (squashedSoftmax./2);
    if rand(1) < x 
        response(i) = 1; % go response
    else
        response(i) = 2; %no-go response
    end
    

    %{ 
if w(stimType(i),1)>w(stimType(i),2)
        coinFlip = rand(1);
        while coinFlip==beta
            coinFlip=rand(1);
        end
        if coinFlip<beta
            response(i)=1; %go
        elseif coinFlip>beta
            response(i)=2; %no go
        end
   elseif w(stimType(i),1)==w(stimType(i),2)
        coinFlip = rand(1);
        while coinFlip==.5
            coinFlip=rand(1);
        end
        if coinFlip>.5
            response(i)=1;
        elseif coinFlip<.5
            response(i)=2;
        end
    elseif w(stimType(i),1)<w(stimType(i),2)
        coinFlip = rand(1);
        while coinFlip==beta
            coinFlip=rand(1);
        end
        if coinFlip>beta
            response(i)=1;
        elseif coinFlip<beta
            response(i)=2;
        end
end
   %}

    %figure out which outcome recieved
    if stimType(i)==1
        if (response(i)==1 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==1) | (response(i)==0 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==2) %defines probabilistic wins
            outcome(i)=1;
        else
            outcome(i)=0;
        end
        numTrials=numTrials+[1 0 0 0];
    elseif stimType(i)==2
        if (response(i)==1 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==1) | (response(i)==0 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==2)
            outcome(i)=0;
        else
            outcome(i)=-1;
        end
        numTrials=numTrials+[0 1 0 0];
    elseif stimType(i)==3
        if (response(i)==2 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==1)  | (response(i)==1 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==2)
            outcome(i)=1;
        else
           outcome(i)=0;
        end
        numTrials=numTrials+[0 0 1 0];
    elseif stimType(i)==4
        if (response(i)==2 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==1)  | (response(i)==1 & outcomeValidFoil(numTrials(stimType(i)),stimType(i))==2)
            outcome(i)=0;
        else
            outcome(i)=-1;
        end
        numTrials=numTrials+[0 0 0 1];
    end

    %update instrumental and pavlovian value estimates
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
    
    %add any biases to action estimate 
    if (response(i) == 1)
        w(stimType(i),response(i)) = q(stimType(i),response(i)) + gobias + pavbias*V(stimType(i));
    else
        w(stimType(i),response(i)) = q(stimType(i),response(i));
    end
    
    
    TaskDataLearning_sim = [stimType,response,outcome];
end
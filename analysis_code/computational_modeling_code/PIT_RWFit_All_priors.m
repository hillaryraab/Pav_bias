%% Hillary Raab 7.17.17
%Fitting function

function [nll, V] = PIT_RWFit_All_priors_final(TaskDataLearning,priorsYN,priors,choicefxn,LR,RS,alphaPos,alphaNeg,beta,squashedSoftmax,gobias,pavbias,posRewardSens,negRewardSens,irrNoise)
if LR==1
    alphaNeg=alphaPos;
end

if RS==1
    negRewardSens=posRewardSens;
end

lik = 0;   % log likelihood

%Stimuli, response, outcome
stimType=TaskDataLearning(:,2); %stimuli type from (1:4)
response=(~TaskDataLearning(:,11))+1; %response: go (1) or no go (2)
outcome=TaskDataLearning(:,17); %outcome: reward (1), nothing (0), lose (-1)

V = zeros(1,length(unique(stimType)));  % initialize stimuli values
q = zeros(length(unique(stimType)),length(unique(response))); % initialize q values
w = zeros(length(unique(stimType)),length(unique(response))); % initialize combined w values

for i = 1:length(TaskDataLearning)
    
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
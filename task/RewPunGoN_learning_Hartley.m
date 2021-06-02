%%%%%%%%%%%%%%%%
%%  Variables  %
%%%%%%%%%%%%%%%%
tic
%%%% Before beginning experiment must switch on line 25 of this script and
%%%% line 18-20 of the 2 task display (learning and task)

%%subject-dependent
subj_name       =input('Participant''s initials: ', 's');
subj_number     =input('Participant number: ');
if length(subj_number)==0
    error ('Participant number missing ')
end
randomization=input('press 0 if stimuli have not been randomized, press 1 if they have been randomized: ');
scr = input('press 0 if no scr, 1 if scr is measured:')
scanner = input('press 0 if no scanner and 1 if scanner:')
session = input ('enter 1 for day 1 and 2 for day 2:')


%update below prior to running
%check to see if file exists; if so prompt error
outdir = 'C:/Users/hartleylab/Desktop/';

if exist ([outdir,'PIT_task/PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_StimOrd_Session_' num2str(session),'.mat'], 'file' )== 2
     error ('About to overwrite data; press cntrl + c to exit')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%config_display(0, 3, [0.5 0.5 0.5], [1 1 1], 'Helvetica', 30, 7, 0);
%above for part screen
%below for real experiment!
config_display(1, 3, [0.5 0.5 0.5], [1 1 1], 'Helvetica', 30, 7, 0);
config_keyboard;
% config_data('Pictures2.dat');
config_log( ['PIT_DATA/' num2str(subj_number) 'PIT/' 'Cogent' num2str(datevec(now),'-%02.0f') subj_name num2str(subj_number) '_Session_' num2str(session) '.log'] );
% if scr==1
%     startportb(888);
% end
if scr==1 %for SCR to link with other computer and send event marker when robot is on the screen
    ioObj = io64;
status = io64(ioObj);
address = hex2dec('C010'); %LPT3 output port address (find this in device manager)
data_CS_on=1; %writes value of '1' to channel D5 (digital I/O) in AcqKnowledge
data_CS_off=0; %writes value of '0' to channel D5 (digital I/O) in AcqKnowledge
io64(ioObj,address,data_CS_off); %initialize signal to "off"
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% buffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InstructScreen=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preparing matrices and stimuli
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rng('shuffle') %changed this 6.18.18
%rand('seed',sum(100*clock)); %seeds the random number generator with the clock time

if session == 1
    switch randomization
        case 0
            Stimuli={'S1.png','S2.png','S3.png','S4.png'};
            StimOrd=randperm(4)
            try
                save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_StimOrd_Session_' num2str(session)],'StimOrd')
            catch
                mkdir (['PIT_DATA/' num2str(subj_number) 'PIT/'])
                save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_StimOrd_Session_' num2str(session)],'StimOrd')
            end
            CSs=[Stimuli(StimOrd(1)),Stimuli(StimOrd(2)),Stimuli(StimOrd(3)),Stimuli(StimOrd(4))];
            RandCSs=CSs
            save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_RandCSs_Session_' num2str(session)],'RandCSs')
        case 1
            load ([num2str(subj_number) '_RandCSs_Session_' num2str(session)])
    end
elseif session == 2
    switch randomization
        case 0
            Stimuli={'S5.png','S6.png','S7.png','S8.png'};
            StimOrd=randperm(4)
            try
                save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_StimOrd_Session_' num2str(session)],'StimOrd')
             catch
                mkdir (['PIT_DATA/' num2str(subj_number) 'PIT/'])
                save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_StimOrd_Session_' num2str(session)],'StimOrd')
            end
                CSs=[Stimuli(StimOrd(1)),Stimuli(StimOrd(2)),Stimuli(StimOrd(3)),Stimuli(StimOrd(4))];
            RandCSs=CSs
            save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_RandCSs_Session_' num2str(session)],'RandCSs')
        case 1
            load ([num2str(subj_number) '_RandCSs_Session_' num2str(session) '_' subj_name])
    end
end
% Button = {'button.png'};
% ButtonBold = {'buttonBold.png'};
%%% Trial type matrix
TrialTypeLearning = [];
RandTrialTypeLearning = [];
for blocks = 1:3 %distribute trial types evenly across 4 blocks (each block 60 trials)
    TrialTypeLearning1=repmat([1 2 3 4],[1,15]);  % 1 go reward; 2 go punishment; 3 no-go reward; 4 no-go punishment;
    TrialTypeLearning=[TrialTypeLearning TrialTypeLearning1];
    RandTrialTypeLearning1=TrialTypeLearning1(randperm(size(TrialTypeLearning1,2)));
    RandTrialTypeLearning = [RandTrialTypeLearning RandTrialTypeLearning1];
end

% TrialType=repmat([1 2 3 4],[1,20]);
% RandTrialType=TrialType(randperm(size(TrialType,2)));
% TrialTarget=repmat([1 2],[1,60]);   % 1 real trial; 2 sham trial
% RandTrialTarget=TrialTarget(randperm(size(TrialTarget,2)));


%Probabilistic rewards; .80 reinforcement; % 1 real trial; 2 sham trial
%12 sham trials out of 60 for each of the 4 blocks 
% Pmat = [];
% for blocks = 1:4 
% PmatTemp = [zeros(1,48),ones(1,12)];
% PmatTemp = PmatTemp + 1;
% PmatTemp = PmatTemp(randperm(60));
% Pmat = [Pmat PmatTemp];
% end

%probabilistic reward set so each robot gets 3 shams/block
Pmat = [];
PmatAllRob = [];
for robots = 1:4
    for blocks = 1:3
        PmatTemp = [zeros(12,1); ones(3,1)];
        PmatTemp = PmatTemp + 1;
        PmatTemp = PmatTemp(randperm(15));
        Pmat = [Pmat; PmatTemp];
    end
    PmatAllRob = [PmatAllRob Pmat];
    Pmat = [];
end

%TrialNumber=[randperm(length(TrialTarget))' randperm(length(TrialTarget))' randperm(length(TrialTarget))' randperm(length(TrialTarget))'];
%TrialCounter=[0 0 0 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% other variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TargetTime=250 + rand(1,length(TrialTypeLearning))*3250;
TargetDisplayTime=1500;
ITI=750 + rand(1,length(TrialTypeLearning))*500;

if scanner==1
    port=1;  %for scanner
    config_serial(1);
    config_keyboard_monitoring('led');
    %%keys
    LeftKey         =80;              %m
    RightKey        =81;
else
    LeftKey         =97;              %m
    RightKey        =98;
end

Spacebar       =71;
xlocation1     =-100;
xlocation2     =+100;
ylocation      =0;

NumDummies=6;
SlicesVol=35;

start_cogent;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Instructions and Practice Trials
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

preparestring('In this game there are 4 robots like the ones shown here. You can', InstructScreen,0,200);
preparestring('tell the robots apart by their color.',InstructScreen,0,160);
loadpict('trialRobots.png',InstructScreen,0,-40);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);
preparestring('Some robots are Givers and some are Takers. Givers will give you tickets.',1,0,200);
preparestring('Takers will take your tickets. Your goal is to try to learn which robots are',1,0,160);
preparestring('Givers and which are Takers. For the Givers, you want to earn as many tickets',1,0,120);
preparestring('as possible. For the Takers, you want to stop them from taking your tickets.',1,0,80);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);
preparestring('Look at the robots. They all have an orange button.', InstructScreen,0,200);
loadpict('trialRobotsArrows.png',InstructScreen,0,-40);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);
preparestring('To find out if the robot is a Giver or a Taker, there are two options:',1,0,200);
preparestring('PRESS or NOT PRESS the robot''s orange button when you see the button',1,0,160);
preparestring('on the screen alone, as shown below.',1,0,120);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
loadpict('buttonOrange.png',InstructScreen,0,-60);
%insert picture of button
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);
preparestring('Each time you see a robot, your job is to decide whether or not to press', InstructScreen,0,200);
preparestring('their button. First you''ll see a robot. Then you''ll see just their orange',1,0,160);
preparestring('button. When you see just their button on the screen, you have a couple',1,0,120);
preparestring('of seconds to decide whether to press or not.',1,0,80);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);
preparestring('If you decide to press a robot''s button, you want to make sure you press',1,0,200);
preparestring('while the button is on the screen. To press their button, push the space-bar',1,0,160);
preparestring('key on the keyboard with the pointer finger on your dominant hand. Please',1,0,120);
preparestring('rest your pointer finger on the space-bar throughout the experiment.',1,0,80);
preparestring('Now, let''s practice pressing the robot''s button.', InstructScreen,0,-0);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

%let's practice pressing; build 4 press trials
PracticeTrials = 24;
PracticeTargetDisplayTime=1500;
PracticeTargetTime=250 + rand(1,PracticeTrials)*3250;

   %%% Set random stimuli order
        PressTrialStimuli={'P1.png','P2.png','P3.png','P4.png'};
        PressTrialOrd=randperm(4)
        PracticeOrd = PressTrialOrd;
        PressTrialOrd = [PressTrialOrd PressTrialOrd PressTrialOrd PressTrialOrd];
        save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeOrd_Session_' num2str(session)],'PracticeOrd');
        PressTrialCSs=[PressTrialStimuli(PressTrialOrd(1)),PressTrialStimuli(PressTrialOrd(2)),PressTrialStimuli(PressTrialOrd(3)),PressTrialStimuli(PressTrialOrd(4))];
        PressTrialRandCSs=PressTrialCSs;
        PracticeRandCSs = PressTrialRandCSs;
        save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeRandCSs_Session_' num2str(session)],'PracticeRandCSs');

    PracticeData = NaN(1,14);
    count = 1;
while sum(PracticeData(:,12)==1)<4
    if count > 5 && PracticeData(count-1,12)~=1
        clearpict(InstructScreen);
        preparestring('Remember to press this robot''s button by pushing the space-bar key.', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
    end
    ITI_trial=ITI(count);
    PTT = PracticeTargetTime(count);
    PressStimCue = PressTrialOrd(count);
    [data] = practice_tutorial (PressStimCue,PTT,1,PracticeTargetDisplayTime,ITI_trial, Spacebar);
    save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeData_Session_' num2str(session)],'PracticeData');
    PracticeData(count,:)=[count data];
    count = count + 1
end
clearpict(InstructScreen);
cgscale;

preparestring('Great job! Let''s practice not pressing the robot''s button.', InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

%let's practice NOT pressing; 4 no press trials
 %%% Set random stimuli order
        NoPressTrialStimuli={'P1.png','P2.png','P3.png','P4.png'};
        NoPressTrialOrd=randperm(4)
        PracticeOrd = [PracticeOrd; NoPressTrialOrd];
        NoPressTrialOrd=[NoPressTrialOrd NoPressTrialOrd NoPressTrialOrd NoPressTrialOrd];
        save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeOrd_Session_' num2str(session)],'PracticeOrd');
        NoPressTrialCSs=[NoPressTrialStimuli(NoPressTrialOrd(1)),NoPressTrialStimuli(NoPressTrialOrd(2)),NoPressTrialStimuli(NoPressTrialOrd(3)),NoPressTrialStimuli(NoPressTrialOrd(4))];
        NoPressTrialRandCSs=NoPressTrialCSs;
        PracticeRandCSs = [PracticeRandCSs; NoPressTrialRandCSs];
        save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeRandCSs_Session_' num2str(session)],'PracticeRandCSs');
noPressCount = count;
while sum(PracticeData(noPressCount:end,12)==1)<4
    if ((count-noPressCount) > 4) && PracticeData(count-1,12)~=1
        %if ((count-noPressCount)>4) && sum(PracticeData(count-2:count,12)==0)
        clearpict(InstructScreen);
        preparestring('Remember do NOT press this robot''s button.', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
    end
    ITI_trial=ITI(count);
    PTT = PracticeTargetTime(count);
    StimCue = NoPressTrialOrd(count-4);
    [data] = practice_tutorial (StimCue,PTT,2,PracticeTargetDisplayTime,ITI_trial,Spacebar);
    save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeData_Session_' num2str(session)],'PracticeData');
    PracticeData(count,:)=[count data];
    count = count + 1;
end  
save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeData_Session_' num2str(session)],'PracticeData');
clearpict(InstructScreen);
cgscale;

%%% Explanation of Rewards
clearpict(InstructScreen);
preparestring('Great job! After you decide to press their button or not press their button,', InstructScreen,0,200);
preparestring('you''ll find out if the robot gave you a ticket, took a ticket from you, or the',InstructScreen,0,160);
preparestring('number of tickets stayed the same. If the robot gave you one ticket,',InstructScreen,0,120);
preparestring('you will see:',InstructScreen,0,80);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
loadpict('goldenTicket.png',InstructScreen,0,-50);
drawpict(InstructScreen);
waitkeydown(inf);
clearpict(InstructScreen);

preparestring('If the robot took one ticket from you, you will see:',InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
loadpict('goldenTicketRipped.png',InstructScreen,0,-20);
drawpict(InstructScreen);
waitkeydown(inf);
clearpict(InstructScreen);

preparestring('If the number of tickets you have stayed the same, you will see:',InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
loadpict('horizontalBar.png',InstructScreen,0,-20);
drawpict(InstructScreen);
waitkeydown(inf);
clearpict(2);

clearpict(InstructScreen);
preparestring('Now you will have a few chances to see if each robot is a Giver or Taker.', InstructScreen,0,200);
preparestring('Remember to try to PRESS and NOT PRESS for each robot.', InstructScreen,0,160);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('Try pressing and not pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

        RewardTrialStimuli={'P1.png','P2.png','P3.png','P4.png'};
        RewardTrialOrd=randperm(4)
        PracticeOrd=[PracticeOrd;RewardTrialOrd];
        save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeOrd_Session_' num2str(session)],'PracticeOrd')
        RewardTrialCSs=[RewardTrialStimuli(RewardTrialOrd(1)),RewardTrialStimuli(RewardTrialOrd(2)),RewardTrialStimuli(RewardTrialOrd(3)),RewardTrialStimuli(RewardTrialOrd(4))];
        RewardTrialRandCSs=RewardTrialCSs
        PracticeRandCSs = [PracticeRandCSs;RewardTrialRandCSs];
        save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_PracticeRandCSs_Session_' num2str(session)],'PracticeRandCSs')
%press and reward
count = 1;
RewardData = NaN(1,16);
while (sum(RewardData(:,12)==1)<1) || (sum(RewardData(:,12)==0)<1) || (count<5)
    ITI_trial=ITI(count);
    PTT = PracticeTargetTime(count);
    StimCue = RewardTrialOrd(1);
    [data] = reward_tutorial(StimCue,1,PTT,1,PracticeTargetDisplayTime,ITI_trial,scr,Spacebar);
    RewardData(count,:)=[count data];
    save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_RewardData_Session' num2str(session)],'RewardData');
    if count > 4 && sum(RewardData(:,12)==1)<1 
        clearpict(InstructScreen);
        preparestring('Try pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
   elseif count > 4 && sum(RewardData(:,12)==0)<1 %need to do a no press trial
        clearpict(InstructScreen);
        preparestring('Try NOT pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
    end
     count = count + 1
end
save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_RewardData_Session' num2str(session)],'RewardData');

%Explanation of rewards
clearpict(InstructScreen);
cgscale;
preparestring('This robot gave you a ticket when you pressed its button.', InstructScreen,0,200);
preparestring('When you did not press its button, the robot did not give you a ticket.', InstructScreen,0,160);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('Let''s try another robot! Remember to press and not press its button.', InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

%do not press and reward
R2Count= count;
while (sum(RewardData(R2Count:end,12)==1)<1) || (sum(RewardData(R2Count:end,12)==0)<1) || (count-R2Count<4)
    ITI_trial=ITI(count);
    PTT = PracticeTargetTime(count);
    StimCue = RewardTrialOrd(2);
    [data] = reward_tutorial(StimCue,3,PTT,1,PracticeTargetDisplayTime,ITI_trial,scr,Spacebar);
     RewardData(count,:)=[count data];
    if (count-R2Count)>4 && sum(RewardData(R2Count:end,12)==1)<1 
        clearpict(InstructScreen);
        preparestring('Try pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
   elseif (count-R2Count)>4 && sum(RewardData(R2Count:end,12)==0)<1 %need to do a no press trial
        clearpict(InstructScreen);
        preparestring('Try NOT pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
    end
    count = count + 1;
end
clearpict(InstructScreen);
cgscale;
%Explanation of rewards
preparestring('This robot gave you a ticket when you did not press its button.', InstructScreen,0,200);
preparestring('When you pressed its button, the robot did not give you a ticket.', InstructScreen,0,160);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('Let''s try another robot! Remember to press and not press its button.', InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

%press and lose points
R3Count= count;
while (sum(RewardData(R3Count:end,12)==1)<1) || (sum(RewardData(R3Count:end,12)==0)<1) || (count-R3Count<4)
    ITI_trial=ITI(count);
    PTT = PracticeTargetTime(count);
    StimCue = RewardTrialOrd(3);
    [data] = reward_tutorial(StimCue,2,PTT,1,PracticeTargetDisplayTime,ITI_trial,scr,Spacebar);
    RewardData(count,:)=[count data];
    if (count-R3Count)>4 && sum(RewardData(R3Count:end,12)==1)<1 
        clearpict(InstructScreen);
        preparestring('Try pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
   elseif (count-R3Count)>4 && sum(RewardData(R3Count:end,12)==0)<1 %need to do a no press trial
        clearpict(InstructScreen);
        preparestring('Try NOT pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
    end
    count = count + 1;
end

clearpict(InstructScreen);
cgscale;
%Explanation of punishment
preparestring('This robot took a ticket when you did not press its button.', InstructScreen,0,200);
preparestring('When you pressed its button, the robot did not take your ticket.', InstructScreen,0,160);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('Let''s try another robot! Remember to press and not press its button.', InstructScreen,0,200);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

%do not press and lose points
R4Count= count;
while (sum(RewardData(R4Count:end,12)==1)<1) || (sum(RewardData(R4Count:end,12)==0)<1) || (count-R4Count<4)
    ITI_trial=ITI(count);
    PTT = PracticeTargetTime(count);
    StimCue = RewardTrialOrd(4);
    [data] = reward_tutorial(StimCue,4,PTT,1,PracticeTargetDisplayTime,ITI_trial,scr,Spacebar);
    RewardData(count,:)=[count data];
    if (count-R4Count)>4 && sum(RewardData(R4Count:end,12)==1)<1 
        clearpict(InstructScreen);
        preparestring('Try pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
   elseif (count-R4Count)>4 && sum(RewardData(R4Count:end,12)==0)<1 %need to do a no press trial
        clearpict(InstructScreen);
        preparestring('Try NOT pressing this robot''s button and let''s see what happens!', InstructScreen,0,200);
        preparestring('...Press space-bar to continue',InstructScreen,250,-275);
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
%         extraPTT = 250 + rand(1,PracticeTrials)*3250;
%         extraITI_trial=750 + rand(1)*500;
%         [data] = reward_tutorial(StimCue,1,extraPTT,1,PracticeTargetDisplayTime,extraITI_trial,0,Spacebar);
%         extraPracticeData(count-11,:)=[count data];
    end
    count = count + 1;
end

save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_RewardData_Session' num2str(session)],'RewardData');
% if exist('extraPracticeData', 'var') == 1 
%     save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_' subj_name '_extraPracticeData'],'extraPracticeData');
% end
clearpict(InstructScreen);
cgscale;
%Explanation of punishment
preparestring('This robot took a ticket when you pressed its button.', InstructScreen,0,200);
preparestring('When you did not press its button, the robot did not take a ticket.', InstructScreen,0,160);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

%%% Explain probabilistic rewards
cgscale;
preparestring('Some Givers give you tickets MOST of the time, but not ALL the time.', InstructScreen,0,200);
preparestring('Some Givers mostly do NOTHING but SOMETIMES give you a ticket.', InstructScreen,0,160);
preparestring('Some Takers take a ticket from you MOST of the time, but not ALL the time.', InstructScreen,0,80);
preparestring('Some Takers mostly do NOTHING but SOMETIMES take a ticket from you.', InstructScreen,0,40);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('When you see a robot, you will have to choose whether or not to press', InstructScreen,0,200);
preparestring('the robot''s button. You can learn which choices to make by trying', InstructScreen,0,160);
preparestring('out pressing, or not pressing, each robot''s button. The color of',InstructScreen,0,120);
preparestring('the robots will be different than the ones you saw in this practice.', InstructScreen,0,80);
preparestring('...Press space-bar to continue',InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);
preparestring('The game can be hard so you will need to concentrate.', InstructScreen,0,200);
preparestring('Remember: Try to earn as many tickets as possible by learning', InstructScreen,0,120);
preparestring('whether to press the button or not for each robot. The more', InstructScreen,0,80);
preparestring('tickets you win, the more bonus money you will get.', InstructScreen,0,40);
preparestring('...Press space-bar to continue', InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('Now, I will show you how to contact me at the end of the game.', InstructScreen,0,200);
preparestring('Any questions?', InstructScreen,0,120);
preparestring('Please wait until I leave the room to start the game.', InstructScreen,0,80);
preparestring('...Press space-bar to continue', InstructScreen,250,-275);
drawpict(InstructScreen);
waitkeydown(inf,71);
clearpict(InstructScreen);

preparestring('Get ready',InstructScreen,0,0);
drawpict(InstructScreen);
wait(1500);
clearpict(InstructScreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The Task
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TargetTime=250 + rand(1,length(TrialTypeLearning))*3250; %in primary behavioural experiment 1750
TargetDisplayTime=1500;
ITI=750 + rand(1,length(TrialTypeLearning))*750;
Pcount = [1 1 1 1];
for count=1:length(RandTrialTypeLearning)
    TrialCue=RandTrialTypeLearning(count);
    Time2Target=TargetTime(count);
    ITI_trial=ITI(count);
    if TrialCue == 1
        P=PmatAllRob(Pcount(1,1),1);
        Pcount=Pcount+[1 0 0 0];
    elseif TrialCue == 2
        P=PmatAllRob(Pcount(1,2),2)
        Pcount=Pcount+[0 1 0 0]
    elseif TrialCue == 3
        P=PmatAllRob(Pcount(1,3),3);
        Pcount=Pcount+[0 0 1 0];
    elseif TrialCue == 4
        P=PmatAllRob(Pcount(1,4),4);
        Pcount=Pcount+[0 0 0 1];
    end
    %P = Pmat(count); if it doesn't matter 3 sham trials/robot/block
    [data] = task_display_learning_Hartley (TrialCue,Time2Target,P,TargetDisplayTime,ITI_trial,RandCSs,scr,Spacebar);
   %[data] = task_display_learning2 (TrialCue,Time2Target,1,xlocation1,xlocation2,TargetDisplayTime,ITI_trial,RandCSs,scr,LeftKey,RightKey);
    TaskDataLearning(count,:)=[count data];
    save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_TaskDataLearning_Session' num2str(session)],'TaskDataLearning');
    if rem(count,60)==0 && count ~=180
        clearpict(InstructScreen);
        preparestring('You can take a break.',InstructScreen,0,0);
        preparestring('...Press space-bar to continue', InstructScreen,250,-275);
        toc
        drawpict(InstructScreen);
        waitkeydown(inf,71);
        clearpict(InstructScreen);
    end
end
save(['PIT_DATA/' num2str(subj_number) 'PIT/' num2str(subj_number) '_TaskDataLearning_Session' num2str(session)],'TaskDataLearning');
% eval( ['save Cogent_results_' subj_name '_' num2str(subj_number) '_learning_' num2str(datevec(now),'-%02.0f')] );


if sum(TaskDataLearning(:,17)) <= 0
    clearpict(InstructScreen);
    preparestring(['You have won 4 points in this run.'],InstructScreen,0,200) % if they win 0 or lose points, set points to 4
    preparestring('Please use the intercom to contact the experimenter.',InstructScreen,0,0);
    drawpict(InstructScreen);
    waitkeydown(inf,71);
    clearpict(InstructScreen);
    num2str(sum(TaskDataLearning(:,17)))
    toc
elseif sum(TaskDataLearning(:,17)) > 0
    clearpict(InstructScreen);
    preparestring(['You have won ' num2str(sum(TaskDataLearning(:,17))) ' points in this run.'],InstructScreen,0,200)
    preparestring('Please use the intercom to contact the experimenter.',InstructScreen,0,0);
    drawpict(InstructScreen);
    waitkeydown(inf,71);
    clearpict(InstructScreen);
    num2str(sum(TaskDataLearning(:,17)))
    toc
end

stop_cogent;
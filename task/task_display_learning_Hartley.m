function  [data] = task_display (TrialCue, Time2Target, P, TargetDisplayTime, ITI, RandCSs, scr, Spacebar)
if scr==1
    ioObj = io64;
status = io64(ioObj);
address = hex2dec('C010'); %LPT3 output port address (find this in device manager)
data_CS_on=1; %writes value of '1' to channel D5 (digital I/O) in AcqKnowledge
data_CS_off=0; %writes value of '0' to channel D5 (digital I/O) in AcqKnowledge
io64(ioObj,address,data_CS_off); %initialize signal to "off"
end
Money=1.0;

% if rand<=0.5
%     TargetPosition=xlocation1;
% else
%     TargetPosition=xlocation2;
% end

% Pmat = [ones(1,8),2,2];
% Pmat = Pmat(randperm(10));
% P = Pmat(1); 

clearkeys;
clearpict(2);
preparepict(loadpict(RandCSs{TrialCue}),2);
% if scr==1
%     outportb(888,255);
%     wait(10);
%     outportb(888,0);
% end
if scr==1
    io64(ioObj,address,data_CS_on); %tell Biopac CS is on
end
TimeCue=drawpict(2); %present cue for 1000 ms
wait(1000);
if scr==1
    io64(ioObj,address,data_CS_off); %tell Biopac CS is off
end

readkeys;
logkeys;
[KeyResp, KeyTime, n]=getkeydown;

if n~=0 %press before the target
    clearpict(3);
    cgscale(60);
    cgfont('Arial',2);
    preparestring('You pressed the key too early.',3);
    drawpict(3);
    wait(1000);
    cgscale;
    
    TimeTarget=0; KeyResp=0; KeyTime=0; RT=0; ResponseCue1=1; ResponseCue2=0; Response=5; CorrResp=0; TargetDisplayTime=0; TimeOutcome=0; Won=0;
else

    ResponseCue1=0; %if participant did not press, then show fixation cross
    
    clearkeys;
    clearpict(3);
    preparestring('+',3);
    drawpict(3);
    wait(Time2Target);

    readkeys;
    logkeys;
    [KeyResp, KeyTime, n]=getkeydown;

    if n~=0 %during fixation cross, pressed too early
        clearpict(3);
        cgscale(60);
        cgfont('Arial',2);
        preparestring('You pressed the key too early.',3);
        drawpict(3);
        wait(1000);
        cgscale;
        TimeTarget=0; KeyResp=0; KeyTime=0; RT=0; ResponseCue2=1; Response=5; CorrResp=0; TargetDisplayTime=0; TimeOutcome=0; Won=0;
    else
        ResponseCue2=0;
        clearpict(1);
        %drawpict(1);
        preparepict(loadpict('buttonOrange.png'),1);
        clearkeys;
        TimeTarget=drawpict(1); %present orange circle

%         cgpencol(0.5,0.5,0.5);
%         cgrect(0,0,1000,1000);
% 
%         cgpencol(1,1,1); %cg pen color is white
%         cgpenwid(5);
%         cgellipse(TargetPosition,0,70,70); %draw ellipse target
%         TimeTarget=cgflip; %time at which ellipse appears on screen in seconds
        logstring(['time Target is ' mat2str(TimeTarget)]); %*1000
        [KeyResp, KeyTime, n] = waitkeydown(TargetDisplayTime, Spacebar); %keep target on screen until left or right button press or max 1500 ms
        if KeyTime-TimeTarget < TargetDisplayTime & KeyResp == Spacebar %*1000
            clearpict(2);
            preparepict(loadpict('buttonOrangeBold.png'),2);
            drawpict(2); %present orange circle
            wait(TargetDisplayTime - (KeyTime-TimeTarget)); %*1000
        end
    %readkeys;
        %logkeys;
        %[KeyResp, KeyTime]=lastkeydown; %log key response and time of response
%clearpict(2);
%preparepict('.',2,-100,0);
%clearpict(3);
%preparepict('.',3,100,0);
% if KeyTime-TimeTarget*1000 < 2000 & KeyResp == Spacebar
    %KeyResp==KeyLeft %add in dot in middle of circle after participant presses to ease working memory load
    %drawpict(2);
%     cgpencol(0.5,0.5,0.5);
%     cgrect(0,0,1000,1000);
%     cgpencol(1,1,1); %cg pen color is white
%     cgpenwid(5);
%     cgellipse(TargetPosition,0,70,70);
%     cgpencol(1,0,0); %cg pen color is white
%     cgpenwid(5);
%     cgellipse(xlocation1,0,10,10,'f'); %draw ellipse target
%     cgflip;
%         clearpict(2);
%         drawpict(2);
%         preparepict(loadpict('buttonOrangeBold.png'),2);
%         drawpict(2); %present orange circle
%     wait(2000 - (KeyTime-TimeTarget*1000));
% elseif KeyTime-TimeTarget*1000 < 2000 & KeyResp == KeyRight
%            %KeyResp==KeyLeft %add in dot in middle of circle after participant presses to ease working memory load
%     %drawpict(2);
%     cgpencol(0.5,0.5,0.5);
%     cgrect(0,0,1000,1000);
%     cgpencol(1,1,1); %cg pen color is white
%     cgpenwid(5);
%     cgellipse(TargetPosition,0,70,70);
%     cgpencol(1,0,0); %cg pen color is white
%     cgpenwid(5);
%     cgellipse(xlocation2,0,10,10,'f'); %draw ellipse target
%     cgflip;
%     wait(2000 - (KeyTime-TimeTarget*1000));
% end
        %this measure valid responses
        if n > 0 & KeyResp==Spacebar
            RT=KeyTime-TimeTarget; %*1000; %RT = time key is pressed - time ellipse appears; (ellipse in sec. so convert to ms by *1000)
            Key=KeyResp;
            if RT<TargetDisplayTime
%                 if TargetPosition==xlocation1 & KeyResp==KeyLeft
                    Response=1; %correct response
%                 elseif TargetPosition==xlocation2 & KeyResp==KeyRight
%                     Response=1;
%                 else
%                     Response=2; %incorrect response
%                 end
            else
                Response=3; % too late
            end
        elseif n>0 & KeyResp ~=Spacebar
           RT=KeyTime-TimeTarget;
           if RT<TargetDisplayTime
                Response=2; %incorrect
           else
                Response=3; %incorrect and too late
           end
        elseif n==0
            RT=0;
            KeyResp=0;
            KeyTime=0;
            Response=0;  %no response
            CorrResp=0;
        end
  
        clearpict(3);
        preparestring('+',3); %fixation cross for 1000 ms
        drawpict(3);
        wait(1000);

        clearpict(4);
        x=[0,3,-3];
        y=[5,0,0];

        if TrialCue==1
            if Response==1
                CorrResp=1;
            else
                CorrResp=0;
            end
            if (Response==1 & P==1) | (Response==0 & P==2) %defines probabilistic wins
                Won=Money; %add Money to total and draw green arrow pointing upwards
%                 cgscale(60);
                clearpict(4);
                preparepict(loadpict('goldenTicket.png'),4);
%                 cgpencol(0,1,0); green arrrow
%                 cgrect(0,-4,2,8); green arrow
%                 cgpolygon(x,y); green arrow
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 cgtext(['OK, you won £' num2str(Money)],0,-10);
                
            else
                Won=0; %add nothing to total and draw horizontal dashed line
                clearpict(4);
                preparepict(loadpict('horizontalBar.png'),4);
%                 cgscale(60); yellow horizontal arrow
%                 cgpencol(1,1,0) yellow horizontal arrow 
%                 cgrect(0,0,8,2); yellow horizontal arrow
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2);
                %                 if Response==1
                %                     cgtext(['OK, but you did not win£' num2str(Money) 'anyway'],0,-10);
                %                 else
                %                     cgtext('UNSUCCESSFUL, your response was too late or incorrect',0,-10);
                %                 end
            end
        elseif TrialCue==2 % Go to avoid losing
            if Response==1
                CorrResp=1;
            else
                CorrResp=0;
            end
            if (Response==1 & P==1) | (Response==0 & P==2)
                Won=0; %if they respond, avoid losing
                %cgscale(60);
                clearpict(4);
                preparepict(loadpict('horizontalBar.png'),4);
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 cgtext(['OK, you avoided losing £' num2str(Money)],0,-10);
            else
                Won=-Money; % if they don't respond, lose money and green arrow downwards
                %cgscale(60);
                clearpict(4);
                preparepict(loadpict('goldenTicketRipped.png'),4);
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 if Response==1
                %                     cgtext(['OK, but you lost £' num2str(Money) 'anyway'],0,-10);
                %                 else
                %                     cgtext('UNSUCCESSFUL, your response was too late or incorrect',0,-10);
                %                 end
            end
        elseif TrialCue==3 %No go to win
            if Response==0
                CorrResp=1;
            else
                CorrResp=0;
            end
            if (Response==0 & P==1)  | (Response>0 & P==2)
                Won=Money; %earn money and yellow ticket
                %cgscale(60);
                clearpict(4);
                preparepict(loadpict('goldenTicket.png'),4);
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 cgtext(['OK, you won £' num2str(Money)],0,-10);
            else
                Won=0; %no money and dashed line
                %cgscale(60);
                clearpict(4);
                preparepict(loadpict('horizontalBar.png'),4);
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 if Response==0
                %                     cgtext(['OK, but you did not win £' num2str(Money) 'anyway'],0,-10);
                %                 else
                %                     cgtext('UNSUCCESSFUL, you should have not responded',0,-10);
                %                 end
            end
        elseif TrialCue==4 %No Go to avoid losing
            if Response==0
                CorrResp=1; %they choice the best option
            else
                CorrResp=0;
            end
            if (Response==0 & P==1)  | (Response>0 & P==2)
                Won=0
                %cgscale(60);
                clearpict(4);
                preparepict(loadpict('horizontalBar.png'),4);
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 cgtext(['OK, you avoided losing £' num2str(Money)],0,-10);
            else
                Won=-Money; %lose money and red arrow downwards
                %cgscale(60);
                clearpict(4);
                preparepict(loadpict('goldenTicketRipped.png'),4);
           
%                 cgpencol(1,0,0)
%                 cgrect(0,4,2,8);
%                 cgpolygon(-x,-y);
                %                 cgpencol(1,1,1);
                %                 cgfont('Arial',2)
                %                 if Response==0
                %                     cgtext(['OK, but you lost £' num2str(Money) 'anyway'],0,-10);
                %                 else
                %                     cgtext('UNSUCCESSFUL, you should have not responded',0,-10);
                %                 end
            end
        end
        if scr==1
            io64(ioObj,address,data_CS_on); %tell Biopac CS is on
        end
            TimeOutcome = drawpict(4);
            wait(2000);
            if scr==1
                io64(ioObj,address,data_CS_off); %tell Biopac CS is off
            end
            cgscale;
        end
end
clearpict(3);
preparestring('+',3);
drawpict(3);
wait(ITI);

% cgfont('Helvetica',3)

data=[TrialCue,TimeCue,ResponseCue1,ResponseCue2,Time2Target,TimeTarget,KeyResp,KeyTime,RT,Response,CorrResp,P,TargetDisplayTime,TimeOutcome,ITI,Won];
end
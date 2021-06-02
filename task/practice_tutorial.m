function  [data] = practice_tutorial (StimCue, Time2Target, PracticeRun, TargetDisplayTime, ITI, Spacebar) 
if PracticeRun ==1 %1 = practice pressing
clearpict(2);
 if StimCue == 1
     preparepict(loadpict('P1.png'),2);
 elseif StimCue == 2  
       preparepict(loadpict('P2.png'),2);
 elseif StimCue == 3  
       preparepict(loadpict('P3.png'),2);
 elseif StimCue == 4  
     preparepict(loadpict('P4.png'),2);
   end
clearkeys;
TimeCue=drawpict(2);
wait(1000);

[KeyResp, KeyTime, n]=getkeydown;

if n~=0 %press before the target
    clearpict(3);
    cgscale(60);
    cgfont('Arial',2);
    preparestring('You pressed the key too early.',3);
    drawpict(3);
    wait(1000);
    cgscale;
    
    TimeTarget=0; KeyResp=0; KeyTime=0; RT=0; ResponseCue1=1; ResponseCue2=0; Response=5; TargetDisplayTime=0; TimeOutcome=0; Won=0;
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
        TimeTarget=0; KeyResp=0; KeyTime=0; RT=0; ResponseCue2=1; Response=5; TargetDisplayTime=0; TimeOutcome=0; Won=0;
    else
        ResponseCue2=0;
        clearpict(1);
        preparepict(loadpict('buttonOrange.png'),1);
        clearkeys;
        TimeTarget=drawpict(1); %present orange circle
        
        logstring(['time Target is ' mat2str(TimeTarget)]);
        [KeyResp, KeyTime, n] = waitkeydown(TargetDisplayTime, Spacebar);
        if KeyTime-TimeTarget < TargetDisplayTime & KeyResp == Spacebar %*1000
            clearpict(2);
            preparepict(loadpict('buttonOrangeBold.png'),2);
            drawpict(2); %present orange circle
            wait(TargetDisplayTime - (KeyTime-TimeTarget)); %*1000    
        end
        
clearpict(3);
preparestring('+',3);
clearkeys;
FixTime=drawpict(3);
[LateKeyResp, LateKeyTime, LateN] = waitkeydown(1000, Spacebar);
        
%this measure valid responses
if n > 0 & KeyResp==Spacebar  
    RT=KeyTime-TimeTarget; %*1000
    Key=KeyResp;
    if RT<TargetDisplayTime
            Response=1; %correct response
    else
            Response=4; %too late
            %Response=5; %too early
    end
elseif n > 0 & KeyResp ~= Spacebar
    RT=KeyTime-TimeTarget; %*1000
    if RT<TargetDisplayTime
        Response=2; 
    else
        Response=3;
    end
elseif LateN > 0 
        Response=4;
        KeyResp=LateKeyResp;
        KeyTime=LateKeyTime;
        RT=LateKeyTime-FixTime;
elseif n==0
    RT=0;
    KeyResp=0; %renamed 
    KeyTime=0;
    Response=0;  %missed response
end

clearpict(4);

if Response==1
    preparestring(['Great'],4);
elseif Response==2
    preparestring('Incorrect',4);
    preparestring('Right now we are pressing the button.',4,0,-40);
elseif Response==3
    preparestring('Incorrect and too late',4);
elseif Response==4
    preparestring('You pressed the key too late.',4);
else
    preparestring('Incorrect',4);
    preparestring('Right now we are pressing the button.',4,0,-40);
end
TimeOutcome=drawpict(4);
wait(2000);

clearpict(3);
preparestring('+',3);
drawpict(3);
wait(ITI);
    end 
end
data=[TimeTarget,KeyResp,KeyTime,RT,Response,TargetDisplayTime,ITI];

elseif PracticeRun ==2 %2 = practice not pressing
clearpict(2);
 if StimCue == 1
     preparepict(loadpict('P1.png'),2);
 elseif StimCue == 2  
       preparepict(loadpict('P2.png'),2);
 elseif StimCue == 3  
       preparepict(loadpict('P3.png'),2);
 elseif StimCue == 4  
     preparepict(loadpict('P4.png'),2);
   end
clearkeys;
TimeCue=drawpict(2);
wait(1000);
[KeyResp, KeyTime, n]=getkeydown;

if n~=0 %press before the target
    clearpict(3);
    cgscale(60);
    cgfont('Arial',2);
    preparestring('Right now we are NOT pressing the button.',3);
    drawpict(3);
    wait(1000);
    cgscale;
    TimeTarget=0; KeyResp=0; KeyTime=0; RT=0; ResponseCue1=1; ResponseCue2=0; Response=5; TargetDisplayTime=0; TimeOutcome=0; Won=0;
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
        preparestring('Right now we are NOT pressing the button.',3);
        drawpict(3);
        wait(1000);
        cgscale;
        TimeTarget=0; KeyResp=0; KeyTime=0; RT=0; ResponseCue2=1; Response=5; TargetDisplayTime=0; TimeOutcome=0; Won=0;
    else
        ResponseCue2=0;
        clearpict(1);
        preparepict(loadpict('buttonOrange.png'),1);
        clearkeys;
        TimeTarget=drawpict(1); %present orange circle
        logstring(['time Target is ' mat2str(TimeTarget)]);
        [KeyResp, KeyTime, n] = waitkeydown(TargetDisplayTime, Spacebar);
        if KeyTime-TimeTarget < TargetDisplayTime & KeyResp == Spacebar %*1000
            clearpict(2);
            preparepict(loadpict('buttonOrangeBold.png'),2);
            drawpict(2); %present orange circle
            wait(TargetDisplayTime - (KeyTime-TimeTarget)); %*1000    
        end

clearpict(3);
preparestring('+',3);
clearkeys;
FixTime=drawpict(3);
[LateKeyResp, LateKeyTime, LateN] = waitkeydown(1000, Spacebar);

%this measure valid responses
if n>0 & KeyResp == Spacebar 
    RT=KeyTime-TimeTarget; %*1000
    Key=KeyResp;
    if RT<TargetDisplayTime
            Response=2; %incorrect response
    else
            Response=2; %incorrect and too late
    end
elseif n > 0 & KeyResp ~= Spacebar
    RT=KeyTime-TimeTarget;
        if RT < TargetDisplayTime
            Response=2; 
        else
        Response=2;
        end
elseif LateN > 0
        Response=4;
        KeyResp=LateKeyResp;
        KeyTime=LateKeyTime;
        RT=LateKeyTime-FixTime;
elseif n==0
    RT=0;
    KeyResp=0; %renamed 
    KeyTime=0;
    Response=1;  %correct response
end

clearpict(4);
if Response==1
    preparestring(['Great'],4);
elseif Response==2
    preparestring('Incorrect',4);
    preparestring('Right now we are NOT pressing the button.',4,0,-40);
elseif Response==3
    preparestring('Incorrect and too late',4);
elseif Response==4
    preparestring('Right now we are NOT pressing the button.',4);
else
    preparestring('You did not respond.',4)
end
TimeOutcome=drawpict(4);
wait(2000);
clearpict(3);
preparestring('+',3);
drawpict(3);
wait(ITI);
    end 
end
end
data=[StimCue,PracticeRun,TimeCue,ResponseCue1,ResponseCue2,Time2Target,TimeTarget,KeyResp,KeyTime,RT,Response,TargetDisplayTime,ITI];
end
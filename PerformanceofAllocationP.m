%%%%
% The modified performance with the objective of minimizing the total cost
% include salary and the penalty of overwaiting
%%%%%

function [TCost,W2,W3,Cost,N_delayed,W1] = PerformanceofAllocationP(Allocations,dayT,warmday,Vlambda,Vmu,Prop,c,cd,Ut) 
tempQ1st = zeros(1,Allocations(3));
[TrueArrive,Type] = ArriveProcess(dayT,Vlambda,Prop);
lenArrive = length(TrueArrive);
aTrueArrive = TrueArrive;
%     N_delayed = zeros(1,Allocations(3));
NoType2 = length(find(Type==2));
InforDelayed = zeros(Allocations(3)*2,NoType2); %the first row represents the end of observation time, the second row denotes the start time on 2nd
indexlevel2 = zeros(2,Allocations(3)); %the first row record the number of end of Obs from Allocation(3); the second row record the number of start service in 2nd
% EndofObs = zeros(1,NoType2);
%     Begin2nd = zeros(1,NoType2);
%% calculate the income(object)
% find the number of arrival after warmup day
countArrival = length(find(TrueArrive >= warmday*24*60));
% form allocation to the pair number
numofNR  = Allocations(3); % we consider Nurse+Resident as a fixed pair(always together)
numofS = Allocations(4);
numofN = Allocations(1); % the Allocation(1) give the number of all nurses and thus the number of nurse for exam is Allocation(1)-Allocation(3)
numofMI = Allocations(2);
%Income  = p(1)* countArrival+ p(2)*(dayT-warmday);
Cost = sum(c.*[numofN+numofNR,numofMI,numofNR,numofS])*(dayT-warmday);
%ARevenue = Income - Cost;
%exp1 = exprnd(30,[lenArrive*10,1]);
%exp2 = exprnd(10, [lenArrive,1]);
%exp3 = exprnd(20, [lenArrive,1]);
exp1 = exprnd(Vmu(1),[lenArrive,1]);
exp21 = exprnd(Vmu(2), [lenArrive,1]);%30
exp22 = exprnd(Vmu(3), [lenArrive,1]);
exp23 = exprnd(Vmu(4), [lenArrive,1]);
exp3 = exprnd(Vmu(5), [lenArrive,1]);%30
index1 = 1;
index2 = 1;
index3 = 1;
index4 = 1;
index5 = 1;

%% Calculate the waiting time
%% Initialization
w1 = 0; % cumulative waiting time
w2 = 0; % cumulative waiting time of level 2
w3 = 0; % cumulative waiting time of level 3

%queue length
Qrescue = 0;
Qexam = 0;
Qcasualty = 0;
Q1st = 0;
Q2nd = zeros(1,numofNR);

%which station the staff in
StationN = zeros(1,numofN);%0=idle, 1 = in exam,这个其实可以省略，因为这部分的nurse只有exam这一个station。 先放这儿
StationMI = zeros(1,numofMI); %0 = idle, 1 = exam, 2 = casualty
StationNR = zeros(1,numofNR); %0=idle, 1 = 1st, 2 = 2nd, 3 = in rescue
StationS = zeros(1,numofS); %0=idle, 1 = 2nd, 2 = in rescue.

%End of service time of each staff
EndN = zeros(1,numofN);
EndMI = zeros(1,numofMI);
EndNR = zeros(1,numofNR);
EndS = zeros(1,numofS);
lenT2 = length(find(Type==2));
EndObs = ones(numofNR,lenT2).*inf; % there may be different patients in observation, we should record all their return time, different patient should return to specific queue
countObs = zeros(1,numofNR);

% begin the process, t = 0 , time clock
t = 0;
T = dayT*24*60;

%% The process goes as one of 7 events occurs
arriveIndex = 1;
TrueArrive(lenArrive+1)=Inf;
EarlyTime = zeros(1,6+numofNR);
EarlyTime(2:6+numofNR) = Inf;
EarlyTime(1) = TrueArrive(1);
IdleindexS = 1:numofS;
IdleindexNR = 1:numofNR;
IdleindexMI = 1:numofMI;
IdleindexN = 1:numofN;


%    tic
k = 0;
while t <= T && arriveIndex <= lenArrive
    %        tic
    k = k+1;
    [earlyT,indexEarly] = min(EarlyTime);
    %             total(d) = toc;
    %              d=d+1;
    %             record the waiting time till the new event happens after warm
    %         tic
    if earlyT > warmday*24*60 && earlyT <= T
        if t < warmday*24*60
            w1 = w1 + Qrescue*(earlyT - warmday*24*60);
            w2 = w2 + (Qexam + Q1st)*(earlyT - warmday*24*60);
            w3 = w3 + Qcasualty*(earlyT - warmday*24*60); 
        else
            w1 = w1 + Qrescue*(earlyT - t);
            w2 = w2 + (Qexam +  Q1st)*(earlyT - t);
            w3 = w3 + Qcasualty*(earlyT - t);
        end
    else
        if earlyT > T
            w1 = w1 + Qrescue*(T - t);
            w2 = w2 + (Qexam + Q1st)*(T - t);
            w3 = w3 + Qcasualty*(T - t);
        end
    end
    %         total(d) = toc;
    %         d=d+1;
    
    %tic
    %% the next event is an arrival
    switch indexEarly
        case 1
            %tic
            TrueArrive(arriveIndex) = inf;
            if Type(arriveIndex) == 1
                RescueS = find(StationS==2);
                if isempty(RescueS) % rescue room is empty
                    if ~isempty(IdleindexNR) && ~isempty(IdleindexS) % |idleNR|>0,|idleS|>0
                        tempindexNR = IdleindexNR(1);
                        tempindexS = IdleindexS(1);
                        IdleindexNR(1) = [];
                        IdleindexS(1) = [];
                        StationNR(tempindexNR) = 3;
                        StationS(tempindexS) = 2;
                        %                            tempEndT = earlyT + exprnd(30);
                        tempEndT = earlyT + exp1(index1);
                        index1 = index1+1;
                        EndNR(tempindexNR) = tempEndT;
                        EndS(tempindexS) = tempEndT;
                    else
                        if ~isempty(IdleindexS) && isempty(IdleindexNR)% break the 1st to server the level 1
                            Busy1stNR = find(StationNR==1);
                            temp1stNR = Busy1stNR(1);
                            tempindexS = IdleindexS(1);
                            IdleindexS(1) = [];
                            StationNR(temp1stNR) = 3;
                            StationS(tempindexS) = 2;
                            %                                tempEndT = earlyT + exprnd(30);
                            tempEndT = earlyT + exp1(index1);
                            index1 = index1+1;
                            EndNR(temp1stNR) = tempEndT;
                            EndS(tempindexS) = tempEndT;
                            Q1st = Q1st + 1;
                            [EarlyTime(4),index1st] = min([EndNR(StationNR == 1),Inf]);
                        else % break 2nd to serve level 1
                            Busy2ndNR = find(StationNR==2);
                            [~,indexShortQ]= min(Q2nd(Busy2ndNR));
                            temp2ndNR = Busy2ndNR(indexShortQ);
                            tempS = find(EndS == EndNR(temp2ndNR));
                            StationNR(temp2ndNR) = 3;
                            StationS(tempS) = 2;
                            %                                tempEndT = earlyT + exprnd(30);
                            tempEndT = earlyT + exp1(index1);
                            index1 = index1+1;
                            EndNR(temp2ndNR) = tempEndT;
                            EndS(tempS) = tempEndT;
                            Q2nd(temp2ndNR) =  Q2nd(temp2ndNR) + 1;
                            % the begin service time of this 2nd
                            % patients is delayed
                            InforDelayed(temp2ndNR*2,indexlevel2(2,temp2ndNR)) = 0;
                            indexlevel2(2,temp2ndNR) = indexlevel2(2,temp2ndNR) - 1;
                            [EarlyTime(5),index2nd] = min([EndNR(StationNR == 2),Inf]);
                        end
                    end
                    EarlyTime(6) = min([EndNR(StationNR==3), Inf]);
                else
                    Qrescue = Qrescue + 1;
                end
                
            else
                if Type(arriveIndex) == 2  %if level 2 arrive
                    %                        tic
                    if ~isempty(IdleindexN) && ~isempty(IdleindexMI)
                        %                             tic
                        tempindexN =  IdleindexN(1); %the index of nurse to allocate the patient to
                        tempindexMI = IdleindexMI(1);
                        IdleindexN(1) = [];
                        IdleindexMI(1) = [];
                        %                            tic
                        StationMI(tempindexMI) = 1;
                        StationN(tempindexN) = 1; %StationN的其实都可以省略，不影响
                        %                             total(d) = toc;
                        %                             d=d+1;
                        %                            tic
                        %                            tempEndT = earlyT + exprnd(10);
                        tempEndT = earlyT + exp21(index2);
                        index2 = index2+1;
                        %                             total(d) = toc;
                        %                             d=d+1;
                        EndN(tempindexN) =  tempEndT;
                        EndMI(tempindexMI) = tempEndT;
                        [EarlyTime(2),indexExam] = min([EndN(StationN==1),Inf]);
                        %                             total(d) = toc;
                        %                             d=d+1;
                    else
                        Qexam = Qexam + 1;
                    end
                    %                         total(d) = toc;
                    %                         d=d+1;
                else
                    if ~isempty(IdleindexMI)
                        %                            tic
                        tempindexMI = IdleindexMI(1);
                        IdleindexMI(1) = [];
                        StationMI(tempindexMI) = 2; % the MI is doing casualty treatment
                        %                             total(d) = toc;
                        %                             d=d+1;
                        %                            tempEndT = earlyT + exprnd(30);
                        tempEndT = earlyT + exp3(index5);
                        index5 = index5+1;
                        EndMI(tempindexMI) = tempEndT;
                        [EarlyTime(3),indexCasualty] = min([EndMI(StationMI==2),Inf]);
                    else
                        Qcasualty = Qcasualty + 1;
                    end
                    %                         total(d) = toc;
                    %                         d=d+1;
                end
            end
            arriveIndex = arriveIndex + 1;
            EarlyTime(1) = TrueArrive(arriveIndex);
            %                 total(d) = toc;
            %                 d=d+1;
            %% if the next event is finishing exam
        case 2
            %                 tic
            % find the index of N and MI that first finishing exam
            BusyN = find(StationN==1);
            tempindexN = BusyN(indexExam);
            tempindexMI = find(EndMI == EndN(tempindexN));
            %                 total(d) = toc;
            %                 d=d+1;
            %tic
            if Qexam == 0
                %                     tic
                StationN(tempindexN) = 0;
                IdleindexN = [IdleindexN,tempindexN];
                if Qcasualty > 0
                    StationMI(tempindexMI) = 2;
                    %                        tempEndT = earlyT + exprnd(30);
                    tempEndT = earlyT + exp3(index5);
                    index5 = index5+1;
                    EndMI(tempindexMI) = tempEndT;
                else
                    StationMI(tempindexMI) = 0;
                    IdleindexMI = [IdleindexMI,tempindexMI];
                end
                %                     total(d) = toc;
                %                     d=d+1;
            else
                Qexam = Qexam -1;
                %                    tempEndT = earlyT + exprnd(10);
                tempEndT = earlyT + exp21(index2);
                index2 = index2 + 1;
                EndMI(tempindexMI) = tempEndT;
                EndN(tempindexN) = tempEndT;
            end
            if ~isempty(IdleindexNR)
                %                     tic
                tempindexNR = IdleindexNR(1);
                IdleindexNR(1) = [];
                StationNR(tempindexNR) = 1;
                %                    tempEndT = earlyT +exprnd(30);
                tempEndT = earlyT + exp22(index3);
                index3 = index3+1;
                EndNR(tempindexNR) = tempEndT;
                tempQ1st(tempindexNR) = tempQ1st(tempindexNR) + 1;
                %                     total(d) = toc;
                %                     d=d+1;
            else
                Q1st = Q1st + 1;
            end
            
            %                tic
            [EarlyTime(2),indexExam] = min([EndN(StationN==1),Inf]);
            [EarlyTime(3),indexCasualty] = min([EndMI(StationMI==2),Inf]);
            [EarlyTime(4),index1st] = min([EndNR(StationNR == 1),Inf]);
            %                 total(d) = toc;
            %                 d=d+1;
            
            %% if the next event is finishing casualty
        case 3
            %                tic
            % fine the index who finishes the casualty
            BusyMI = find(StationMI==2);
            tempindexMI = BusyMI(indexCasualty);
            if Qexam > 0 && ~isempty(IdleindexN) % combine the available MI with idle N to serve exam
                tempindexN = IdleindexN(1);
                IdleindexN(1) = [];
                StationMI(tempindexMI) = 2;
                StationN(tempindexN) = 1;
                %                    tempEndT = earlyT + exprnd(10);
                tempEndT = earlyT + exp21(index2);
                index2 = index2+1;
                EndN(tempindexN) = tempEndT;
                EndMI(tempindexMI) = tempEndT;
                Qexam = Qexam -1;
            else
                if Qcasualty == 0 % MI be idle
                    StationMI(tempindexMI) = 0;
                    IdleindexMI = [IdleindexMI, tempindexMI];
                else % go on serve casualty
                    Qcasualty = Qcasualty -1;
                    %                        tempEndT = earlyT + exprnd(30);
                    tempEndT = earlyT + exp3(index5);
                    index5 = index5+1;
                    EndMI(tempindexMI) = tempEndT;
                end
            end
            %               tic
            [EarlyTime(2),indexExam] = min([EndN(StationN==1),Inf]);
            [EarlyTime(3),indexCasualty] = min([EndMI(StationMI==2),Inf]);
            
            %               total(d) = toc;
            %               d=d+1;
            
            %% if the next event is finishing 1st
        case 4
            %tic
            BusyNR = find(StationNR==1);
            tempindexNR = BusyNR(index1st);
            countObs(tempindexNR) = countObs(tempindexNR) + 1;
            tempEndofObs = earlyT + 10 +(40-10)*rand;
            EndObs(tempindexNR,countObs(tempindexNR)) = tempEndofObs; % the time this patient finish observation
            
            if ~isempty(IdleindexS) && Q2nd(tempindexNR) > 0 % then go to serve 2nd
                tempindexS = IdleindexS(1);
                IdleindexS(1) = [];
                StationS(tempindexS) = 1;
                StationNR(tempindexNR) = 2;
                %                    tempEndT = earlyT + exprnd(15);
                tempEndT = earlyT + exp23(index4);
                index4 = index4+1;
                EndNR(tempindexNR) = tempEndT;
                EndS(tempindexS) = tempEndT;
                Q2nd(tempindexNR) = Q2nd(tempindexNR) - 1;
                indexlevel2(2,tempindexNR) = indexlevel2(2,tempindexNR) + 1;
                InforDelayed(tempindexNR*2,indexlevel2(2,tempindexNR)) = earlyT;
            else
                if Q1st > 0
                    %                        tempEndT = earlyT + exprnd(30);
                    tempEndT = earlyT + exp22(index3);
                    index3 = index3+1;
                    EndNR(tempindexNR) = tempEndT;
                    Q1st = Q1st -1;
                    tempQ1st(tempindexNR) = tempQ1st(tempindexNR) + 1;
                else
                    StationNR(tempindexNR) = 0;
                    IdleindexNR = [IdleindexNR, tempindexNR];
                end
            end
            [EarlyTime(7:6+numofNR),~] = min(EndObs,[],2);
            [EarlyTime(4),index1st] = min([EndNR(StationNR == 1),Inf]);
            [EarlyTime(5),index2nd] = min([EndNR(StationNR == 2),Inf]);
            %                 total(d) = toc;
            %                 d=d+1;
            %% the event is finishing 2nd
        case 5
            BusyNR = find(StationNR==2);
            tempindexNR = BusyNR(index2nd);
            tempindexS = find(EndS == EndNR(tempindexNR));
            if Q2nd(tempindexNR) == 0
                if Q1st >0
                    StationNR(tempindexNR) = 1;
                    %                        tempEndT = earlyT + exprnd(30);
                    tempEndT = earlyT + exp22(index3);
                    index3 = index3 + 1;
                    EndNR(tempindexNR) = tempEndT;
                    tempQ1st(tempindexNR) = tempQ1st(tempindexNR) + 1;
                    %StationS(tempindexS) = 0;
                    %IdleindexS = [IdleindexS, tempindexS];
                    Q1st = Q1st - 1;
                else
                    StationNR(tempindexNR) = 0;
                    IdleindexNR = [IdleindexNR, tempindexNR];
                end
                % find other idle NR with longest Q2nd(i) except tempindexNR
                BlockQ2nd = IdleindexNR(Q2nd(IdleindexNR)>0); % index of idle NR due to lack of S
                % set the current NR idle
                if ~isempty(BlockQ2nd)
                    [~,indexLongQ] = max(Q2nd(BlockQ2nd));
                    tempindexNR_O = BlockQ2nd(indexLongQ); % the server with the longest Q in 2nd
                    IdleindexNR(IdleindexNR==tempindexNR_O)=[];
                    StationNR(tempindexNR_O) = 2;
                    %                            tempEndT = earlyT + exprnd(15);
                    tempEndT = earlyT + exp23(index4);
                    index4 = index4 + 1;
                    EndS(tempindexS) = tempEndT;
                    EndNR(tempindexNR_O) = tempEndT;
                    Q2nd(tempindexNR_O) = Q2nd(tempindexNR_O) - 1;
                    indexlevel2(2,tempindexNR_O) = indexlevel2(2,tempindexNR_O) + 1;
                    InforDelayed(tempindexNR_O*2,indexlevel2(2,tempindexNR_O)) = earlyT;
                else
                    StationS(tempindexS) = 0;
                    IdleindexS = [IdleindexS, tempindexS];
                end
            else
                %                    tempEndT = earlyT + exprnd(15);
                tempEndT = earlyT + exp23(index4);
                index4 = index4 + 1;
                EndNR(tempindexNR) = tempEndT;
                EndS(tempindexS) = tempEndT;
                Q2nd(tempindexNR) = Q2nd(tempindexNR) -1;
                indexlevel2(2,tempindexNR) = indexlevel2(2,tempindexNR) + 1;
                InforDelayed(tempindexNR*2,indexlevel2(2,tempindexNR)) = earlyT;
            end
            [EarlyTime(4),index1st] = min([EndNR(StationNR == 1),Inf]);
            [EarlyTime(5),index2nd] = min([EndNR(StationNR == 2),Inf]);
            
            %% if the next event is finishing rescue
        case 6
            tempindexNR = find(StationNR==3);
            tempindexS = find(EndS == EndNR(tempindexNR));
            if Qrescue == 0
                if Q2nd(tempindexNR) > 0 % back to serve the specific Q2nd
                    StationNR(tempindexNR) =2;
                    StationS(tempindexS) = 1;
                    %                        tempEndT = earlyT + exprnd(15);
                    tempEndT = earlyT + exp23(index4);
                    index4 = index4+1;
                    EndNR(tempindexNR) = tempEndT;
                    EndS(tempindexS) = tempEndT;
                    Q2nd(tempindexNR) = Q2nd(tempindexNR) - 1;
                    indexlevel2(2,tempindexNR) = indexlevel2(2,tempindexNR) + 1;
                    InforDelayed(tempindexNR*2,indexlevel2(2,tempindexNR)) = earlyT;
                else
                    if Q1st >0
                        StationNR(tempindexNR) = 1;
                        %                            tempEndT = earlyT + exprnd(30);
                        tempQ1st(tempindexNR) = tempQ1st(tempindexNR) + 1;
                        tempEndT = earlyT + exp22(index3);
                        index3 = index3+1;
                        EndNR(tempindexNR) = tempEndT;
                        %                             StationS(tempindexS) = 0;
                        %                             IdleindexS = [IdleindexS, tempindexS];
                        Q1st = Q1st - 1;
                    else
                        StationNR(tempindexNR) = 0;
                        IdleindexNR = [IdleindexNR, tempindexNR];
                    end
                    % find other idle NR with longest Q2nd(i) except tempindexNR
                    BlockQ2nd = IdleindexNR(Q2nd(IdleindexNR)>0);
                    % set the current NR idle
                    
                    if ~isempty(BlockQ2nd)
                        [~,indexLongQ] = max(Q2nd(BlockQ2nd));
                        tempindexNR_O = BlockQ2nd(indexLongQ);
                        StationNR(tempindexNR_O) = 2;
                        StationS(tempindexS) = 1;
                        IdleindexNR(IdleindexNR==tempindexNR_O) = [];
                        %                                tempEndT = earlyT + exprnd(15);
                        tempEndT = earlyT + exp23(index4);
                        index4 = index4+1;
                        EndS(tempindexS) = tempEndT;
                        EndNR(tempindexNR_O) = tempEndT;
                        Q2nd(tempindexNR_O) = Q2nd(tempindexNR_O) - 1;
                        indexlevel2(2,tempindexNR_O) = indexlevel2(2,tempindexNR_O) + 1;
                        InforDelayed(tempindexNR_O*2,indexlevel2(2,tempindexNR_O)) = earlyT;
                    else
                        StationS(tempindexS) = 0;
                        IdleindexS = [IdleindexS, tempindexS];
                    end
                end
            else
                Qrescue = Qrescue - 1;
                %                    tempEndT = earlyT + exprnd(30);
                tempEndT = earlyT + exp1(index1);
                index1 = index1 + 1;
                EndNR(tempindexNR) = tempEndT;
                EndS(tempindexS) = tempEndT;
            end
            [EarlyTime(4),index1st] = min([EndNR(StationNR == 1),Inf]);
            [EarlyTime(5),index2nd] = min([EndNR(StationNR == 2),Inf]);
            EarlyTime(6) = min([EndNR(StationNR==3), Inf]);
            
            
            %% if the next event is finishing observation
        otherwise
            % record the end of observation time
            tempindexObs = indexEarly - 6;
            indexlevel2(1,tempindexObs) = indexlevel2(1,tempindexObs) +1; % the number of patients end of 1st in server tempindexNR
            InforDelayed(tempindexObs*2-1,indexlevel2(1,tempindexObs)) = earlyT; %the first row represents the end of observation time, the second row denotes the start time on 2nd
            if StationNR(tempindexObs) == 0 && ~isempty(IdleindexS)
                tempindexS = IdleindexS(1);
                IdleindexS(1) = [];
                IdleindexNR(IdleindexNR==tempindexObs)=[];
                StationNR(tempindexObs) = 2;
                StationS(tempindexS) = 1;
                indexlevel2(2,tempindexObs) = indexlevel2(2,tempindexObs) + 1;
                InforDelayed(tempindexObs*2,indexlevel2(2,tempindexObs)) = earlyT;
                %                    tempEndT = earlyT + exprnd(15);
                tempEndT = earlyT + exp23(index4);
                index4 = index4 + 1;
                EndNR(tempindexObs) = tempEndT;
                EndS(tempindexS) = tempEndT;
            else
                Q2nd(tempindexObs) = Q2nd(tempindexObs) + 1;
            end
            EndObs(EndObs <= earlyT) = Inf;
            [EarlyTime(7:6+numofNR),~] = min(EndObs,[],2);
            [EarlyTime(5),index2nd] = min([EndNR(StationNR == 2),Inf]);
    end
    % update the time clock
    t = earlyT;
    %             total(d) = toc;
    %             d=d+1;
end
%     W1 = w1/length(find(Type == 1));
%     W2 = w2/(length(Type) - length(find(Type == 1)));
%     total(d) = toc;
%     d=d+1;
%count the number of patient arrive in day5 - day15
Ndelayed = zeros(1,Allocations(3));
for i = 1 : Allocations(3)
    tempindexWarm = find(InforDelayed(i*2,:)> warmday*24*60);
    tempW = InforDelayed(i*2,tempindexWarm) - InforDelayed(i*2-1,tempindexWarm);
    %tempW = InforDelayed(i*2,:) - InforDelayed(i*2-1,:);
    Ndelayed(i) = length(find(tempW >= Ut)); %- length(find(InforDelayed(i*2,:)<=warmday*24*60)) + length(find(InforDelayed(i*2,:)==0));
end
N_delayed = sum(Ndelayed);
countType = Type(aTrueArrive>=warmday*24*60);
TCost = Cost + cd*N_delayed;
W1 = w1/length(find(countType == 1));
W2 = w2/(length(find(countType == 2)));
W3 = w3/(length(find(countType == 3)));
end
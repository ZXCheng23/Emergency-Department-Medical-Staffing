%% generate samples
clear
clc
Allocations = StaffAllocation();
Asize = size(Allocations);
aSS_required = ones(1,Asize(1)).*1000; % generate 1000 observation for each allocation policy
k = Asize(1);
dayT = 15;
warmday = 5;
c = [100,133,166,200]./100;
Ut = 30;
cd = 10./100;
Vlambda = 10;
Vmu = [30 10 30 15 30];
Prop = [0.04 0.85 0.11];
SampleF = cell(1,k);
for  i = 1 : k
    tempSample = zeros(6,aSS_required(i));%[TCost,W2,W3,Cost,N_delayed,W1] 
    Allocation = Allocations(i,:);
parfor j = 1 : aSS_required(i)
    [tempTC,tempW2,tempW3,tempC,tempNdelayed,tempW1] = PerformanceofAllocationP(Allocation,dayT,warmday,Vlambda,Vmu,Prop,c,cd,Ut)
    tempSample(:,j) = [tempTC,tempW2,tempW3,tempC,tempNdelayed,tempW1]';
end
SampleF(i) = {tempSample};
disp(i)
end

save('Sample');

function Allocations = StaffAllocation()
Allocations = [];
for x2 = 1 : 4
    for x3 = 3 : 8
        for x1 = max(1,4-x3) : min(x2,10-x3)
            for x4 = 1 : min(4,x3)
                Allocations = [Allocations; x1, x2, x3, x4];
            end
        end
    end
end
end
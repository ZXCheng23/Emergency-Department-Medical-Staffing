function [TrueArrive, Type] = ArriveProcess(dayT,Vlambda,Prop)
%dayT = 30; % run one week
T = dayT*24*60;
%% generate the patient arrival process_ non-homogenous poisson
% 0a.m.-9a.m. 2.2/hour; 9am-3pm, 6.0/hour; 3pm-12pm, 5/hour
% Vlambda1 = 60/2.2; % mean of inter arrival time
% Vlambda2 = 10;
% Vlambda3 = 12;
%% generate the nonhomogeneous arrival process
NumberofArrival = random('poisson',T/Vlambda);
CarriveT = rand(1,NumberofArrival).*T;
TrueArrive = sort(CarriveT);
% CarriveT = sort(CarriveT);
% CarriveT1 = [];%cumulative arrival in
% CarriveT2 = [];
% CarriveT3 = [];
%divide the arrival into three parts with different arrival rate, named as QusiArrival1,2,3
% for i = 1 : dayT
%     CarriveT1 = [CarriveT1,setdiff(CarriveT(CarriveT <= (i-1)*60*24 + 9*60),CarriveT(CarriveT <= (i-1)*60*24))];
%     CarriveT2 = [CarriveT2,setdiff(CarriveT(CarriveT <= (i-1)*60*24 + 15*60),CarriveT(CarriveT <= (i-1)*60*24))];
%     CarriveT3 = [CarriveT3,setdiff(CarriveT(CarriveT <= (i-1)*60*24 + 24*60),CarriveT(CarriveT <= (i-1)*60*24))];
% end
% QusiArrive1 =  CarriveT1;
% QusiArrive2 = setdiff(CarriveT2,CarriveT1);
% QusiArrive3 = setdiff(CarriveT3,CarriveT2);
%Sparse method to generate non-homogeneous Poisson: reserve the arrival with prob Vlambda/Vlambda1
% count1 = length(QusiArrive1);
% count2 = length(QusiArrive2);
% count3 = length(QusiArrive3);
% Rrand1 = rand(1,count1);
% Rrand2 = rand(1,count2);
% Rrand3 = rand(1,count3);
% ReserveCarrive1 = QusiArrive1;
% ReserveCarrive1(Rrand1 > Vquasilambda/Vlambda(1)) = [];
% ReserveCarrive2 = QusiArrive2;
% ReserveCarrive2(Rrand2 > Vquasilambda/Vlambda(2)) = [];
% ReserveCarrive3 = QusiArrive3;
% ReserveCarrive3(Rrand3 > Vquasilambda/Vlambda(3)) = [];
% TrueArrive =[ReserveCarrive1,ReserveCarrive2,ReserveCarrive3];
% TrueArrive = sort(TrueArrive); % The true nonhomogeneous poisson arrival
%% generate the type of each arrival
% PropS1 = 0.04; %proportion of type1
% PropS2 = 0.845;
% PropS3 = 0.115;
PropS1 = Prop(1); %proportion of type1
PropS2 = Prop(2);
PropS3 = Prop(3);
NumofArrival = length(TrueArrive);
Type = zeros(1,NumofArrival); % store the type of each arrival
Trand = rand(1,NumofArrival);
Type1 = find(Trand < PropS1);
Type2 = setdiff(find(Trand < PropS1 + PropS2),Type1);
Type3 = setdiff((1:1:NumofArrival),find(Trand < PropS1 + PropS2));
Type(Type1) = 1;% Tag the type of each arrival
Type(Type2) = 2;
Type(Type3) = 3;
end
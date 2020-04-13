% MMS 排队模拟仿真，S个平行服务的服务台，只有一个队列，先到先接受服务，队列无限长。
% 部分借鉴 %一颗修行千年的葱% 的 MM1 模型
% 作者：Zhennan Kou，时间：12/Mar/2020

clear 
clc 
%***************************************** 
%初始化顾客源 
%***************************************** 
S = 2; %服务数是2
%总仿真时间 
Total_time = 3000;  
%到达率与服务率 
lambda = 3; 
mu = 4; 
%平均到达时间与平均服务时间 
arr_mean = 1/lambda; 
ser_mean = 1/mu; 
arr_num = Total_time*lambda*10; 
%events矩阵：第一行是顾客到达时刻；
%第二行是顾客所需服务时间；
%第三行是顾客排队时间；
%第四行是顾客进入服务的时刻；
%第五行是顾客离开时刻；
%第六行是顾客到来时的队列长度（包括他自己）；
%第七行是顾客到来时系统中的总人数（包括他自己）。
events = []; 
%按负指数分布产生各顾客达到时间间隔 
events(1,:) = exprnd(arr_mean,1,arr_num); 
%各顾客的到达时刻等于时间间隔的累积和 
events(1,:) = cumsum(events(1,:)); 
%按负指数分布产生各顾客服务时间 
events(2,:) = exprnd(ser_mean,1,arr_num); 
%计算仿真顾客个数，即到达时刻在仿真时间内的顾客数 
len_sim = sum(events(1,:)<= Total_time);
%删除到达时间大于total time的顾客
events(:,events(1,:)>Total_time) = [];

SS = zeros(2,S); %服务台矩阵
SS(1,:) = [1:S]; %服务台编号

%***************************************** 
%计算前 S个顾客的信息 
%***************************************** 
%第 S个顾客进入系统后直接接受服务，无需等待 
for i = 1:S
    events(3,i) = 0; 
    %其进入服务时刻就是其到达时刻
    events(4,i) = events(1,i);
    %其离开时刻等于其到达时刻与服务时间之和 
    events(5,i) = events(1,i)+events(2,i); 
    %前S个顾客不需排队 
    events(6,i) = 0; 
    %系统中总人数:第i个顾客到来时多少顾客尚未离开
    if i == 1 %第一个顾客，系统中只有他自己
        events(7,i) = 1;
    else %第二个，第三个。。。
        events(7,i) = sum(events(5,1:i-1) > events(1,i))+1; %+1是因为算上他自己
    end
    %记录此服务台使用完毕的时刻
    SS(2,i) = events(5,i);
    %其进入系统后，系统内已有成员序号为 1:S 
end


for i = S+1:length(events(1,:)) 
    %判断需不需要排队
    need_in_line = sum(events(1,i) < min(SS(2,:)));
    %不需要排队的情况
    if need_in_line == 0
        %开始服务的时刻
        events(4,i) = events(1,i);
        %离开时间
        events(5,i) = events(1,i)+events(2,i);
        %队列长度为零
        events(6,i) = 0;
        %系统中总人数
        events(7,i) = sum(events(5,1:i-1) > events(1,i))+1; %+1是因为算上他自己
        %服务台服务结束时间更新
        SS(2,SS(2,:)==min(SS(2,:))) = events(5,i);
    else
        %此人等待时间为最先完成服务的服务台时刻减去他到达的时刻
        events(3,i) = min(SS(2,:))-events(1,i);
        %其开始服务时刻等于其到达时刻加上其等待时间
        events(4,i) = min(SS(2,:));
        %其离开时刻等于其到达时刻加等待时间加服务时间
        events(5,i) = events(4,i)+events(2,i);
        %其到来时队列长度等于他之前尚未开始服务的人数
        events(6,i) = sum(events(4,1:i-1)>events(1,i))+1; %+1是因为算上他自己
        %系统中总人数
        events(7,i) = sum(events(5,1:i-1) > events(1,i))+1; %+1是因为算上他自己
        %服务台服务结束时间更新
        SS(2,SS(2,:)==min(SS(2,:))) = events(5,i);
    end
end
            
%%%%%%%%%%%%%% 数据处理与绘图 %%%%%%%%%%%%%  

%仿真结束时，进入系统的总顾客数 
len_mem = length(events); 
member = 1:len_mem;
%平均排队时间
time_in_line = mean(events(3,:))*60; %单位：分钟
%一个人从来到走所花的平均时间
time_spent = mean(events(5,:)-events(1,:))*60; %单位：分钟

%下面要计算排队人数与系统总人数与时间的关系，这里人数更新频率为每分钟
%为排队人数矩阵分配空间
people_in_line = zeros(60,Total_time); %列是小时，行是分钟
people_in_system = zeros(60,Total_time); %列是小时，行是分钟
%计算每分钟排队的人数和每分钟在系统中的人数
for HOUR = 0:Total_time-1; %第几个小时
    for MIN = 0:59 %第几分钟
        time = HOUR+MIN/60; %换回小时单位
        %排队中的人数等于这一分钟之前到来，并且没有开始接受服务的人
        people_in_line(MIN+1,HOUR+1) = sum((events(1,:)<time)&(events(4,:)>=time));
        %系统中的人数等于这一分钟之前到来，并且没有结束接受服务的人
        people_in_system(MIN+1,HOUR+1) = sum((events(1,:)<time)&(events(5,:)>=time));
    end
end

%从0到total_ttime,每一个小时的平均队列长度
line_length_per_hour = mean(people_in_line,1);
system_length_per_hour = mean(people_in_system,1);

%在总仿真时间内每小时平均队列长度
line_length = mean(line_length_per_hour);
%在总仿真时间内每小时平均系统中人数
system_length = mean(system_length_per_hour);

fprintf('平均等待时长：%.2f min\n',time_in_line);
fprintf('每人完成服务平均花费时长：%.2f min\n',time_spent);
fprintf('平均每小时队列长度：%.2f 人\n',line_length);
fprintf('平均每小时系统中人数：%.2f 人\n',system_length);


%绘制在仿真时间内，进入系统的所有顾客的到达时刻和离 
%开时刻曲线图（stairs：绘制二维阶梯图） 
stairs(0:len_mem,[0 events(1,member)]); 
hold on; 
stairs(0:len_mem,[0 events(5,member)],'.-r'); 
legend('到达时间 ','离开时间 '); 
hold off; 
grid on; 
%绘制在仿真时间内，进入系统的所有顾客的停留时间和等 
%待时间曲线图（plot：绘制二维线性图） 
figure; 
plot(1:len_mem,events(3,:),'r-*',1:len_mem,events(5,:)-events(1,:),'k-'); 
legend('等待时间 ','停留时间 '); 
grid on;

%平均每小时排队人数，平均每小时系统人数与模拟时间长度的关系
%刻画了队长与系统人数平均值与模拟时间的关系，模拟时间越长，数值越接近平均值
mean_line_length = zeros(1,Total_time);
mean_system_length = zeros(1,Total_time);
for i = 1:Total_time
    mean_line_length(i) = mean(line_length_per_hour(1:i));
    mean_system_length(i) = mean(system_length_per_hour(1:i));
end
figure; 
plot(0:Total_time-1,mean_line_length,'r-',0:Total_time-1,mean_system_length,'b-'); 
legend('平均每小时系统中人数 ','平均每小时队列中人数 '); 
grid on;

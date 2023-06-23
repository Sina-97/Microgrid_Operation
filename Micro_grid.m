clc
clear all
close all
Ppv=[0 0 0 0 0.2 0.4 0.6 0.8 1 1.2 1.3 1.5 1.6 1.6 1.7 1.5 1.4 0.8 0.7 0.4 0.3 0.2 0 0];
Pwind=[0.06 0.08 0.07 0.09 0.1 0.1 0.11 0.11 0.12 0.13 0.13 0.12 0.13 0.13 0.12 0.11 0.11 0.1 0.9 0.08 0.07 0.05 0.06 0.07];
Pel_load=[3 3.6 3.5 4.1 4.6 6.1 7.1 7.7 7.9 5.8 5.6 6 6.4 6.5 7 5.1 8.6 11 13.3 13.8 11.2 11 7.8 6];
Pth_load=[3.5 3.2 2.5 2.8 3.2 3.5 3 4.4 7 9.5 10 9 7.5 5.8 4.8 6.4 6.8 7.7 7.5 6.7 7.5 6.5 5.5 4.5];
eps_st=0.95;eps_bat=0.98;
sohmin=1;socmin=0.6;sohmax=10;socmax=6.5;
Pfc_min=0.2*15;Pfc_max=1*15;
Pmt_min=0.3*10;Pmt_max=1*10;
Pbat_min=-0.04*socmax;Pbat_max=0.1*socmax;
Pst_min=-0.1*sohmax;Pst_max=0.1*sohmax;
x0=ones(1,120);
Ptrade_min=-6;
Ptrade_max=6;
LB=[];UB=[];
A=[];b=[];
nonlcon=@n_linear;
options=optimset('MaxFunEvals',100000,'TolX',1e-15);
[x,fval,exitflag,output]=fmincon(@Cost_Fun,x0,A,b,[],[],LB,UB,nonlcon,options)
P=x;
for i=1:120
    if abs(P(i))<0.001
        P(i)=0;
    end

end
Pfc=P(1:24);Pmt=P(25:48);Pbat=P(49:72);Pst=P(73:96);P_wind=P(97:120);

for h=1:24

    if Pfc(h)>0.001
        Ptrade(h)=Pel_load(h)-Ppv(h)-P(h+96)-P(24+h)-P(h)-P(48+h);
    else
        Ptrade(h)=Pel_load(h);
    end
end
figure(1)
subplot(1,2,1);
bar(Pfc,'r');
title('P fuell cell');
ylabel('KW');
xlabel('hour');
subplot(1,2,2);
bar(Pmt,'g');
title('P micro turbine');
ylabel('KW');
xlabel('hour');
figure(2);
dim = [.2 .8 .8 .2];
str='P<0 :sell    P>0 :buy';
annotation('textbox',dim,'String',str,'FitBoxToText','on');
bar(Ptrade);
title('P trade');
ylabel('KW');
xlabel('hour');
figure(3)
dim = [.35 .7 .8 .3];
str='P<0:Charge    P>0:Discharge';
annotation('textbox',dim,'String',str,'FitBoxToText','on');
subplot(1,2,1);
bar(Pbat,'r');
title('P bat');
ylabel('KW');
xlabel('hour');
subplot(1,2,2);
bar(Pst,'g');
title('P st');
ylabel('KW');
xlabel('hour');
figure(4)
bar(P_wind);
title('P Wind');
ylabel('KW');
xlabel('hour');
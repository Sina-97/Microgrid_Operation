function Cost_T=Cost_Fun(P)
% P=a1;
soc0=1;
soh0=2;
t_on=4;t_off=2;
flag=[0 0];flag1=0;
Ptrade_min=-6;
Ptrade_max=6;
Kom_fc=0.00419;
Kom_mt=0.00587;
ro_NOx=4.2;ro_SO2=0.99;ro_CO2=0.014;
EF_NOx_fc=0.03;EF_NOx_mt=0.44;EF_SO2_fc=0.006;EF_SO2_mt=0.008;EF_CO2_fc=1.078;EF_CO2_mt=1.596;
Ppv=[0 0 0 0 0.2 0.4 0.6 0.8 1 1.2 1.3 1.5 1.6 1.6 1.7 1.5 1.4 0.8 0.7 0.4 0.3 0.2 0 0];
Pwind=[0.06 0.08 0.07 0.09 0.1 0.1 0.11 0.11 0.12 0.13 0.13 0.12 0.13 0.13 0.12 0.11 0.11 0.1 0.9 0.08 0.07 0.05 0.06 0.07];
Pel_load=[3 3.6 3.5 4.1 4.6 6.1 7.1 7.7 7.9 5.8 5.6 6 6.4 6.5 7 5.1 8.6 11 13.3 13.8 11.2 11 7.8 6];
Pth_load=[3.5 3.2 2.5 2.8 3.2 3.5 3 4.4 7 9.5 10 9 7.5 5.8 4.8 6.4 6.8 7.7 7.5 6.7 7.5 6.5 5.5 4.5];
ro_buy=[0.023 0.018 0.025 0.022 0.022 0.026 0.033 0.032 0.03 0.057 0.036 0.027 0.026 0.024 0.03 0.027 0.032 0.1 0.046 0.036 0.029 0.038 0.03 0.024];
ro_sell=[0.023 0.018 0.025 0.022 0.022 0.026 0.033 0.032 0.03 0.068 0.036 0.027 0.026 0.024 0.03 0.027 0.032 0.124 0.046 0.036 0.029 0.038 0.03 0.024];
rand_boiler=0.9;rand_th_fc=0.7;rand_th_mt=0.85;rand_bat=0.8;%#ok<*NASGU>
LHV=35.2;
mfuel_fc=0.5;mfuel_mt=0.4;
ro_fuel=0.015;
eps_st=0.95;eps_bat=0.98;
sohmin=1;socmin=0.6;sohmax=10;socmax=6.5;
afc=-0.0066;bfc=0.6198;amt=0.3985;bmt=0.8571;
t=0;
Cost_s=0;
flag_uc=0;
for h=1:24
    flag3=0;
    flag4=0;
    deltah=1;
    counter=1;
    while (flag3==0)
        %Fuel Cell
        
        rand_el_fc(h)=afc* P(h)+bfc;
        Pth_fc(h)=rand_th_fc*(P(h)*(1-rand_el_fc(h))/rand_el_fc(h));
        Pfuel_fc(h)=mfuel_fc*LHV;
        if abs(P(h))<0.00000001
            Pth_fc(h)=0;
            Pfuel_fc(h)=0;
        end
        
        rand_fc=(Pth_fc(h)+P(h))/Pfuel_fc(h);
        
        %Microturbine
        
        rand_el_mt(h)=(amt*P(24+h))/(bmt+P(24+h));
        Pth_mt(h)=rand_th_mt*(P(24+h)*(1-rand_el_mt(h))/rand_el_mt(h));
        Pfuel_mt(h)=LHV*mfuel_mt;
        if abs(P(h+24))<0.00000001
            Pth_mt(h)=0;
            Pfuel_mt(h)=0;
        end
        
        
        %Battery
        
        Ebat(h)=P(48+h)*deltah;
        soc(h)=(eps_bat)*soc0-(rand_bat*Ebat(h));
        
        %Storage
        
        Est(h)=P(72+h)*deltah;
        soh(h)=(eps_st)*soh0-Est(h);
        
        %Cost of Trade
        if flag4==0
            Ptrade(h)=Pel_load(h)-Ppv(h)-P(h+96)-P(24+h)-P(h)-P(48+h);
            if Ptrade(h)>0
                Strade=1;
            elseif Ptrade(h)<=0
                Strade=0;
            end
            Cost_trade(h)=(ro_buy(h)*Ptrade(h)*Strade)+(ro_sell(h)*Ptrade(h)*(1-Strade));
        end
        %Cost of MT & FC & Boiler's Fuel
        
        Pboiler(h)=Pth_load(h)-Pth_mt(h)-Pth_fc(h)-P(72+h);
        if Pboiler(h)<0
            Pboiler(h)=0;
        end
        Pfuel_boiler(h)=Pboiler(h)/rand_boiler;
        Cost_fuel(h)=ro_fuel*(Pfuel_boiler(h)+Pfuel_fc(h)+Pfuel_mt(h));
        
        %Cost of OM
        
        Cost_om(h)=Kom_fc*P(h)+Kom_mt*P(24+h);
        
        %Cost of Emission
        
        Cost_emission(h)=ro_NOx*(EF_NOx_fc*P(h)+EF_NOx_mt*P(24+h))+ro_SO2*(EF_SO2_fc*P(h)+EF_SO2_mt*P(24+h))+ro_CO2*(EF_CO2_fc*P(h)+EF_CO2_mt*P(24+h));
        
        %Cost of Start=0.1
        
        %Unit Commitment
        Cost_total(h)=Cost_trade(h)+Cost_fuel(h)+Cost_om(h)+Cost_emission(h);
        if Cost_total(h)>(ro_buy(h)*Pel_load(h))
            flag_uc=1;
        end
        if flag_uc==1
            error=zeros(1,24);
            if Pel_load(h)<=Ptrade_max
                Cost_trade_uc(h)=Pel_load(h)*ro_buy(h);
            else
                Cost_trade_uc(h)=Ptrade_max*ro_buy(h);
            end
            if t>=t_off && flag1(1)==1
                flag(2)=0;
                if Pel_load(h)>Ptrade_max
                    t=0;
                end
            end
            if t>=t_on && flag1(1)==0
                flag(1)=0;
                if Pel_load(h)<=Ptrade_max
                    t=0;
                end
            end
            
            if Pel_load(h)<=Ptrade_max && flag(1)==0
                flag1(1)=1;
                if t==0
                    flag(2)=1;
                end
            end
            
            if Pel_load(h)>Ptrade_max && flag(2)==0
                flag1(1)=0;
                if t==0
                    flag(1)=1;
                    Cost_s=Cost_s+0.05;
                end
            elseif Pel_load(h)>Ptrade_max && flag(2)==1
                error(h)=1;
            end
            if flag1(1)==1
                Cost_trade(h)=  Cost_trade_uc(h);
                flag4=1;
                Ptrade(h)=Pel_load(h);
                P(h)=0;
                P(24+h)=0;
                P(48+h)=0;
                P(72+h)=0;
                
            end
        end
        if counter==2
            flag3=1;
        end
        counter=counter+1;
    end
    t=t+1;
    %Total Cost
    Cost_total(h)=Cost_trade(h)+Cost_fuel(h)+Cost_om(h)+Cost_emission(h)+P(96+h)*ro_buy(h)/2;
    soc0=soc(h);
    soh0=soh(h);
end
%Cost Function

Cost_T=sum(Cost_total)+Cost_s;

end
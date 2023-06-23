function [c ceq]=n_linear(P)
% P=a1;
t_on=4;t_off=2;
flag=[0 0];flag1=0;
soc0=1;
soh0=2;
Ptrade_min=-6;
Ptrade_max=6;
Pboiler_max=24;
Kom_fc=0.00419;
Kom_mt=0.00587;
ro_NOx=4.2;ro_SO2=0.99;ro_CO2=0.014;
Pfc_min=ones(1,24)*0.2*18;
Pfc_max=ones(1,24)*1*18;
Pmt_min=ones(1,24)*0.3*8;
Pmt_max=ones(1,24)*1*8;
error=zeros(1,24);
EF_NOx_fc=0.03;EF_NOx_mt=0.44;EF_SO2_fc=0.006;EF_SO2_mt=0.008;EF_CO2_fc=1.078;EF_CO2_mt=1.596;
Ppv=[0 0 0 0 0.2 0.4 0.6 0.8 1 1.2 1.3 1.5 1.6 1.6 1.7 1.5 1.4 0.8 0.7 0.4 0.3 0.2 0 0];
Pwind=[0.06 0.08 0.07 0.09 0.1 0.1 0.11 0.11 0.12 0.13 0.13 0.12 0.13 0.13 0.12 0.11 0.11 0.1 0.9 0.08 0.07 0.05 0.06 0.07];
Pel_load=[3 3.6 3.5 4.1 4.6 6.1 7.1 7.7 7.9 5.8 5.6 6 6.4 6.5 7 5.1 8.6 11 13.3 13.8 11.2 11 7.8 6];
Pth_load=[3.5 3.2 2.5 2.8 3.2 3.5 3 4.4 7 9.5 10 9 7.5 5.8 4.8 6.4 6.8 7.7 7.5 6.7 7.5 6.5 5.5 4.5];
ro_buy=[0.023 0.018 0.025 0.022 0.022 0.026 0.033 0.032 0.03 0.057 0.036 0.027 0.026 0.024 0.03 0.027 0.032 0.1 0.046 0.036 0.029 0.038 0.03 0.024];
ro_sell=[0.023 0.018 0.025 0.022 0.022 0.026 0.033 0.032 0.03 0.068 0.036 0.027 0.026 0.024 0.03 0.027 0.032 0.124 0.046 0.036 0.029 0.038 0.03 0.024];
rand_boiler=0.9;rand_th_fc=0.7;rand_th_mt=0.85;rand_bat=0.8; %#ok<*NASGU>
LHV=35.2;
mfuel_fc=0.5;mfuel_mt=0.4;
ro_fuel=0.015;
eps_st=0.95;eps_bat=0.98;
sohmin=1;socmin=0.6;sohmax=10;socmax=6.5;
Pbat_min=ones(1,24)*-0.04*socmax;Pbat_max=ones(1,24)*0.1*socmax;
Pst_min=ones(1,24)*-0.1*sohmax;Pst_max=ones(1,24)*0.1*sohmax;
afc=-0.0066;bfc=0.6198;amt=0.3985;bmt=0.8571;
t=0;
flag_uc=0;
for h=1:24
    flag4=0;
    flag3=0;
    counter=1;
    while (flag3==0)
        deltah=1;

        %Fuel Cell

        rand_el_fc(h)=afc*P(h)+bfc;
        Pth_fc(h)=rand_th_fc*(P(h)*(1-rand_el_fc(h))/rand_el_fc(h));
        Pfuel_fc(h)=mfuel_fc*LHV;
        if abs(P(h))<0.0000000001
            Pth_fc(h)=0;
            Pfuel_fc(h)=0;
        end

        rand_fc=(Pth_fc(h)+P(h))/Pfuel_fc(h);

        %Microturbine

        rand_el_mt(h)=(amt*P(h+24))/(bmt+P(h+24));
        Pth_mt(h)=rand_th_mt*(P(h+24)*(1-rand_el_mt(h))/rand_el_mt(h));
        Pfuel_mt(h)=LHV*mfuel_mt;
        if abs(P(h+24))<0.000000001
            Pth_mt(h)=0;
            Pfuel_mt(h)=0;
        end


        %Battery

        Ebat(h)=P(h+48)*deltah;
        soc(h)=(eps_bat)*soc0-(rand_bat*Ebat(h));

        %Storage

        Est(h)=P(h+72)*deltah;
        soh(h)=(eps_st)*soh0-Est(h);

        %Cost of Trade
        if flag4==0
            Ptrade(h)=Pel_load(h)-Ppv(h)-P(h+96)-P(h+24)-P(h)-P(h+48);
            if Ptrade(h)>0
                Strade=1;
            elseif Ptrade(h)<=0
                Strade=0;
            end
            Cost_trade(h)=(ro_buy(h)*Ptrade(h)*Strade)+(ro_sell(h)*Ptrade(h)*(1-Strade));
        end
        %Cost of MT & FC & Boiler's Fuel

        Pboiler(h)=Pth_load(h)-Pth_mt(h)-Pth_fc(h)-P(h+72);
        if Pboiler(h)<=0
            Pboiler(h)=0;
        end
        Pfuel_boiler(h)=Pboiler(h)/rand_boiler;
        Cost_fuel(h)=ro_fuel*(Pfuel_boiler(h)+Pfuel_fc(h)+Pfuel_mt(h));

        %Cost of OM

        Cost_om(h)=Kom_fc*P(h)+Kom_mt*P(h+24);

        %Cost of Emission

        Cost_emission(h)=ro_NOx*(EF_NOx_fc*P(h)+EF_NOx_mt*P(h+24))+ro_SO2*(EF_SO2_fc*P(h)+EF_SO2_mt*P(h+24))+ro_CO2*(EF_CO2_fc*P(h)+EF_CO2_mt*P(h+24));

        %Cost of Start=0.1


        %Unit Commitment
        Cost_total(h)=Cost_trade(h)+Cost_fuel(h)+Cost_om(h)+Cost_emission(h);
        if Cost_total(h)>(ro_buy(h)*Pel_load(h))
            flag_uc=1;
        end
        if flag_uc==1
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
                end
            elseif Pel_load(h)>Ptrade_max && flag(2)==1
                error(h)=1;
            end
            if flag1(1)==1
                flag4=1;
                Cost_trade(h)=  Cost_trade_uc(h);
                Ptrade(h)=Pel_load(h);
                Pfc_min(h)=0;
                Pmt_min(h)=0;
                Pbat_min(h)=0;
                Pst_min(h)=0;
                Pfc_max(h)=0;
                Pmt_max(h)=0;
                Pbat_max(h)=0;
                Pst_max(h)=0;
            end
        end
        if counter==2
            flag3=1;
        end
        counter=counter+1;
    end
    t=t+1;

    %Constraint

    risk_data(h)=P(96+h)/Pwind(h);

    zo(h,1)=Pboiler(h)-Pboiler_max;
    zo(h+24,1)=-Pboiler(h);
    zo(h+48,1)=soc(h)-socmax;
    zo(h+72,1)=socmin-soc(h);
    zo(h+96,1)=soh(h)-sohmax;
    zo(h+120,1)=sohmin-soh(h);
    zo(h+144,1)=P(h)-Pfc_max(h);
    zo(h+168,1)=Pfc_min(h)-P(h);
    zo(h+192,1)=P(h+24)-Pmt_max(h);
    zo(h+216,1)=Pmt_min(h)-P(h+24);
    zo(h+240,1)=P(h+48)-Pbat_max(h);
    zo(h+264,1)=Pbat_min(h)-P(48+h);
    zo(h+288,1)=P(h+72)-Pst_max(h);
    zo(h+312,1)=Pst_min(h)-P(72+h);
    zo(h+336,1)=Ptrade(h)-Ptrade_max;
    zo(h+360,1)=Ptrade_min-Ptrade(h);
    zo(h+384,1)=P(h+96)-1.8;
    zo(h+408,1)=-P(h+96);
    zo(h+432,1)=risk_data(h)-7;
    soc0=soc(h);
    soh0=soh(h);

end
zo(457,1)=sum(risk_data(:))/24-6;
ceq=[];
c=zo;

end
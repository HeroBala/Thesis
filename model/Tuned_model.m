%% ============================================================
% FINAL TUNED WIND TURBINE MODEL + SCOPES + SCADA VALIDATION
%% ============================================================

bdclose all
clear
clc

%% ============================================================
% 1. LOAD SCADA DATA
%% ============================================================

scada = readtable('../data/scada_power_curve.csv');

V_real = scada.wind_speed;
P_real = scada.power;

t = (0:length(V_real)-1)';
wind_input = [t V_real];

%% ============================================================
% 2. PARAMETERS (STABLE)
%% ============================================================

rho = 1.225;
R   = 40;
A   = pi * R^2;

lambda_opt = 8;
Cp_opt     = 0.45;

Kopt = 0.5 * rho * A * Cp_opt * (R^3 / lambda_opt^3);

J = 5e4;
eps_val = 0.5;

P_rated = max(P_real) * 1000;

%% ============================================================
% 3. CREATE MODEL
%% ============================================================

model = 'WT_MPPT_SCOPES_FINAL_v2';

new_system(model)
open_system(model)

set_param(model,...
    'StopTime',num2str(length(V_real)),...
    'Solver','ode4',...
    'FixedStep','0.1');

x=50; y=50; dx=160; dy=100;

%% ============================================================
% WIND INPUT
%% ============================================================

add_block('simulink/Sources/From Workspace',[model '/Wind'],...
'VariableName','wind_input',...
'Position',[x y x+120 y+40])

%% ============================================================
% CONSTANTS
%% ============================================================

add_block('simulink/Sources/Constant',[model '/R'],'Value',num2str(R))
add_block('simulink/Sources/Constant',[model '/eps'],'Value',num2str(eps_val))

%% ============================================================
% ROTOR DYNAMICS
%% ============================================================

add_block('simulink/Continuous/Integrator',[model '/omega'],...
'InitialCondition','10')

add_block('simulink/Discontinuities/Saturation',[model '/omega_sat'],...
'LowerLimit','0.1','UpperLimit','100')

add_line(model,'omega/1','omega_sat/1')

add_block('simulink/Math Operations/Sum',[model '/TorqueSum'],'Inputs','+-')
add_block('simulink/Math Operations/Gain',[model '/1_J'],'Gain',['1/' num2str(J)])

%% ============================================================
% TIP SPEED RATIO
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/Romega'])
add_block('simulink/Math Operations/Sum',[model '/v_safe'],'Inputs','++')
add_block('simulink/Math Operations/Divide',[model '/lambda'])

add_line(model,'omega_sat/1','Romega/1')
add_line(model,'R/1','Romega/2')

add_line(model,'Wind/1','v_safe/1')
add_line(model,'eps/1','v_safe/2')

add_line(model,'Romega/1','lambda/1')
add_line(model,'v_safe/1','lambda/2')

%% ============================================================
% Cp FUNCTION (TUNED)
%% ============================================================

add_block('simulink/User-Defined Functions/MATLAB Function',[model '/Cp'])

rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/Cp']);

chart.Script = [
'function Cp = Cp(lambda)' newline ...
'lambda = max(lambda,0.1);' newline ...
'lambda = min(lambda,12);' newline ...
'% tuned smoother Cp' newline ...
'Cp = 0.48*exp(-((lambda-8).^2)/8);' newline ...
'end'];

%% ============================================================
% POWER
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/v3'],'Inputs','3')

add_block('simulink/Math Operations/Gain',[model '/Aero'],...
'Gain',['0.5*1.225*pi*' num2str(R) '^2'])

add_block('simulink/Math Operations/Product',[model '/Power'])

add_block('simulink/Discontinuities/Saturation',[model '/P_limit'],...
'LowerLimit','0','UpperLimit',num2str(P_rated))

%% ============================================================
% TORQUE
%% ============================================================

add_block('simulink/Math Operations/Sum',[model '/omega_safe'],'Inputs','++')
add_block('simulink/Math Operations/Divide',[model '/T_aero'])

add_block('simulink/Discontinuities/Saturation',[model '/T_limit'],...
'LowerLimit','0','UpperLimit','1e6')

%% ============================================================
% MPPT
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/omega2'])
add_block('simulink/Math Operations/Gain',[model '/Kopt'],'Gain',num2str(Kopt))

%% ============================================================
% OUTPUT
%% ============================================================

add_block('simulink/Sinks/To Workspace',[model '/Power_out'],...
'VariableName','P_model_sim','SaveFormat','Array')

%% ============================================================
% CONNECTIONS (CRITICAL FIX)
%% ============================================================

add_line(model,'lambda/1','Cp/1')

add_line(model,'Wind/1','v3/1')
add_line(model,'Wind/1','v3/2')
add_line(model,'Wind/1','v3/3')

add_line(model,'v3/1','Aero/1')
add_line(model,'Aero/1','Power/2')
add_line(model,'Cp/1','Power/1')

% 🔥 IMPORTANT: USE LIMITED POWER EVERYWHERE
add_line(model,'Power/1','P_limit/1')
add_line(model,'P_limit/1','Power_out/1')
add_line(model,'P_limit/1','T_aero/1')

add_line(model,'omega_sat/1','omega_safe/1')
add_line(model,'eps/1','omega_safe/2')

add_line(model,'omega_safe/1','T_aero/2')

add_line(model,'T_aero/1','T_limit/1')
add_line(model,'T_limit/1','TorqueSum/1')

add_line(model,'omega_sat/1','omega2/1')
add_line(model,'omega_sat/1','omega2/2')
add_line(model,'omega2/1','Kopt/1')

add_line(model,'Kopt/1','TorqueSum/2')

add_line(model,'TorqueSum/1','1_J/1')
add_line(model,'1_J/1','omega/1')

save_system(model)

%% ============================================================
% RUN + Cp OPTIMIZATION
%% ============================================================

out = sim(model);
P_model_raw = out.P_model_sim(:,1) / 1000;

% Align model output to SCADA time
P_model_raw = interp1(out.tout, P_model_raw, t, 'linear','extrap');

% Ensure column vectors
P_real  = P_real(:);
P_model_raw = P_model_raw(:);

% Match lengths safely
min_len = min(length(P_real), length(P_model_raw));
P_real_cut  = P_real(1:min_len);
P_model_cut = P_model_raw(1:min_len);

% Compute Cp scaling
Cp_scale = sum(P_real_cut .* P_model_cut) / sum(P_model_cut.^2);

set_param([model '/Aero'],'Gain',...
    ['0.5*1.225*pi*' num2str(R) '^2*' num2str(Cp_scale)])

out = sim(model);
P_model = out.P_model_sim(:,1) / 1000;

%% ============================================================
% ALIGN + SORT
%% ============================================================

P_model = interp1(out.tout, P_model, t, 'linear','extrap');

[V_real, idx] = sort(V_real);
P_real = P_real(idx);
P_model = P_model(idx);

%% ============================================================
% PUBLICATION PLOT
%% ============================================================

figure('Color','white')
hold on

scatter(V_real,P_real,60,'k','filled')
plot(V_real,P_model,'k-','LineWidth',2)

xlabel('Wind Speed (m/s)','FontSize',12)
ylabel('Power (kW)','FontSize',12)
title('Wind Turbine Power Curve Validation','FontSize',14)

legend('SCADA','Model','Location','northwest')

set(gca,'Color','white','XColor','k','YColor','k','FontSize',11)

grid on
box on

%% ============================================================
% ERROR
%% ============================================================

RMSE = sqrt(mean((P_model - P_real).^2));
disp(['RMSE = ',num2str(RMSE),' kW'])
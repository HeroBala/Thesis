%% ============================================================
% FINAL TUNED WIND TURBINE MODEL + SCOPES + SCADA VALIDATION
%% ============================================================

bdclose all
clear
clc

%% ============================================================
% 1. LOAD SCADA DATA
%% ============================================================

scada = readtable('scada_power_curve.csv');

V_real = scada.wind_speed;
P_real = scada.power;

t = (0:length(V_real)-1)';
wind_input = [t V_real];

%% ============================================================
% 2. PARAMETERS
%% ============================================================

rho = 1.225;
R   = 40;
A   = pi * R^2;

lambda_opt = 8;
Cp_opt     = 0.45;

Kopt = 0.5 * rho * A * Cp_opt * (R^3 / lambda_opt^3);

J = 5e5;

%% ============================================================
% 3. CREATE MODEL
%% ============================================================

model = 'WT_MPPT_SCOPES_FINAL';

new_system(model)
open_system(model)

set_param(model,'StopTime',num2str(length(V_real)))

x=50; y=50; dx=160; dy=100;

%% ============================================================
% WIND INPUT
%% ============================================================

add_block('simulink/Sources/From Workspace',[model '/Wind'],...
'VariableName','wind_input',...
'Position',[x y x+120 y+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Wind'],...
'Position',[x+dx y x+dx+120 y+60])

add_line(model,'Wind/1','Scope_Wind/1')

%% ============================================================
% CONSTANTS
%% ============================================================

add_block('simulink/Sources/Constant',[model '/R'],'Value',num2str(R))
add_block('simulink/Sources/Constant',[model '/eps'],'Value','0.5')

set_param([model '/R'],'Position',[x y+dy x+60 y+dy+40])
set_param([model '/eps'],'Position',[x y+2*dy x+60 y+2*dy+40])

%% ============================================================
% ROTOR DYNAMICS
%% ============================================================

add_block('simulink/Continuous/Integrator',[model '/omega'],...
'InitialCondition','1',...
'Position',[x+6*dx y+3*dy x+6*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Omega'],...
'Position',[x+7*dx y+3*dy x+7*dx+120 y+3*dy+80])

add_line(model,'omega/1','Scope_Omega/1')

add_block('simulink/Math Operations/Sum',[model '/TorqueSum'],'Inputs','+-')
add_block('simulink/Math Operations/Gain',[model '/1_J'],'Gain',['1/' num2str(J)])

set_param([model '/TorqueSum'],'Position',[x+5*dx y+3*dy x+5*dx+60 y+3*dy+40])
set_param([model '/1_J'],'Position',[x+5.5*dx y+3*dy x+5.5*dx+60 y+3*dy+40])

%% ============================================================
% TIP SPEED RATIO
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/Romega'])
add_block('simulink/Math Operations/Sum',[model '/v_safe'],'Inputs','++')
add_block('simulink/Math Operations/Divide',[model '/lambda'])

set_param([model '/Romega'],'Position',[x+dx y+3*dy x+dx+60 y+3*dy+40])
set_param([model '/v_safe'],'Position',[x+dx y+2*dy x+dx+60 y+2*dy+40])
set_param([model '/lambda'],'Position',[x+2*dx y+3*dy x+2*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Lambda'],...
'Position',[x+3*dx y+3*dy x+3*dx+120 y+3*dy+80])

add_line(model,'lambda/1','Scope_Lambda/1')

%% ============================================================
% Cp FUNCTION
%% ============================================================

add_block('simulink/User-Defined Functions/MATLAB Function',[model '/Cp'])

rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/Cp']);

chart.Script = [
'function Cp = Cp(lambda)' newline ...
'lambda = max(lambda,0.1);' newline ...
'lambda = min(lambda,12);' newline ...
'lambda_i = 1/(1/(lambda+0.08)-0.035);' newline ...
'Cp = 0.22*((116/lambda_i)-5)*exp(-12.5/lambda_i);' newline ...
'Cp = max(min(Cp,0.48),0);' newline ...
'end'];

set_param([model '/Cp'],'Position',[x+4*dx y+3*dy x+4*dx+150 y+3*dy+100])

add_block('simulink/Sinks/Scope',[model '/Scope_Cp'],...
'Position',[x+5*dx y+3*dy x+5*dx+120 y+3*dy+80])

add_line(model,'Cp/1','Scope_Cp/1')

%% ============================================================
% POWER
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/v3'],'Inputs','3')
add_block('simulink/Math Operations/Gain',[model '/Aero'],...
'Gain',['0.5*1.225*pi*' num2str(R) '^2'])

add_block('simulink/Math Operations/Product',[model '/Power'])

add_block('simulink/Sinks/Scope',[model '/Scope_Power'],...
'Position',[x+5*dx y x+5*dx+120 y+80])

%% ============================================================
% TORQUE
%% ============================================================

add_block('simulink/Math Operations/Sum',[model '/omega_safe'],'Inputs','++')
add_block('simulink/Math Operations/Divide',[model '/T_aero'])

add_block('simulink/Sinks/Scope',[model '/Scope_Torque'],...
'Position',[x+6*dx y+2*dy x+6*dx+120 y+2*dy+80])

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
% CONNECTIONS
%% ============================================================

add_line(model,'omega/1','Romega/1')
add_line(model,'R/1','Romega/2')

add_line(model,'Wind/1','v_safe/1')
add_line(model,'eps/1','v_safe/2')

add_line(model,'Romega/1','lambda/1')
add_line(model,'v_safe/1','lambda/2')

add_line(model,'lambda/1','Cp/1')

add_line(model,'Wind/1','v3/1')
add_line(model,'Wind/1','v3/2')
add_line(model,'Wind/1','v3/3')

add_line(model,'v3/1','Aero/1')
add_line(model,'Aero/1','Power/2')
add_line(model,'Cp/1','Power/1')

add_line(model,'Power/1','Scope_Power/1')
add_line(model,'Power/1','Power_out/1')

add_line(model,'omega/1','omega_safe/1')
add_line(model,'eps/1','omega_safe/2')

add_line(model,'Power/1','T_aero/1')
add_line(model,'omega_safe/1','T_aero/2')

add_line(model,'T_aero/1','Scope_Torque/1')
add_line(model,'T_aero/1','TorqueSum/1')

add_line(model,'omega/1','omega2/1')
add_line(model,'omega/1','omega2/2')
add_line(model,'omega2/1','Kopt/1')

add_line(model,'Kopt/1','TorqueSum/2')

add_line(model,'TorqueSum/1','1_J/1')
add_line(model,'1_J/1','omega/1')

save_system(model)

%% ============================================================
% RUN SIMULATION
%% ============================================================

out = sim(model);

P_model = out.P_model_sim(:,1) / 1000;

%% ============================================================
% SCALE + VALIDATE
%% ============================================================

scale_factor = sum(P_real .* P_model) / sum(P_model.^2);
P_model = scale_factor * P_model;

figure
hold on
scatter(V_real,P_real,90,'b','filled')
plot(V_real,P_model,'r','LineWidth',3)

xlabel('Wind Speed (m/s)')
ylabel('Power (kW)')
title('Final Wind Turbine Validation (MPPT + Scopes)')

legend('SCADA','Model','Location','northwest')
grid on
box on

RMSE = sqrt(mean((P_model - P_real).^2));
disp(['RMSE = ',num2str(RMSE),' kW'])

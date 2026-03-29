%% ============================================================
% DYNAMIC WIND TURBINE SIMULATION MODEL (WORKING)
%% ============================================================

bdclose all
clear
clc

%% ============================================================
% INPUT DATA
%% ============================================================

scada = readtable('../data/scada_power_curve.csv');

V = scada.wind_speed(:);
t = (0:length(V)-1)';

wind_input = [t V];

%% ============================================================
% PARAMETERS
%% ============================================================

rho = 1.225;
R = 26;
A = pi * R^2;

lambda_opt = 7.5;
Cp_opt = 0.45;

J = 2e5;
eps_val = 0.5;

Kopt = 0.5 * rho * A * Cp_opt * (R^3 / lambda_opt^3);

%% ============================================================
% CREATE MODEL
%% ============================================================

model = 'WT_DYNAMIC_MODEL';
new_system(model)
open_system(model)

set_param(model,...
    'StopTime', num2str(length(V)),...
    'Solver','ode4',...
    'FixedStep','0.05');

%% ============================================================
% BLOCKS
%% ============================================================

% Wind input
add_block('simulink/Sources/From Workspace',[model '/Wind'],...
    'VariableName','wind_input')

% Constants
add_block('simulink/Sources/Constant',[model '/R'],'Value',num2str(R))
add_block('simulink/Sources/Constant',[model '/eps'],'Value',num2str(eps_val))

%% ROTOR SPEED
add_block('simulink/Continuous/Integrator',[model '/omega'],...
    'InitialCondition','6')

add_block('simulink/Discontinuities/Saturation',[model '/omega_sat'],...
    'LowerLimit','0.5','UpperLimit','40')

%% TIP SPEED RATIO
add_block('simulink/Math Operations/Product',[model '/Romega'])
add_block('simulink/Math Operations/Sum',[model '/v_safe'],'Inputs','++')
add_block('simulink/Math Operations/Divide',[model '/lambda'])

%% Cp FUNCTION
add_block('simulink/User-Defined Functions/MATLAB Function',[model '/Cp'])

rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/Cp']);

chart.Script = [
'function Cp = Cp(lambda)' newline ...
'lambda = max(lambda,0.1);' newline ...
'lambda_i = 1./(1./(lambda+0.08) - 0.035./(lambda.^3 + 1));' newline ...
'Cp = 0.22*((116./lambda_i)-5).*exp(-12.5./lambda_i);' newline ...
'Cp = max(0,min(0.45,Cp));' newline ...
'end'
];

%% POWER
add_block('simulink/Math Operations/Product',[model '/v3'],'Inputs','3')

add_block('simulink/Math Operations/Gain',[model '/Aero'],...
    'Gain',['0.5*' num2str(rho) '*pi*' num2str(R) '^2'])

add_block('simulink/Math Operations/Product',[model '/Power'])

%% TORQUE
add_block('simulink/Math Operations/Sum',[model '/omega_safe'],'Inputs','++')
add_block('simulink/Math Operations/Divide',[model '/T_aero'])

%% MPPT CONTROL
add_block('simulink/Math Operations/Product',[model '/omega2'])
add_block('simulink/Math Operations/Gain',[model '/Kopt'],...
    'Gain',num2str(Kopt))

%% DYNAMICS
add_block('simulink/Math Operations/Sum',[model '/TorqueSum'],'Inputs','+-')
add_block('simulink/Math Operations/Gain',[model '/1_J'],...
    'Gain',['1/' num2str(J)])

%% OUTPUT
add_block('simulink/Sinks/To Workspace',[model '/Power_out'],...
    'VariableName','P_sim','SaveFormat','Array')

%% ============================================================
% CONNECTIONS
%% ============================================================

% Rotor
add_line(model,'omega/1','omega_sat/1')

% TSR
add_line(model,'omega_sat/1','Romega/1')
add_line(model,'R/1','Romega/2')

add_line(model,'Wind/1','v_safe/1')
add_line(model,'eps/1','v_safe/2')

add_line(model,'Romega/1','lambda/1')
add_line(model,'v_safe/1','lambda/2')

% Cp
add_line(model,'lambda/1','Cp/1')

% Wind^3
add_line(model,'Wind/1','v3/1')
add_line(model,'Wind/1','v3/2')
add_line(model,'Wind/1','v3/3')

% Power
add_line(model,'v3/1','Aero/1')
add_line(model,'Aero/1','Power/2')
add_line(model,'Cp/1','Power/1')

% Torque
add_line(model,'Power/1','T_aero/1')

add_line(model,'omega_sat/1','omega_safe/1')
add_line(model,'eps/1','omega_safe/2')

add_line(model,'omega_safe/1','T_aero/2')

% MPPT
add_line(model,'omega_sat/1','omega2/1')
add_line(model,'omega_sat/1','omega2/2')

add_line(model,'omega2/1','Kopt/1')

% Dynamics
add_line(model,'T_aero/1','TorqueSum/1')
add_line(model,'Kopt/1','TorqueSum/2')

add_line(model,'TorqueSum/1','1_J/1')
add_line(model,'1_J/1','omega/1')

% Output
add_line(model,'Power/1','Power_out/1')

save_system(model)

%% ============================================================
% RUN SIMULATION
%% ============================================================

out = sim(model);

P_sim = interp1(out.tout, out.P_sim(:,1), t) / 1000;

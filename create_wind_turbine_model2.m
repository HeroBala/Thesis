%% ============================================================
% CREATE FULL NONLINEAR WIND TURBINE MODEL
% Thesis Plant Model with Multiple Scopes
%% ============================================================

bdclose all
clear
clc

model = 'WindTurbine_FullPlant';

new_system(model)
open_system(model)

set_param(model,'StopTime','20')

x = 50;
y = 50;
dx = 160;
dy = 100;

%% ------------------------------------------------------------
% WIND INPUT
%% ------------------------------------------------------------

add_block('simulink/Sources/Sine Wave',[model '/Wind'], ...
'Amplitude','2', ...
'Bias','10', ...
'Frequency','0.3', ...
'Position',[x y x+80 y+40])

%% Wind Scope
add_block('simulink/Sinks/Scope',[model '/Scope_Wind'], ...
'Position',[x+dx y x+dx+100 y+60])

add_line(model,'Wind/1','Scope_Wind/1')

%% ------------------------------------------------------------
% CONSTANTS
%% ------------------------------------------------------------

add_block('simulink/Sources/Constant',[model '/Radius'], ...
'Value','40', ...
'Position',[x y+dy x+60 y+dy+40])

add_block('simulink/Sources/Constant',[model '/Pitch'], ...
'Value','0', ...
'Position',[x y+2*dy x+60 y+2*dy+40])

add_block('simulink/Sources/Constant',[model '/Generator_Torque'], ...
'Value','6e5', ...
'Position',[x+5*dx y+3*dy x+5*dx+60 y+3*dy+40])

%% ------------------------------------------------------------
% ROTOR DYNAMICS
%% ------------------------------------------------------------

add_block('simulink/Continuous/Integrator',[model '/omega'], ...
'InitialCondition','1', ...
'Position',[x y+3*dy x+60 y+3*dy+40])

add_block('simulink/Math Operations/Sum',[model '/Torque_Sum'], ...
'Inputs','+-', ...
'Position',[x+4*dx y+3*dy x+4*dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Gain',[model '/1_over_J'], ...
'Gain','1/5e5', ...
'Position',[x+5*dx y+3*dy x+5*dx+60 y+3*dy+40])

%% Rotor speed scope
add_block('simulink/Sinks/Scope',[model '/Scope_Omega'], ...
'Position',[x+6*dx y+3*dy x+6*dx+100 y+3*dy+80])

%% ------------------------------------------------------------
% TIP SPEED RATIO
%% ------------------------------------------------------------

add_block('simulink/Math Operations/Product',[model '/R_times_w'], ...
'Position',[x+dx y+3*dy x+dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Divide',[model '/Lambda'], ...
'Position',[x+2*dx y+3*dy x+2*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Lambda'], ...
'Position',[x+3*dx y+3*dy x+3*dx+100 y+3*dy+80])

%% ------------------------------------------------------------
% WIND POWER TERM
%% ------------------------------------------------------------

add_block('simulink/Math Operations/Product',[model '/v_cubed'], ...
'Inputs','3', ...
'Position',[x+dx y x+dx+60 y+40])

add_block('simulink/Math Operations/Gain',[model '/Half_rho_A'], ...
'Gain','0.5*1.225*(pi*40^2)', ...
'Position',[x+2*dx y x+2*dx+120 y+40])

%% ------------------------------------------------------------
% CP NONLINEAR BLOCK
%% ------------------------------------------------------------

add_block('simulink/User-Defined Functions/MATLAB Function', ...
[model '/Cp_block'], ...
'Position',[x+3*dx y+3*dy x+3*dx+150 y+3*dy+100])

rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/Cp_block']);

chart.Script = [
'function Cp = Cp_block(lambda,beta)' newline ...
'lambda_i = 1/((1/(lambda+0.08*beta))-(0.035/(beta^3+1)));' newline ...
'Cp = 0.22*((116/lambda_i)-0.4*beta-5)*exp(-12.5/lambda_i);' newline ...
'end'];

%% Cp Scope
add_block('simulink/Sinks/Scope',[model '/Scope_Cp'], ...
'Position',[x+4*dx y+3*dy x+4*dx+100 y+3*dy+80])

%% ------------------------------------------------------------
% POWER AND TORQUE
%% ------------------------------------------------------------

add_block('simulink/Math Operations/Product',[model '/Cp_times_P'], ...
'Position',[x+4*dx y x+4*dx+60 y+40])

add_block('simulink/Math Operations/Divide',[model '/Torque'], ...
'Position',[x+4*dx y+2*dy x+4*dx+60 y+2*dy+40])

%% Torque Scope
add_block('simulink/Sinks/Scope',[model '/Scope_Torque'], ...
'Position',[x+5*dx y+2*dy x+5*dx+100 y+2*dy+80])

%% ------------------------------------------------------------
% CONNECTIONS
%% ------------------------------------------------------------

add_line(model,'omega/1','R_times_w/1')
add_line(model,'Radius/1','R_times_w/2')

add_line(model,'R_times_w/1','Lambda/1')
add_line(model,'Wind/1','Lambda/2')

add_line(model,'Lambda/1','Scope_Lambda/1')

add_line(model,'Lambda/1','Cp_block/1')
add_line(model,'Pitch/1','Cp_block/2')

add_line(model,'Cp_block/1','Scope_Cp/1')

add_line(model,'Wind/1','v_cubed/1')
add_line(model,'Wind/1','v_cubed/2')
add_line(model,'Wind/1','v_cubed/3')

add_line(model,'v_cubed/1','Half_rho_A/1')

add_line(model,'Half_rho_A/1','Cp_times_P/2')
add_line(model,'Cp_block/1','Cp_times_P/1')

add_line(model,'Cp_times_P/1','Torque/1')
add_line(model,'omega/1','Torque/2')

add_line(model,'Torque/1','Scope_Torque/1')

add_line(model,'Torque/1','Torque_Sum/1')
add_line(model,'Generator_Torque/1','Torque_Sum/2')

add_line(model,'Torque_Sum/1','1_over_J/1')
add_line(model,'1_over_J/1','omega/1')

add_line(model,'omega/1','Scope_Omega/1')

%% ------------------------------------------------------------
% SAVE MODEL
%% ------------------------------------------------------------

save_system(model)

disp('Wind Turbine Simulink model created successfully.')

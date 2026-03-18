%% ============================================================
% WIND TURBINE MODEL WITH MPPT OPTIMAL TORQUE CONTROL
% Full nonlinear aerodynamic model
%% ============================================================

bdclose all
clear
clc

model = 'WindTurbine_MPPT_Model';

new_system(model)
open_system(model)

set_param(model,'StopTime','20')

x=50;
y=50;
dx=160;
dy=100;

%% ============================================================
% WIND INPUT
%% ============================================================

add_block('simulink/Sources/Sine Wave',[model '/Wind'],...
'Amplitude','2','Bias','10','Frequency','0.3',...
'Position',[x y x+80 y+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Wind'],...
'Position',[x+dx y x+dx+120 y+60])

add_line(model,'Wind/1','Scope_Wind/1','autorouting','on')

%% ============================================================
% CONSTANTS
%% ============================================================

add_block('simulink/Sources/Constant',[model '/Radius'],...
'Value','40',...
'Position',[x y+dy x+60 y+dy+40])

add_block('simulink/Sources/Constant',[model '/Pitch'],...
'Value','0',...
'Position',[x y+2*dy x+60 y+2*dy+40])

%% ============================================================
% ROTOR DYNAMICS
%% ============================================================

add_block('simulink/Continuous/Integrator',[model '/omega'],...
'InitialCondition','1',...
'Position',[x+6*dx y+3*dy x+6*dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Sum',[model '/Torque_Sum'],...
'Inputs','+-',...
'Position',[x+5*dx y+3*dy x+5*dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Gain',[model '/1_over_J'],...
'Gain','1/5e5',...
'Position',[x+5.5*dx y+3*dy x+5.5*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Omega'],...
'Position',[x+7*dx y+3*dy x+7*dx+120 y+3*dy+80])

%% ============================================================
% TIP SPEED RATIO
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/R_times_w'],...
'Position',[x+dx y+3*dy x+dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Divide',[model '/Lambda'],...
'Position',[x+2*dx y+3*dy x+2*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Lambda'],...
'Position',[x+3*dx y+3*dy x+3*dx+120 y+3*dy+80])

%% ============================================================
% WIND POWER TERM
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/v_cubed'],...
'Inputs','3',...
'Position',[x+dx y x+dx+60 y+40])

add_block('simulink/Math Operations/Gain',[model '/Half_rho_A'],...
'Gain','0.5*1.225*(pi*40^2)',...
'Position',[x+2*dx y x+2*dx+120 y+40])

%% ============================================================
% Cp NONLINEAR FUNCTION
%% ============================================================

add_block('simulink/User-Defined Functions/MATLAB Function',...
[model '/Cp_block'],...
'Position',[x+4*dx y+3*dy x+4*dx+150 y+3*dy+100])

rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/Cp_block']);

chart.Script = [
'function Cp = Cp_block(lambda,beta)' newline ...
'lambda_i = 1/((1/(lambda+0.08*beta))-(0.035/(beta^3+1)));' newline ...
'Cp = 0.22*((116/lambda_i)-0.4*beta-5)*exp(-12.5/lambda_i);' newline ...
'end'];

add_block('simulink/Sinks/Scope',[model '/Scope_Cp'],...
'Position',[x+5*dx y+3*dy x+5*dx+120 y+3*dy+80])

%% ============================================================
% POWER AND TORQUE
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/Cp_times_P'],...
'Position',[x+4*dx y x+4*dx+60 y+40])

add_block('simulink/Math Operations/Divide',[model '/Torque'],...
'Position',[x+5*dx y+2*dy x+5*dx+60 y+2*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Torque'],...
'Position',[x+6*dx y+2*dy x+6*dx+120 y+2*dy+80])

%% ============================================================
% MPPT CONTROLLER  (T = Kopt * omega^2)
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/omega_squared'],...
'Position',[x+4*dx y+4*dy x+4*dx+60 y+4*dy+40])

add_block('simulink/Math Operations/Gain',[model '/Kopt'],...
'Gain','2.5e5',...
'Position',[x+5*dx y+4*dy x+5*dx+60 y+4*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_GeneratorTorque'],...
'Position',[x+6*dx y+4*dy x+6*dx+120 y+4*dy+80])

%% ============================================================
% CONNECTIONS
%% ============================================================

add_line(model,'omega/1','R_times_w/1','autorouting','on')
add_line(model,'Radius/1','R_times_w/2','autorouting','on')

add_line(model,'R_times_w/1','Lambda/1','autorouting','on')
add_line(model,'Wind/1','Lambda/2','autorouting','on')

add_line(model,'Lambda/1','Scope_Lambda/1','autorouting','on')

add_line(model,'Lambda/1','Cp_block/1','autorouting','on')
add_line(model,'Pitch/1','Cp_block/2','autorouting','on')

add_line(model,'Cp_block/1','Scope_Cp/1','autorouting','on')

add_line(model,'Wind/1','v_cubed/1','autorouting','on')
add_line(model,'Wind/1','v_cubed/2','autorouting','on')
add_line(model,'Wind/1','v_cubed/3','autorouting','on')

add_line(model,'v_cubed/1','Half_rho_A/1','autorouting','on')

add_line(model,'Half_rho_A/1','Cp_times_P/2','autorouting','on')
add_line(model,'Cp_block/1','Cp_times_P/1','autorouting','on')

add_line(model,'Cp_times_P/1','Torque/1','autorouting','on')
add_line(model,'omega/1','Torque/2','autorouting','on')

add_line(model,'Torque/1','Scope_Torque/1','autorouting','on')
add_line(model,'Torque/1','Torque_Sum/1','autorouting','on')

add_line(model,'Torque_Sum/1','1_over_J/1','autorouting','on')
add_line(model,'1_over_J/1','omega/1','autorouting','on')

add_line(model,'omega/1','Scope_Omega/1','autorouting','on')

%% MPPT LOOP

add_line(model,'omega/1','omega_squared/1','autorouting','on')
add_line(model,'omega/1','omega_squared/2','autorouting','on')

add_line(model,'omega_squared/1','Kopt/1','autorouting','on')

add_line(model,'Kopt/1','Scope_GeneratorTorque/1','autorouting','on')
add_line(model,'Kopt/1','Torque_Sum/2','autorouting','on')

%% SAVE

save_system(model)

disp('Wind turbine MPPT control model created successfully.')
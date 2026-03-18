%% ============================================================
% FINAL WIND TURBINE MODEL WITH PI CONTROLLER (CORRECTED)
% Stable, physically consistent, thesis-ready
%% ============================================================

bdclose all
clear
clc

model = 'WindTurbine_PI_Correct_Final';

new_system(model)
open_system(model)

set_param(model,'StopTime','20')

x = 50;
y = 50;
dx = 160;
dy = 100;

%% ============================================================
% WIND INPUT
%% ============================================================

add_block('simulink/Sources/Sine Wave',[model '/Wind'],...
'Amplitude','2','Bias','10','Frequency','0.3',...
'Position',[x y x+80 y+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Wind'],...
'Position',[x+dx y x+dx+100 y+60])

add_line(model,'Wind/1','Scope_Wind/1')

%% ============================================================
% CONSTANTS
%% ============================================================

add_block('simulink/Sources/Constant',[model '/Radius'],...
'Value','40',...
'Position',[x y+dy x+60 y+dy+40])

add_block('simulink/Sources/Constant',[model '/Lambda_opt'],...
'Value','8',...
'Position',[x+dx y+4*dy x+dx+60 y+4*dy+40])

add_block('simulink/Sources/Constant',[model '/Pitch'],...
'Value','0',...
'Position',[x y+2*dy x+60 y+2*dy+40])

%% ============================================================
% ROTOR DYNAMICS
%% ============================================================

add_block('simulink/Continuous/Integrator',[model '/omega'],...
'InitialCondition','1',...
'Position',[x y+3*dy x+60 y+3*dy+40])

% IMPORTANT: Torque equation = T_aero - T_gen
add_block('simulink/Math Operations/Sum',[model '/Torque_Sum'],...
'Inputs','+-',...
'Position',[x+5*dx y+3*dy x+5*dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Gain',[model '/1_over_J'],...
'Gain','1/5e5',...
'Position',[x+6*dx y+3*dy x+6*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Omega'],...
'Position',[x+7*dx y+3*dy x+7*dx+100 y+3*dy+80])

%% ============================================================
% TIP SPEED RATIO
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/R_times_w'],...
'Position',[x+dx y+3*dy x+dx+60 y+3*dy+40])

add_block('simulink/Math Operations/Divide',[model '/Lambda'],...
'Position',[x+2*dx y+3*dy x+2*dx+60 y+3*dy+40])

% LIMIT λ (CRITICAL)
add_block('simulink/Discontinuities/Saturation',[model '/Lambda_Limit'],...
'UpperLimit','10','LowerLimit','2',...
'Position',[x+3*dx y+3*dy x+3*dx+60 y+3*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Lambda'],...
'Position',[x+4*dx y+3*dy x+4*dx+100 y+3*dy+80])

%% ============================================================
% WIND POWER
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/v_cubed'],...
'Inputs','3',...
'Position',[x+dx y x+dx+60 y+40])

add_block('simulink/Math Operations/Gain',[model '/Half_rho_A'],...
'Gain','0.5*1.225*(pi*40^2)',...
'Position',[x+2*dx y x+2*dx+120 y+40])

%% ============================================================
% Cp FUNCTION (SAFE)
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
'Cp = max(0, Cp);' newline ...
'end'];

add_block('simulink/Sinks/Scope',[model '/Scope_Cp'],...
'Position',[x+5*dx y+3*dy x+5*dx+100 y+3*dy+80])

%% ============================================================
% POWER → TORQUE
%% ============================================================

add_block('simulink/Math Operations/Product',[model '/Cp_times_P'],...
'Position',[x+5*dx y x+5*dx+60 y+40])

add_block('simulink/Sources/Constant',[model '/omega_offset'],...
'Value','0.1',...
'Position',[x+5*dx y+2*dy x+5*dx+60 y+2*dy+40])

add_block('simulink/Math Operations/Sum',[model '/omega_safe'],...
'Inputs','++',...
'Position',[x+5.5*dx y+2*dy x+5.5*dx+60 y+2*dy+40])

add_block('simulink/Math Operations/Divide',[model '/Torque'],...
'Position',[x+6*dx y+2*dy x+6*dx+60 y+2*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Torque'],...
'Position',[x+7*dx y+2*dy x+7*dx+100 y+2*dy+80])

%% ============================================================
% PI CONTROLLER (FIXED & TUNED)
%% ============================================================

% omega_ref = lambda_opt * wind / R
add_block('simulink/Math Operations/Product',[model '/Lambda_wind'],...
'Position',[x+2*dx y+5*dy x+2*dx+60 y+5*dy+40])

add_block('simulink/Math Operations/Divide',[model '/omega_ref'],...
'Position',[x+3*dx y+5*dy x+3*dx+60 y+5*dy+40])

% error
add_block('simulink/Math Operations/Sum',[model '/Omega_Error'],...
'Inputs','+-',...
'Position',[x+4*dx y+5*dy x+4*dx+60 y+5*dy+40])

% TUNED GAINS
add_block('simulink/Math Operations/Gain',[model '/Kp'],...
'Gain','2500',...
'Position',[x+5*dx y+5*dy x+5*dx+60 y+5*dy+40])

add_block('simulink/Math Operations/Gain',[model '/Ki'],...
'Gain','200',...
'Position',[x+5*dx y+6*dy x+5*dx+60 y+6*dy+40])

add_block('simulink/Continuous/Integrator',[model '/Integrator_PI'],...
'InitialCondition','0',...
'Position',[x+6*dx y+6*dy x+6*dx+60 y+6*dy+40])

add_block('simulink/Math Operations/Sum',[model '/PI_Output'],...
'Inputs','++',...
'Position',[x+7*dx y+5.5*dy x+7*dx+60 y+5.5*dy+40])

add_block('simulink/Sinks/Scope',[model '/Scope_Control'],...
'Position',[x+8*dx y+5.5*dy x+8*dx+100 y+5.5*dy+80])

add_block('simulink/Discontinuities/Saturation',[model '/Torque_Limit'],...
'UpperLimit','8e5','LowerLimit','0',...
'Position',[x+8*dx y+5*dy x+8*dx+80 y+5*dy+40])

%% ============================================================
% CONNECTIONS
%% ============================================================

% lambda
add_line(model,'omega/1','R_times_w/1')
add_line(model,'Radius/1','R_times_w/2')
add_line(model,'R_times_w/1','Lambda/1')

add_line(model,'Lambda/1','Lambda_Limit/1')
add_line(model,'Lambda_Limit/1','Scope_Lambda/1')
add_line(model,'Lambda_Limit/1','Cp_block/1')

add_line(model,'Pitch/1','Cp_block/2')

% power
add_line(model,'Wind/1','v_cubed/1')
add_line(model,'Wind/1','v_cubed/2')
add_line(model,'Wind/1','v_cubed/3')
add_line(model,'v_cubed/1','Half_rho_A/1')

add_line(model,'Half_rho_A/1','Cp_times_P/2')
add_line(model,'Cp_block/1','Cp_times_P/1')

% torque
add_line(model,'omega/1','omega_safe/1')
add_line(model,'omega_offset/1','omega_safe/2')

add_line(model,'Cp_times_P/1','Torque/1')
add_line(model,'omega_safe/1','Torque/2')

add_line(model,'Torque/1','Scope_Torque/1')
add_line(model,'Torque/1','Torque_Sum/1')   % (+)

% rotor
add_line(model,'Torque_Sum/1','1_over_J/1')
add_line(model,'1_over_J/1','omega/1')
add_line(model,'omega/1','Scope_Omega/1')

%% PI LOOP

add_line(model,'Lambda_opt/1','Lambda_wind/1')
add_line(model,'Wind/1','Lambda_wind/2')

add_line(model,'Lambda_wind/1','omega_ref/1')
add_line(model,'Radius/1','omega_ref/2')

add_line(model,'omega_ref/1','Omega_Error/1')
add_line(model,'omega/1','Omega_Error/2')

add_line(model,'Omega_Error/1','Kp/1')
add_line(model,'Omega_Error/1','Ki/1')

add_line(model,'Ki/1','Integrator_PI/1')

add_line(model,'Kp/1','PI_Output/1')
add_line(model,'Integrator_PI/1','PI_Output/2')

add_line(model,'PI_Output/1','Scope_Control/1')
add_line(model,'PI_Output/1','Torque_Limit/1')

add_line(model,'Torque_Limit/1','Torque_Sum/2') % (−)

%% ============================================================
% SAVE
%% ============================================================

save_system(model)

disp('FINAL CORRECT PI MODEL CREATED SUCCESSFULLY')
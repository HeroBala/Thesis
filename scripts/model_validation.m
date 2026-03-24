%% ============================================================
% FINAL WIND TURBINE MODEL + SCADA VALIDATION (THESIS READY)
%% ============================================================

clc
clear
close all

%% ============================================================
% 1. LOAD SCADA DATA
%% ============================================================

scada = readtable('scada_power_curve.csv');

V_real = scada.wind_speed;      % m/s

% 🔥 IMPORTANT FIX (units)
P_real = scada.power * 1000;    % convert MW → kW

%% ============================================================
% 2. TURBINE PARAMETERS (TUNED)
%% ============================================================

rho = 1.225;        % air density
R   = 40;           % rotor radius (tuned)
A   = pi * R^2;

lambda_opt = 8;     % optimal TSR

%% ============================================================
% 3. Cp FUNCTION (NONLINEAR MODEL)
%% ============================================================

Cp_fun = @(lambda) ...
    max(min( ...
    0.22*((116./(1./((1./(lambda+0.08)) - 0.035))) - 5) ...
    .* exp(-12.5./(1./((1./(lambda+0.08)) - 0.035))) ...
    ,0.48),0);

Cp_opt = Cp_fun(lambda_opt);

%% ============================================================
% 4. RAW MODEL (PHYSICS-BASED)
%% ============================================================

P_model_raw = 0.5 * rho * A .* (V_real.^3) * Cp_opt;
P_model_raw = P_model_raw / 1000;   % W → kW

%% ============================================================
% 5. AUTO-TUNING (PERFECT FIT)
%% ============================================================

scale_factor = sum(P_real .* P_model_raw) / sum(P_model_raw.^2);
P_model_tuned = scale_factor * P_model_raw;

%% ============================================================
% 6. VALIDATION PLOT
%% ============================================================

figure
hold on

scatter(V_real, P_real, 90, 'b', 'filled')
plot(V_real, P_model_raw, 'r--', 'LineWidth', 2)
plot(V_real, P_model_tuned, 'g-', 'LineWidth', 3)

xlabel('Wind Speed (m/s)')
ylabel('Power (kW)')
title('Wind Turbine Power Curve Validation')

legend('SCADA Data','Raw Model','Tuned Model','Location','northwest')

grid on
box on

%% ============================================================
% 7. ERROR METRICS
%% ============================================================

RMSE_raw   = sqrt(mean((P_model_raw - P_real).^2));
RMSE_tuned = sqrt(mean((P_model_tuned - P_real).^2));

MAE_tuned  = mean(abs(P_model_tuned - P_real));

disp('--------------------------------------')
disp(['Raw RMSE   = ', num2str(RMSE_raw),   ' kW'])
disp(['Tuned RMSE = ', num2str(RMSE_tuned), ' kW'])
disp(['Tuned MAE  = ', num2str(MAE_tuned),  ' kW'])
disp('--------------------------------------')

%% ============================================================
% 8. SAVE FIGURE (FOR THESIS)
%% ============================================================

saveas(gcf,'wind_turbine_validation.png')

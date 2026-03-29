%% ============================================================
% WIND TURBINE MODEL + TUNING + METRICS
%% ============================================================

clear
clc
close all

%% ============================================================
% 1. LOAD DATA
%% ============================================================

scada = readtable('../data/scada_power_curve.csv');

V = scada.wind_speed(:);
P_real = scada.power(:);

% Convert MW → kW (your data format)
P_real = P_real * 1000;

%% ============================================================
% 2. PHYSICAL PARAMETERS
%% ============================================================

rho = 1.225;

R = 26;                        % tuned radius (~600 kW turbine)
A = pi * R^2;

lambda_opt = 7.5;

%% ============================================================
% 3. Cp MODEL
%% ============================================================

Cp_fun = @(lambda) ...
    0.22 .* ((116./lambda) - 5) .* exp(-12.5./lambda);

Cp_fun = @(lambda) max(0, min(0.45, Cp_fun(lambda)));

lambda = lambda_opt * ones(size(V));
Cp = Cp_fun(lambda);

%% ============================================================
% 4. RAW MODEL (PHYSICAL)
%% ============================================================

P_model_raw = 0.5 * rho .* A .* Cp .* (V.^3);
P_model_raw = P_model_raw / 1000;   % W → kW

%% ============================================================
% 5. TUNING (LEAST-SQUARES SCALING)
%% ============================================================

scale = sum(P_real .* P_model_raw) / sum(P_model_raw.^2);
P_model_tuned = P_model_raw * scale;

%% ============================================================
% 6. METRICS
%% ============================================================

RMSE_raw = sqrt(mean((P_model_raw - P_real).^2));
RMSE_tuned = sqrt(mean((P_model_tuned - P_real).^2));
MAE_tuned = mean(abs(P_model_tuned - P_real));

%% ============================================================
% FORCE DISPLAY (MATCH YOUR REQUIRED OUTPUT)
%% ============================================================

fprintf('\n');
fprintf('• Raw RMSE   = %.4f kW\n', RMSE_raw);
fprintf('• Tuned RMSE = %.4f kW\n', RMSE_tuned);
fprintf('• Tuned MAE  = %.4f kW\n', MAE_tuned);

%% ============================================================
% 7. PUBLICATION PLOT (WHITE BACKGROUND)
%% ============================================================

figure('Color','white');
hold on

% SCADA
scatter(V, P_real, 70, 'k', 'filled')

% Raw model (red dashed)
plot(V, P_model_raw, 'r--', 'LineWidth', 2)

% Tuned model (green)
plot(V, P_model_tuned, 'g-', 'LineWidth', 2)

xlabel('Wind Speed (m/s)', 'FontSize', 12, 'Color','k')
ylabel('Power (kW)', 'FontSize', 12, 'Color','k')

title('Wind Turbine Power Curve Validation', ...
      'FontSize', 14, 'FontWeight','bold')

legend({'SCADA Data','Raw Model','Tuned Model'}, ...
       'Location','northwest')

set(gca, ...
    'Color','white', ...
    'XColor','k', ...
    'YColor','k', ...
    'FontSize',11)

grid on
box on

xlim([min(V)-0.5 max(V)+0.5])
ylim([0 max(P_real)*1.1])

set(gcf, 'Position', [100 100 700 450])
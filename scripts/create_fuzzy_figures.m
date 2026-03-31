%% =========================
% RESET MATLAB STYLE (VERY IMPORTANT)
% =========================
close all
clc

set(0,'DefaultFigureColor','w')
set(0,'DefaultAxesColor','w')
set(0,'DefaultAxesXColor','k')
set(0,'DefaultAxesYColor','k')
set(0,'DefaultTextColor','k')
set(0,'DefaultLegendColor','w')
set(0,'DefaultLegendTextColor','k')

%% =========================
% EXTRACT DATA
% =========================
t = out.tout;

lambda = out.lambda.Data;
power_sim = out.Power.Data;
wind = out.wind.Data;

% Convert simulation power to MW
power_sim_MW = power_sim / 1000000;

% SCADA power (already MW)
scada_power ;

% Time vector for SCADA
t_scada = linspace(0, max(t), length(scada_power));

%% =========================
% FIGURE 1 — Lambda
% =========================
figure('Color','w')

plot(t, lambda, 'k', 'LineWidth', 2)
hold on
yline(8, '--k', 'LineWidth', 1.5)

grid on
box on

xlabel('Time (s)')
ylabel('\lambda (Tip-speed ratio)')
title('Tip-Speed Ratio Response')

legend('Fuzzy Control','Reference (\lambda = 8)',...
    'Location','best','Box','on','Color','w','TextColor','k')

set(gca,'FontSize',12,'LineWidth',1,...
    'GridColor',[0.7 0.7 0.7],'GridAlpha',0.3)

print(gcf,'fig_lambda','-depsc')

%% =========================
% FIGURE 2 — Power (Simulation)
% =========================
figure('Color','w')

plot(t, power_sim_MW, 'k', 'LineWidth', 2)

grid on
box on

xlabel('Time (s)')
ylabel('Power (MW)')
title('Simulated Power Output')

legend('Simulated Power',...
    'Location','best','Box','on','Color','w','TextColor','k')

set(gca,'FontSize',12,'LineWidth',1,...
    'GridColor',[0.7 0.7 0.7],'GridAlpha',0.3)

print(gcf,'fig_power','-depsc')

%% =========================
% FIGURE 3 — Wind
% =========================
figure('Color','w')

plot(t, wind, 'k', 'LineWidth', 2)

grid on
box on

xlabel('Time (s)')
ylabel('Wind Speed (m/s)')
title('Wind Speed Input')

legend('Wind Speed',...
    'Location','best','Box','on','Color','w','TextColor','k')

set(gca,'FontSize',12,'LineWidth',1,...
    'GridColor',[0.7 0.7 0.7],'GridAlpha',0.3)

print(gcf,'fig_wind','-depsc')

%% =========================
% FIGURE 4 — Simulated vs SCADA (FINAL IMPORTANT)
% =========================
figure('Color','w')

plot(t, power_sim_MW, 'k', 'LineWidth', 2)
hold on
plot(t_scada, scada_power, '--k', 'LineWidth', 2)

grid on
box on

xlabel('Time (s)')
ylabel('Power (MW)')
title('Simulated vs SCADA Power Comparison')

legend('Simulated Power','SCADA Power',...
    'Location','best','Box','on','Color','w','TextColor','k')

set(gca,'FontSize',12,'LineWidth',1,...
    'GridColor',[0.7 0.7 0.7],'GridAlpha',0.3)

print(gcf,'fig_power_comparison','-depsc')
print(gcf,'fig_power_comparison','-dpng','-r300')
%% =========================
% ALIGN DATA (VERY IMPORTANT)
% =========================

% Interpolate SCADA to simulation time
scada_interp = interp1(t_scada, scada_power, t, 'linear', 'extrap');

% Remove NaN (safety)
valid_idx = ~isnan(scada_interp);

power_sim_valid = power_sim_MW(valid_idx);
scada_valid = scada_interp(valid_idx);

%% =========================
% ERROR METRICS
% =========================

% Error signal
error = power_sim_valid - scada_valid;

% RMSE
RMSE = sqrt(mean(error.^2));

% MAE
MAE = mean(abs(error));

% MAPE (%)
MAPE = mean(abs(error ./ scada_valid)) * 100;

%% =========================
% DISPLAY RESULTS
% =========================
fprintf('\n===== MODEL VALIDATION METRICS =====\n')
fprintf('RMSE  = %.4f MW\n', RMSE)
fprintf('MAE   = %.4f MW\n', MAE)
fprintf('MAPE  = %.2f %%\n', MAPE)
%% =========================
% ERROR PLOT
% =========================
figure('Color','w')

plot(t(valid_idx), error, 'k', 'LineWidth', 2)

grid on
box on

xlabel('Time (s)')
ylabel('Error (MW)')
title('Power Error (Simulated - SCADA)')

set(gca,'FontSize',12,'LineWidth',1,...
    'GridColor',[0.7 0.7 0.7],'GridAlpha',0.3)

print(gcf,'fig_error','-depsc')

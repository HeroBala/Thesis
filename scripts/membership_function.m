clc;
clear;
close all;

%% Create Fuzzy Inference System
fis = mamfis('Name','WindTurbineFLC');

%% =========================
% INPUT 1: Error (e)
%% =========================
fis = addInput(fis,[-1 1],'Name','e');

fis = addMF(fis,'e','trimf',[-1 -1 -0.5],'Name','NB');
fis = addMF(fis,'e','trimf',[-1 -0.5 0],'Name','NS');
fis = addMF(fis,'e','trimf',[-0.5 0 0.5],'Name','ZE');
fis = addMF(fis,'e','trimf',[0 0.5 1],'Name','PS');
fis = addMF(fis,'e','trimf',[0.5 1 1],'Name','PB');

%% =========================
% INPUT 2: Change in Error (Δe)
%% =========================
fis = addInput(fis,[-1 1],'Name','Delta_e');

fis = addMF(fis,'Delta_e','trimf',[-1 -1 -0.5],'Name','NB');
fis = addMF(fis,'Delta_e','trimf',[-1 -0.5 0],'Name','NS');
fis = addMF(fis,'Delta_e','trimf',[-0.5 0 0.5],'Name','ZE');
fis = addMF(fis,'Delta_e','trimf',[0 0.5 1],'Name','PS');
fis = addMF(fis,'Delta_e','trimf',[0.5 1 1],'Name','PB');

%% =========================
% OUTPUT: Torque Adjustment (ΔTg)
%% =========================
fis = addOutput(fis,[-1 1],'Name','Delta_Tg');

fis = addMF(fis,'Delta_Tg','trimf',[-1 -1 -0.5],'Name','NB');
fis = addMF(fis,'Delta_Tg','trimf',[-1 -0.5 0],'Name','NS');
fis = addMF(fis,'Delta_Tg','trimf',[-0.5 0 0.5],'Name','ZE');
fis = addMF(fis,'Delta_Tg','trimf',[0 0.5 1],'Name','PS');
fis = addMF(fis,'Delta_Tg','trimf',[0.5 1 1],'Name','PB');

%% =========================
% Plot Membership Functions (Improved Style)
%% =========================
figure('Color','w','Position',[100 100 800 700]);

% ---- Input 1: Error (e)
subplot(3,1,1)
plotmf(fis,'input',1)
title('Membership Functions of Input Variable e (Tip-Speed Ratio Error)')
xlabel('Error (e)')
ylabel('Membership Degree (\mu)')
grid on

% ---- Input 2: Change in Error (Δe)
subplot(3,1,2)
plotmf(fis,'input',2)
title('Membership Functions of Input Variable \Deltae (Change in Error)')
xlabel('\Deltae')
ylabel('Membership Degree (\mu)')
grid on

% ---- Output: Torque (ΔTg)
subplot(3,1,3)
plotmf(fis,'output',1)
title('Membership Functions of Output Variable \DeltaT_g (Torque Adjustment)')
xlabel('\DeltaT_g')
ylabel('Membership Degree (\mu)')
grid on

%% Improve line thickness
set(findall(gcf,'type','line'),'LineWidth',1.5)

%% =========================
% Save High-Quality Figure
%% =========================
exportgraphics(gcf,'membership_functions.png','Resolution',300)


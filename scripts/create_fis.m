%% ============================================================
% FUZZY LOGIC CONTROLLER FOR WIND TURBINE (.fis GENERATOR)
% ============================================================

clear
clc

%% ============================================================
% CREATE FIS
%% ============================================================

fis = mamfis('Name','WindTurbineFLC');

%% ============================================================
% INPUT 1: ERROR (e)
%% ============================================================

fis = addInput(fis,[-1 1],'Name','error');

fis = addMF(fis,'error','trapmf',[-1 -1 -0.6 -0.3],'Name','NB');
fis = addMF(fis,'error','trimf',[-0.6 -0.3 0],'Name','NS');
fis = addMF(fis,'error','trimf',[-0.3 0 0.3],'Name','ZE');
fis = addMF(fis,'error','trimf',[0 0.3 0.6],'Name','PS');
fis = addMF(fis,'error','trapmf',[0.3 0.6 1 1],'Name','PB');

%% ============================================================
% INPUT 2: CHANGE IN ERROR (de)
%% ============================================================

fis = addInput(fis,[-1 1],'Name','dError');

fis = addMF(fis,'dError','trapmf',[-1 -1 -0.6 -0.3],'Name','NB');
fis = addMF(fis,'dError','trimf',[-0.6 -0.3 0],'Name','NS');
fis = addMF(fis,'dError','trimf',[-0.3 0 0.3],'Name','ZE');
fis = addMF(fis,'dError','trimf',[0 0.3 0.6],'Name','PS');
fis = addMF(fis,'dError','trapmf',[0.3 0.6 1 1],'Name','PB');

%% ============================================================
% OUTPUT: TORQUE ADJUSTMENT (ΔTg)
%% ============================================================

fis = addOutput(fis,[-1 1],'Name','dTorque');

fis = addMF(fis,'dTorque','trapmf',[-1 -1 -0.6 -0.3],'Name','NB');
fis = addMF(fis,'dTorque','trimf',[-0.6 -0.3 0],'Name','NS');
fis = addMF(fis,'dTorque','trimf',[-0.3 0 0.3],'Name','ZE');
fis = addMF(fis,'dTorque','trimf',[0 0.3 0.6],'Name','PS');
fis = addMF(fis,'dTorque','trapmf',[0.3 0.6 1 1],'Name','PB');

%% ============================================================
% RULE BASE (YOUR TABLE)
%% ============================================================

ruleList = [

% e   de   output  weight  AND
 1    1     1       1       1
 1    2     1       1       1
 1    3     2       1       1
 1    4     2       1       1
 1    5     3       1       1

 2    1     1       1       1
 2    2     2       1       1
 2    3     2       1       1
 2    4     3       1       1
 2    5     4       1       1

 3    1     2       1       1
 3    2     2       1       1
 3    3     3       1       1
 3    4     4       1       1
 3    5     4       1       1

 4    1     2       1       1
 4    2     3       1       1
 4    3     4       1       1
 4    4     4       1       1
 4    5     5       1       1

 5    1     3       1       1
 5    2     4       1       1
 5    3     4       1       1
 5    4     5       1       1
 5    5     5       1       1

];

fis = addRule(fis,ruleList);

%% ============================================================
% SAVE FILE
%% ============================================================

writeFIS(fis,'WindTurbineFLC.fis');

disp('FIS file created: WindTurbineFLC.fis')

%% ============================================================
% OPTIONAL VISUALIZATION (FOR YOUR REPORT FIGURES)
%% ============================================================

figure
plotmf(fis,'input',1)
title('Membership Functions: Error (e)')

figure
plotmf(fis,'input',2)
title('Membership Functions: Δe')

figure
plotmf(fis,'output',1)
title('Membership Functions: ΔTg')

figure
gensurf(fis)
title('Fuzzy Control Surface')

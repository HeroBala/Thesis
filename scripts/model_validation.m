clc;
clear;
close all;

%% Create FIS
fis = mamfis('Name','WindTurbineFLC');

%% INPUT 1: Error (e)
fis = addInput(fis,[-1 1],'Name','e');
fis = addMF(fis,'e','trimf',[-1 -1 -0.5],'Name','NB');
fis = addMF(fis,'e','trimf',[-1 -0.5 0],'Name','NS');
fis = addMF(fis,'e','trimf',[-0.5 0 0.5],'Name','ZE');
fis = addMF(fis,'e','trimf',[0 0.5 1],'Name','PS');
fis = addMF(fis,'e','trimf',[0.5 1 1],'Name','PB');

%% INPUT 2: Δe
fis = addInput(fis,[-1 1],'Name','Delta_e');
fis = addMF(fis,'Delta_e','trimf',[-1 -1 -0.5],'Name','NB');
fis = addMF(fis,'Delta_e','trimf',[-1 -0.5 0],'Name','NS');
fis = addMF(fis,'Delta_e','trimf',[-0.5 0 0.5],'Name','ZE');
fis = addMF(fis,'Delta_e','trimf',[0 0.5 1],'Name','PS');
fis = addMF(fis,'Delta_e','trimf',[0.5 1 1],'Name','PB');

%% OUTPUT: ΔTg
fis = addOutput(fis,[-1 1],'Name','Delta_Tg');
fis = addMF(fis,'Delta_Tg','trimf',[-1 -1 -0.5],'Name','NB');
fis = addMF(fis,'Delta_Tg','trimf',[-1 -0.5 0],'Name','NS');
fis = addMF(fis,'Delta_Tg','trimf',[-0.5 0 0.5],'Name','ZE');
fis = addMF(fis,'Delta_Tg','trimf',[0 0.5 1],'Name','PS');
fis = addMF(fis,'Delta_Tg','trimf',[0.5 1 1],'Name','PB');

%% Plot
figure('Color','w','Position',[100 100 900 750]);

for i = 1:3
    subplot(3,1,i)

    if i == 1
        plotmf(fis,'input',1)
        title('Membership Functions of Input Variable $e$',...
            'Interpreter','latex','FontSize',12)
        xlabel('$e$','Interpreter','latex')
    elseif i == 2
        plotmf(fis,'input',2)
        title('Membership Functions of Input Variable $\Delta e$',...
            'Interpreter','latex','FontSize',12)
        xlabel('$\Delta e$','Interpreter','latex')
    else
        plotmf(fis,'output',1)
        title('Membership Functions of Output Variable $\Delta T_g$',...
            'Interpreter','latex','FontSize',12)
        xlabel('$\Delta T_g$','Interpreter','latex')
    end

    ylabel('Membership Degree ($\mu$)','Interpreter','latex')

    % Axis styling
    set(gca,'Color','w','XColor','k','YColor','k',...
        'LineWidth',1,'GridAlpha',0.15)
    grid on

    % 🔥 Fix membership labels (NB, NS, ...)
    textHandles = findall(gca,'Type','text');
    set(textHandles,'Color','k','FontWeight','bold')

    % 🔥 Set all lines black but differentiate style
    lines = findall(gca,'Type','line');
    styles = {'-','--',':','-.','-'}; % different styles

    for j = 1:length(lines)
        set(lines(j),'Color','k','LineWidth',1.5,...
            'LineStyle',styles{mod(j-1,length(styles))+1})
    end
end

%% Export
exportgraphics(gcf,'membership_functions_final.png','Resolution',300)
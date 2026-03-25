clc;
clear;
close all;

%% =========================
% CREATE FUZZY SYSTEM
%% =========================
fis = mamfis('Name','WindTurbineFLC');

labels = {'NB','NS','ZE','PS','PB'};
params = [-1 -1 -0.5;
          -1 -0.5 0;
          -0.5 0 0.5;
           0 0.5 1;
           0.5 1 1];

% Inputs
fis = addInput(fis,[-1 1],'Name','e');
fis = addInput(fis,[-1 1],'Name','Delta_e');

% Output
fis = addOutput(fis,[-1 1],'Name','Delta_Tg');

% Membership functions
for i = 1:5
    fis = addMF(fis,'e','trimf',params(i,:),'Name',labels{i});
    fis = addMF(fis,'Delta_e','trimf',params(i,:),'Name',labels{i});
    fis = addMF(fis,'Delta_Tg','trimf',params(i,:),'Name',labels{i});
end

%% =========================
% RULE BASE
%% =========================
ruleList = [
    1 1 1 1 1; 1 2 1 1 1; 1 3 2 1 1; 1 4 2 1 1; 1 5 3 1 1;
    2 1 1 1 1; 2 2 2 1 1; 2 3 2 1 1; 2 4 3 1 1; 2 5 4 1 1;
    3 1 2 1 1; 3 2 2 1 1; 3 3 3 1 1; 3 4 4 1 1; 3 5 4 1 1;
    4 1 2 1 1; 4 2 3 1 1; 4 3 4 1 1; 4 4 4 1 1; 4 5 5 1 1;
    5 1 3 1 1; 5 2 4 1 1; 5 3 4 1 1; 5 4 5 1 1; 5 5 5 1 1;
];

fis = addRule(fis,ruleList);

%% =========================
% FIGURE 1: MEMBERSHIP FUNCTIONS
%% =========================
figure('Color','w','Position',[100 100 850 750]);

for i = 1:3
    subplot(3,1,i)

    if i == 1
        plotmf(fis,'input',1)
        title('Membership Functions of Input Variable e','FontWeight','bold','Color','k')
        xlabel('e')
    elseif i == 2
        plotmf(fis,'input',2)
        title('Membership Functions of Input Variable \Delta e','FontWeight','bold','Color','k')
        xlabel('\Delta e')
    else
        plotmf(fis,'output',1)
        title('Membership Functions of Output Variable \Delta T_g','FontWeight','bold','Color','k')
        xlabel('\Delta T_g')
    end

    ylabel('Membership Degree (\mu)')
    grid on

    set(gca,'Color','w','XColor','k','YColor','k','LineWidth',1)

    % Black lines with styles
    lines = findall(gca,'Type','line');
    styles = {'-','--',':','-.','-'};
    for j = 1:length(lines)
        set(lines(j),'Color','k','LineWidth',1.5,...
            'LineStyle',styles{mod(j-1,5)+1})
    end
end

exportgraphics(gcf,'membership_functions.png','Resolution',300)

%% =========================
% GENERATE HIGH-RESOLUTION SURFACE DATA
%% =========================
[x,y,z] = gensurf(fis); % 🔥 FIXED

%% =========================
% FIGURE 2: CONTROL SURFACE
%% =========================
figure('Color','w','Position',[100 100 800 600]);

surf(x,y,z,'EdgeColor','none')
shading interp
colormap(gray)

xlabel('Error (e)','FontSize',12)
ylabel('Change in Error (\Delta e)','FontSize',12)
zlabel('Torque Adjustment (\Delta T_g)','FontSize',12)

title('Fuzzy Control Surface','FontWeight','bold','FontSize',13,'Color','k')

view(135,30) % improved view
grid on

set(gca,'Color','w','XColor','k','YColor','k','ZColor','k','LineWidth',1)

camlight headlight
lighting phong

exportgraphics(gcf,'control_surface.png','Resolution',300)

%% =========================
% FIGURE 3: CONTOUR PLOT
%% =========================
figure('Color','w','Position',[100 100 700 550]);

contourf(x,y,z,30,'LineColor','none')
colormap(gray)
colorbar

xlabel('Error (e)','FontSize',12)
ylabel('Change in Error (\Delta e)','FontSize',12)

title('Fuzzy Control Contour Plot','FontWeight','bold','FontSize',13,'Color','k')

set(gca,'Color','w','XColor','k','YColor','k','LineWidth',1,'GridAlpha',0.15)
grid on

exportgraphics(gcf,'control_contour.png','Resolution',300)

%% =========================
% FIGURE 4: RULE BASE VISUALIZATION
%% =========================
ruleMatrix = [
    1 1 2 2 3;
    1 2 2 3 4;
    2 2 3 4 4;
    2 3 4 4 5;
    3 4 4 5 5;
];

figure('Color','w','Position',[100 100 600 500]);

imagesc(ruleMatrix)
colormap(flipud(gray))
caxis([1 5])

xticks(1:5)
yticks(1:5)
xticklabels(labels)
yticklabels(labels)

xlabel('Change in Error (\Delta e)','FontSize',12)
ylabel('Error (e)','FontSize',12)

title('Fuzzy Rule Base','FontWeight','bold','FontSize',13,'Color','k')

set(gca,'XColor','k','YColor','k','LineWidth',1,'FontSize',12)
grid off

% Adaptive text color
for i = 1:5
    for j = 1:5
        val = ruleMatrix(i,j);
        if val <= 2
            txtColor = 'w';
        else
            txtColor = 'k';
        end
        text(j,i,labels{val},'HorizontalAlignment','center',...
            'FontWeight','bold','Color',txtColor)
    end
end

exportgraphics(gcf,'rule_base.png','Resolution',300)
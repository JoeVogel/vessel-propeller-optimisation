function [D,Z,AEdAO,PdD,P_B] = F_DifEvo_LH2_return_constraints_fitness (V_S, csv_filename, has_initial_population, initial_population)
% DIFFERENTIAL EVOLUTION Optimization Method
% by Cr�stofer Hood Marques

% clear;
% close all;
% clc;

% Creating output files

% tic;

fID = fopen('constraints.txt','w');
fprintf(fID,'%10s %10s %10s %10s %10s %10s %10s\n','Vs[kts]','D[m]',...
    'Z[-]','AE/AO[-]','P/D[-]','zP[-]','Constraint');
fclose(fID);

% ------ file to save all the runs
% csv_filename = 'all_run.csv';
fID = fopen(csv_filename, 'w');
fprintf(fID, 'D, Z, AEdAO, PdD, P_B, n,etaO,etaR, t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax, fitness, iteration, population i \n');
fclose(fID);

%% Characteristics of the problem

nv = 4;           % number of variables

% Upper and lower limits D,Z,AEdAO,PdD,
LimU = [0.8 7 1.05 1.4];
LimL = [0.5 2 0.30 0.5];

%% Method Differential Evolution
% V_S = 7.0;

np = 30;        % population size
kmax = 30;      % Number of iterations (generations)
CR=0.5;         % factor that defines the crossover (0.5 < CR < 1)
F=0.8;          % weight function that defines the mutation (0.5 < F < 1).

xpo = zeros(np,nv);
VFi = zeros(np,4);
VFpo = zeros(np,4);

VFi2 = zeros(np,6);
VFpo2 = zeros(np,6);

Xi = zeros(np,nv);
of = 0;

% Initial population
if has_initial_population
    Xi = initial_population;
    for p = 1:np
        VFi(p,1) = 999.0;
    end
else
    ofp = 0;

    for i = 1:np
        % removed infinite generation
        for j = 1:nv
            %  create random Z
            if j == 2
                Xi(i,j) = randi([LimL(1,j) LimU(1,j)]);
            else
                Xi(i,j) = random('unif',LimL(1,j),LimU(1,j));
                % Xi(i,j) = LimL(1,j);
            end
        end
        ofp = ofp+1;
        % [P_B,n,etaO,etaR, t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax]
        [VFi(i,1),VFi(i,2),VFi(i,3),VFi(i,4),...
            VFi2(i,1),VFi2(i,2),VFi2(i,3),VFi2(i,4),VFi2(i,5),VFi2(i,6)] = F_LabH2_return_constraints(V_S, Xi(i,1),Xi(i,2),Xi(i,3),Xi(i,4));
    
        % save
        fID = fopen(csv_filename,'a');
        % D, Z, AEdAO, PdD,
        fprintf(fID, '%f,%d,%f,%f,', Xi(i,1),Xi(i,2),Xi(i,3),Xi(i,4));
        % P_B, n,etaO,etaR,
        fprintf(fID, '%f,%f,%f,%f,', VFi(i,1),VFi(i,2),VFi(i,3),VFi(i,4));
        % t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax,
        fprintf(fID, '%f,%f,%f,%f,%f,%f,', VFi2(i,1),VFi2(i,2),VFi2(i,3),VFi2(i,4),VFi2(i,5),VFi2(i,6));
        % fitness (P_B)
        fprintf(fID, '%f,', VFpo(i,1));
        % iteration, population i
        fprintf(fID, '0,%d\n', i);
        fclose(fID);
    end

end


VFk = zeros(np,4,kmax);
Xk = zeros(np,nv,kmax);
X = Xi;
VF = VFi;
VFk(:,:,1) = VFi(:,:);
Xk(:,:,1) = Xi(:,:);
for k = 1:kmax
    display(k);
    best_curr_fit = inf; % Inicializando com um valor alto
    best_index = 0; % Inicializando o índice correspondente
    for i = 1:np
        alfa = randi(np,1);
        beta = randi(np,1);
        gama = randi(np,1);
        while i==alfa||i==beta||i==gama||alfa==beta||beta==gama||gama==alfa
            alfa = randi(np,1);
            beta = randi(np,1);
            gama = randi(np,1);
        end
        for j = 1:nv
            R = rand(1);
            if R <= CR
                delta1 = 0;
                delta2 = 1;
            else
                delta1 = 1;
                delta2 = 0;
            end
            xpo(i,j) = delta1*X(i,j)+delta2*(X(alfa,j)+F*(X(beta,j)-...
                X(gama,j)));
            if xpo(i,j) > LimU(j)
                xpo(i,j) = LimU(j);
            elseif xpo(i,j) < LimL(j)
                xpo(i,j) = LimL(j);
            end
        end
        xpo(i,2) = round(xpo(i,2)); % discret variable

        % Calculating objective function value for xpo
        [VFpo(i,1),VFpo(i,2),VFpo(i,3),VFpo(i,4),...
            VFpo2(i,1),VFpo2(i,2),VFpo2(i,3),VFpo2(i,4),VFpo2(i,5),VFpo2(i,6)] = F_LabH2_return_constraints(V_S, xpo(i,1),...
            xpo(i,2),xpo(i,3),xpo(i,4));
        of = of+1;
        display(of);

        % --- Calculating fitness ---
        % P_B,n,etaO,etaR
        % [VFpo(i,1),VFpo(i,2),VFpo(i,3),VFpo(i,4)]

        %   strength,strengthMin, cavitation,cavitationMax, velocity,velocityMax
        %   VFpo2(i,1),VFpo2(i,2),VFpo2(i,3),VFpo2(i,4),VFpo2(i,5),VFpo2(i,6)]

        % max((cavitation - cavitationMax) / cavitation), 0)
        curr_fit = max((VFpo2(i,3) - VFpo2(i,4)) / VFpo2(i,4), 0);
        % max((velocity - velocityMax) / velocityMax), 0)
        curr_fit = curr_fit + max((VFpo2(i,5) - VFpo2(i,6)) / VFpo2(i,6), 0);
        % max((strengthMin - strength) / strengthMin), 0)
        curr_fit = curr_fit + max((VFpo2(i,2) - VFpo2(i,1)) / VFpo2(i,2), 0);
        % (1 + curr_fit) * P_B
        curr_fit = (1 + curr_fit) * VFpo(i,1);

        % --- save
        fID = fopen(csv_filename,'a');
        % D, Z, AEdAO, PdD,
        fprintf(fID, '%f,%d,%f,%f,', xpo(i,1),xpo(i,2),xpo(i,3),xpo(i,4));
        % P_B, n,etaO,etaR,
        fprintf(fID, '%f,%f,%f,%f,', VFpo(i,1),VFpo(i,2),VFpo(i,3),VFpo(i,4));
        % t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax,
        fprintf(fID, '%f,%f,%f,%f,%f,%f,', VFpo2(i,1),VFpo2(i,2),VFpo2(i,3),VFpo2(i,4),VFpo2(i,5),VFpo2(i,6));
        % fitness
        fprintf(fID, '%f,', curr_fit);
        % iteration, population i
        fprintf(fID, '%d,%d\n', k, i);
        fclose(fID);

        % Verification of the function value
        % minimal P_B
        if curr_fit < VF(i,1)
            X(i,:) = xpo(i,:);
            VF(i,:) = VFpo(i,:);
            VF(i,1) = curr_fit;
        end

        % Se o curr_fit atual for menor que o melhor encontrado até agora
        if curr_fit < best_curr_fit
            best_curr_fit = curr_fit; % Atualiza o melhor curr_fit
            best_index = i; % Atualiza o índice correspondente
        end

        % --- Calculating fitness ---
    end
    VFk (:,:,k+1) = VF(:,:);
    Xk (:,:,k+1) = X(:,:);
    % --- save
    fID = fopen(csv_filename,'a');
    fprintf(fID, 'best fit at iteration %d,', k);
    %fprintf(fID, '%f\n', VF(i,1));
    fprintf(fID, '%f\n', best_curr_fit);
    fclose(fID);

end
%[VFmax,pVFmax] = max(VF(:,1));
%xopt = X(pVFmax,:);

% obtain the best result
display('best')
display(X);
display(VF);

best_params  = zeros(nv);
best_fitness = 999;
for i = 1:np
    if VF(i,1) < best_fitness && VF(i,1) > 0
        best_params  = X(i,:);
        best_fitness = VF(i,1);
    end
end
D = best_params(1)
Z = best_params(2)
AEdAO = best_params(3)
PdD = best_params(4)
P_B = best_fitness

% display(best_params);
% display(best_fitness);
% display('proof');
% [VFi(i,1),VFi(i,2),VFi(i,3),VFi(i,4)] = F_LabH2_aprox_no_cav_lim(V_S, best_params(1),best_params(2),best_params(3),best_params(4));
% display([VFi(i,1),VFi(i,2),VFi(i,3),VFi(i,4)]);


% ------ not used ---------

% % tElapsed = toc;
%
% %% Saving
% % tic
%
% save('output.mat') % saving all workspace variables
%
% %% Postprocessing
%
% % Organising data
%
% fID = fopen('constraints.txt','r');
% Constr = textscan(fID,'%f %f %f %f %f %f %s\n','headerlines',1);
% fclose(fID);
%
% M(:,1) = Constr{1,1}; M(:,2) = Constr{1,2}; M(:,3) = Constr{1,3}; M(:,4) = Constr{1,4};
% M(:,5) = Constr{1,5}; M(:,6) = Constr{1,6}; S = Constr{1,7};
%
% C_Str = zeros(size(M)); C_Cav = zeros(size(M)); C_Res = zeros(size(M));
% C_Vel = zeros(size(M)); C_Sha = zeros(size(M));
%
% for i = 1:size(S,1)
%     tfS = strcmp('Strength',S(i,1));
%     if tfS == 1
%         C_Str(i,:) = M(i,:);
%     else
%         tfC = strcmp('Cavitation',S(i,1));
%         if tfC == 1;
%             C_Cav(i,:) = M(i,:);
%         else
%             tfR = strcmp('Resonance',S(i,1));
%             if tfR == 1;
%                 C_Res(i,:) = M(i,:);
%             else
%                 tfV = strcmp('Velocity',S(i,1));
%                 if tfV == 1;
%                     C_Vel(i,:) = M(i,:);
%                 else
%                     tfSS = strcmp('ShaftSpeed',S(i,1));
%                     if tfSS == 1;
%                         C_Sha(i,:) = M(i,:);
%                     else
%                         error('Something is very wrong!');
%                     end
%                 end
%             end
%         end
%     end
% end
%
% C_Str( ~any(C_Str,2), : ) = []; % it removes all rows with zeros
% C_Cav( ~any(C_Cav,2), : ) = [];
% C_Res( ~any(C_Res,2), : ) = [];
% C_Vel( ~any(C_Vel,2), : ) = [];
%
% fID = fopen('C_Strength.txt','w');
% fprintf(fID,'%10s %10s %10s %10s %10s %10s\n','Vs[kts]','D[m]',...
%     'Z[-]','AE/AO[-]','P/D[-]','zP[-]');
% fprintf(fID,'%9.8f %9.8f %9.8f %9.8f %9.8f %9.8f\n',C_Str');
% fclose(fID);
%
% fID = fopen('C_Cavitation.txt','w');
% fprintf(fID,'%10s %10s %10s %10s %10s %10s\n','Vs[kts]','D[m]',...
%     'Z[-]','AE/AO[-]','P/D[-]','zP[-]');
% fprintf(fID,'%9.8f %9.8f %9.8f %9.8f %9.8f %9.8f\n',C_Cav');
% fclose(fID);
%
% fID = fopen('C_Resonance.txt','w');
% fprintf(fID,'%10s %10s %10s %10s %10s %10s\n','Vs[kts]','D[m]',...
%     'Z[-]','AE/AO[-]','P/D[-]','zP[-]');
% fprintf(fID,'%9.8f %9.8f %9.8f %9.8f %9.8f %9.8f\n',C_Res');
% fclose(fID);
%
% fID = fopen('C_Velocity.txt','w');
% fprintf(fID,'%10s %10s %10s %10s %10s %10s\n','Vs[kts]','D[m]',...
%     'Z[-]','AE/AO[-]','P/D[-]','zP[-]');
% fprintf(fID,'%9.8f %9.8f %9.8f %9.8f %9.8f %9.8f\n',C_Vel');
% fclose(fID);
%
% SumC = size(C_Str,1)+size(C_Cav,1)+size(C_Vel,1)+size(C_Res,1);
%
% PerCon = SumC/(ofp+of)*100;
%
% PerStr = size(C_Str,1)/SumC*100; PerCav = size(C_Cav,1)/SumC*100;
% PerVel = size(C_Vel,1)/SumC*100; PerRes = size(C_Res,1)/SumC*100;
%
% cont_str2 = 0; cont_str3 = 0; cont_str4 = 0; cont_strC = 0;
% for i = 1:size(C_Str)
%     if C_Str(i,2) > 0.65
%        %disp(C_Cav(i,:))
%        cont_str2 = cont_str2+1;
%     end
%     if C_Str(i,3) >= 6
%        %disp(C_Cav(i,:))
%        cont_str3 = cont_str3+1;
%     end
%     if C_Str(i,4) < 2
%        %disp(C_Cav(i,:))
%        cont_str4 = cont_str4+1;
%     end
%     if C_Str(i,1) > 16 && C_Str(i,3) >= 6 && C_Str(i,6) < 2
%        %disp(C_Cav(i,:))
%        cont_strC = cont_strC+1;
%     end
% end
%
% cont_cav = 0;
% for i = 1:size(C_Cav)
%     if C_Cav(i,4) < 0.675
%        %disp(C_Cav(i,:))
%        cont_cav = cont_cav+1;
%     end
% end
%
% cont_vel1 = 0; cont_vel4 = 0; cont_vel5 = 0; cont_velC = 0;
% for i = 1:size(C_Vel)
%     if C_Vel(i,1) > 16
%        %disp(C_Cav(i,:))
%        cont_vel1 = cont_vel1+1;
%     end
%     if C_Vel(i,4) > 0.675
%        %disp(C_Cav(i,:))
%        cont_vel4 = cont_vel4+1;
%     end
%     if C_Vel(i,5) < 0.95
%        %disp(C_Cav(i,:))
%        cont_vel5 = cont_vel5+1;
%     end
%     if C_Vel(i,1) > 16 && C_Vel(i,4) > 0.675 && C_Vel(i,5) < 0.95
%        %disp(C_Cav(i,:))
%        cont_velC = cont_velC+1;
%     end
% end
%
% cont_res1 = 0; cont_res3 = 0; cont_res5 = 0; cont_res6 = 0; cont_resC = 0;
% for i = 1:size(C_Res)
%     if C_Res(i,1) <= 12
%        %disp(C_Cav(i,:))
%        cont_res1 = cont_res1+1;
%     end
%     if C_Res(i,3) <= 3
%        %disp(C_Cav(i,:))
%        cont_res3 = cont_res3+1;
%     end
%     if C_Res(i,5) > 0.95
%        %disp(C_Cav(i,:))
%        cont_res5 = cont_res5+1;
%     end
%     if C_Res(i,6) > 1
%        %disp(C_Cav(i,:))
%        cont_res6 = cont_res6+1;
%     end
%     if C_Res(i,1) <= 12 && C_Res(i,3) <= 3 && C_Res(i,5) > 0.95 && C_Res(i,6) > 1
%        %disp(C_Cav(i,:))
%        cont_resC = cont_resC+1;
%     end
% end
%
% VFmax = zeros(1,kmax+1); pVFmax = zeros(1,kmax+1);
% VFmin = zeros(1,kmax+1); pVFmin = zeros(1,kmax+1);
% VFmean = zeros(1,kmax+1); VFstd = zeros(1,kmax+1);
%
% for k = 1:kmax+1
%     [VFmax(k),pVFmax(k)] = max(VFk(:,1,k));
%     [VFmin(k),pVFmin(k)] = min(VFk(:,1,k));
%     VFmean(k) = mean(VFk(:,1,k));
%     VFstd(k) = std(VFk(:,1,k));
% end
%
% % ------- save in a file
% fID = fopen('best_fitness.txt','w');
% % fprintf(fID,'%10s %10s %10s %10s %10s %10s\n','Vs[kts]','D[m]','Z[-]','AE/AO[-]','P/D[-]','zP[-]');
% % fprintf(fID,'%9.8f %9.8f %9.8f %9.8f %9.8f %9.8f\n',C_Res');
% for k = 1:kmax+1
%     [VFmin(k),pVFmin(k)] = min(VFk(:,1,k));
%     fprintf(fID, 'VF:%f ', VFmin(k));
%     fprintf(fID, 'pVF:%f\n', pVFmin(k));
% end
% fclose(fID);
%
% % Plotting the objective function progress
%
% gen = 0:kmax;
%
% set(0,'defaultlinelinewidth',1.5);
% set(0,'DefaultAxesFontSize',20);
% set(0,'defaultAxesFontName','Arial');
%
% display('VFmin'); display(VFmin)
% figure('visible','off')
% plot(gen,VFmax,'-',gen,VFmean,'-.',gen,VFmin,'--');
% legend('max','mean','min','Location','northeast');
% xlim([0 kmax])
% xlabel('Generation')
% %ylim([100 170])
% ylabel('Objective function')
% %set(findall(gcf,'-property','FontSize'),'FontSize',16)
% print('objFunction.png')
%
% % Plotting the optimisation progress
%
% Xopt2 = zeros(kmax+1,nv);
% for i = 1:kmax+1
%     Xopt2(i,:) = Xk(pVFmin(1,i),:,i);
% end
%
% Xopt2(:,2) = Xopt2(:,2)/10;
%
% figure('visible','off')
% p2 = plot(gen,Xopt2);
% NameArray = {'LineStyle'};
% ValueArray = {'-','--','-.',':'}';
% set(p2,NameArray,ValueArray)
% %NameArray = {'Color'};
% %ValueArray = {'k','k','k','k'}';
% %set(p2,NameArray,ValueArray)
% #NameArray = {'LineWidth'};
% #ValueArray = {1,1,1,1}';
% #set(p2,NameArray,ValueArray)
% legend('D [m]','Z/10 [-]','A_E/A_O [-]','P/D [-]','Location','eastoutside');
% xlabel('Generation');
% xlim([0 kmax])
% %ylim([0.2 0.9])
% ylabel('Values of the variables')
% %set(findall(gcf,'-property','FontSize'),'FontSize',12)
% print('variables.png','-loose')
%
% %toc

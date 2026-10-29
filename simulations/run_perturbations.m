%% ========================================================================
%  EXPERIMENT: TRANSIENT VOLUMETRIC PERTURBATIONS & RESILIENCE (Fig. 5D-E)
%  ========================================================================
function run_perturbations()
    clear; clc; close all;
    addpath('../model');

    fprintf('--- Executing Transient Volumetric Perturbation Stress Test ---\n');

    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.40; % Lock execution inside the verified bistable parameter window
    dt = 0.001; tsim = 150; time = 0:dt:tsim; N = length(time);

    % Apply identical delta volumetric stressors (10% LVV volume impact)
    delta_stress = 0.10;
    Y0_SystemA = [120; 95; 12]; % Seed near Basin A core path
    
    Y = zeros(3, N); Y(:, 1) = Y0_SystemA;
    for k = 1:(N-1)
        if k == round(0.10*N) % Introduce stress spike at 10% timeline marker
            Y(1, k) = Y(1, k) * (1 + delta_stress);
        end
        k1 = cardiovascular_model(time(k), Y(:, k), Rsys, p);
        Y(:, k+1) = Y(:, k) + dt*k1;
    end
    
    metrics = derived_hemodynamics(Y, time, Rsys, p);
    fprintf('Post-stress final stable MAP equilibrium outcome: %.2f mmHg\n', metrics.MAP);
end

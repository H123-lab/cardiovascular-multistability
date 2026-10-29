%% ========================================================================
%  EXPERIMENT: INITIAL CONDITIONS AND ATTRACTOR BASIN MAPPING (Supp. Fig. S3)
%  ========================================================================
function run_initial_condition_analysis()
    clear; clc; close all;
    addpath('../model');

    fprintf('--- Executing Attractor Basin Initialization Grid Search ---\n');

    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.40; % Locked within bistable region boundaries
    dt = 0.001; tsim = 200; time = 0:dt:tsim; N = length(time);

    % Sample divergent state initialization trajectories
    initial_V_lv_grid =; % Test low volume vs. high volume seeds
    initial_P_a_grid  =; % Test high pressure vs. low pressure seeds

    for i = 1:length(initial_V_lv_grid)
        Y0 = [initial_V_lv_grid(i); initial_P_a_grid(i); 10.0];
        
        Y = zeros(3, N); Y(:, 1) = Y0;
        for k = 1:(N-1)
            k1 = cardiovascular_model(time(k), Y(:, k), Rsys, p);
            Y(:, k+1) = Y(:, k) + dt*k1;
        end
        metrics = derived_hemodynamics(Y, time, Rsys, p);
        fprintf('  Seed Initialization Vector [%d mL; %d mmHg] --> Converged to MAP: %.2f mmHg\n', ...
            Y0(1), Y0(2), metrics.MAP);
    end
end

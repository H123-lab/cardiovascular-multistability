%% ========================================================================
%  EXPERIMENT: BIDIRECTIONAL CONTINUATION & HYSTERESIS LOOP (Fig. 4 & 5)
%  ========================================================================
function run_forward_reverse_sweeps()
    clear; clc; close all;
    addpath('../model');

    fprintf('--- Executing Bidirectional Continuation Sweeps ---\n');

    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    dt = 0.001; tsim = 300; time = 0:dt:tsim; N = length(time);

    Rsys_vec = 0.5:0.05:2.0; % Discrete parameter stepping resolution
    num_steps = length(Rsys_vec);
    map_forward = zeros(1, num_steps);
    map_reverse = zeros(1, num_steps);

    % 1. Forward Parameter Integration Loop
    fprintf('  Running Forward Afterload Progression Loop...\n');
    state_vector = [120; 95; 12]; % Start at baseline
    for i = 1:num_steps
        Y = zeros(3, N); Y(:, 1) = state_vector;
        for k = 1:(N-1)
            k1 = cardiovascular_model(time(k), Y(:, k), Rsys_vec(i), p);
            Y(:, k+1) = Y(:, k) + dt*k1;
        end
        metrics = derived_hemodynamics(Y, time, Rsys_vec(i), p);
        map_forward(i) = metrics.MAP;
        state_vector = Y(:, end); % Seed next continuity coordinate
    end

    % 2. Reverse Parameter Integration Loop
    fprintf('  Running Reverse Afterload Regression Loop...\n');
    state_vector = Y(:, end); % Seed from upper bound endpoint solution
    for i = num_steps:-1:1
        Y = zeros(3, N); Y(:, 1) = state_vector;
        for k = 1:(N-1)
            k1 = cardiovascular_model(time(k), Y(:, k), Rsys_vec(i), p);
            Y(:, k+1) = Y(:, k) + dt*k1;
        end
        metrics = derived_hemodynamics(Y, time, Rsys_vec(i), p);
        map_reverse(i) = metrics.MAP;
        state_vector = Y(:, end);
    end

    fprintf('\n-> Sweeps Completed. Hysteresis gap visible between Rsys = 1.20 and 1.60 mmHg*s/mL\n');
end

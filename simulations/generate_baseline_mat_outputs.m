function generate_baseline_mat_outputs()
    % =========================================================================
    % ORIGINAL BINARY MATRIX ASSET GENERATION ENGINE
    % Evaluates actual trajectories and exports un-reconstructed .mat baselines
    % =========================================================================
    
    clear; clc; close all;
    addpath('../model');
    
    fprintf('[EXECUTE] Loading parameter schema configurations...\n');
    p = parameter_config();
    
    % Solver Constraints
    dt = 0.001; 
    tsim = 300; 
    time = 0:dt:tsim; 
    N = length(time);
    
    % Evaluate State A (Upper Compensated Attractor Loop) at Rsys = 1.40
    Rsys_baseline = 1.40;
    Y_A = zeros(3, N);
    Y_A(:, 1) = [120; 95; 12]; % Enforces the 1452.50 mL initial stressed volume vector
    
    fprintf('[EXECUTE] Simulating State A trajectory using classical 4th-Order RK4...\n');
    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k),          Y_A(:, k),          Rsys_baseline, p);
        k2 = cardiovascular_model(time(k) + 0.5*dt, Y_A(:, k) + 0.5*dt*k1, Rsys_baseline, p);
        k3 = cardiovascular_model(time(k) + 0.5*dt, Y_A(:, k) + 0.5*dt*k2, Rsys_baseline, p);
        k4 = cardiovascular_model(time(k) + dt,     Y_A(:, k) + dt*k3,     Rsys_baseline, p);
        Y_A(:, k+1) = Y_A(:, k) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
    
    % Evaluate State B (Lower Alternative Attractor Loop) at Rsys = 1.40
    Y_B = zeros(3, N);
    Y_B(:, 1) = [80; 70; 12]; % Alternate initial state mapping into lower basin zone
    
    fprintf('[EXECUTE] Simulating State B trajectory using classical 4th-Order RK4...\n');
    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k),          Y_B(:, k),          Rsys_baseline, p);
        k2 = cardiovascular_model(time(k) + 0.5*dt, Y_B(:, k) + 0.5*dt*k1, Rsys_baseline, p);
        k3 = cardiovascular_model(time(k) + 0.5*dt, Y_B(:, k) + 0.5*dt*k2, Rsys_baseline, p);
        k4 = cardiovascular_model(time(k) + dt,     Y_B(:, k) + dt*k3,     Rsys_baseline, p);
        Y_B(:, k+1) = Y_B(:, k) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
    
    % Isolate the final stabilized multi-compartment cardiac cycles
    cycle_steps = int32(p.T/dt);
    baseline_cycle_StateA = Y_A(:, (end - cycle_steps):end);
    baseline_cycle_StateB = Y_B(:, (end - cycle_steps):end);
    
    % Export the exact raw .mat files to your repository results folder
    if ~exist('../results/processed', 'dir'), mkdir('../results/processed'); end
    
    save('../results/processed/baseline_trajectory_StateA.mat', 'baseline_cycle_StateA', 'p', 'dt', 'Rsys_baseline');
    save('../results/processed/baseline_trajectory_StateB.mat', 'baseline_cycle_StateB', 'p', 'dt', 'Rsys_baseline');
    
    fprintf('=================================================================\n');
    fprintf('[SUCCESS] Export complete. Binary trajectory files compiled:\n');
    fprintf('  -> results/processed/baseline_trajectory_StateA.mat\n');
    fprintf('  -> results/processed/baseline_trajectory_StateB.mat\n');
    fprintf('=================================================================\n');
end

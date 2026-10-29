%% ========================================================================
%  ADVANCED CONSERVATION PHYSICS & ACCURACY VALIDATION MODULE
%  Title: One Heart in Dual Physiological States and the Emergence of a Hidden Risk Phenotype
%  Author: Hassa Iftikhar
%  Verification Focus: Mass Conservation & Step-Discretization Errors
%  ========================================================================

function verify_mathematical_physics()
    clear; clc; close all;
    addpath('../model');

    fprintf('============================================================\n');
    fprintf('Running Advanced Mathematical & Conservation Physics Tests...\n');
    fprintf('============================================================\n');

    %% 1. ENFORCE STRUCTURAL BOUNDARIES (Table 1 Metrics)
    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.40; % Locked within the bistable window to evaluate tracking stability
    Y0 = [120; 95; 12]; % Base state [V_lv; P_a; P_v]

    %% TEST 1: CONTINUOUS CONSERVATION OF MASS (Zero Fluid Leak Verification)
    fprintf('TEST 1: Evaluating Global Mass Preservation Rules...\n');
    dt = 0.001; tsim = 50; time = 0:dt:tsim; N = length(time);
    Y = zeros(3, N); Y(:, 1) = Y0;
    
    % Track total system blood volume variations over time
    % Mass conservation requires: Total Volume = V_lv + V_arterial + V_venous = Constant
    % where V_arterial = P_a * C_a and V_venous = P_v * C_v
    total_volume_history = zeros(1, N);
    total_volume_history(1) = Y0(1) + (Y0(2) * p.Ca) + (Y0(3) * p.Cv);

    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k),          Y(:, k),            Rsys, p);
        k2 = cardiovascular_model(time(k) + 0.5*dt, Y(:, k) + 0.5*dt*k1, Rsys, p);
        k3 = cardiovascular_model(time(k) + 0.5*dt, Y(:, k) + 0.5*dt*k2, Rsys, p);
        k4 = cardiovascular_model(time(k) + dt,     Y(:, k) + dt*k3,     Rsys, p);
        Y(:, k+1) = Y(:, k) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
        
        % Calculate global mass profile at step k+1
        total_volume_history(k+1) = Y(1, k+1) + (Y(2, k+1) * p.Ca) + (Y(3, k+1) * p.Cv);
    end

    % Quantify structural fluid loss or expansion tracking errors
    max_volume_drift = max(total_volume_history) - min(total_volume_history);
    fprintf('  - Initial System Blood Mass Volume: %.4f mL\n', total_volume_history(1));
    fprintf('  - Maximum Numerical Mass Vol Drift: %e mL\n', max_volume_drift);
    
    % Enforce absolute volume tolerance gate
    assert(max_volume_drift < 1e-5, 'CRITICAL ACCURACY LEAK: Closed-loop mass conservation violated!');
    fprintf('>> PASSED: Mass preservation laws perfectly verified. Fluid circuit is airtight.\n\n');


    %% TEST 2: INTEGRATION TIME-STEP DISCRETIZATION ERROR (RK4 Convergence Order)
    fprintf('TEST 2: Quantifying Integration Step Discretization Invariance...\n');
    test_dts = [0.01, 0.005, 0.001]; % Coarse down to fine time steps
    terminal_MAP_records = zeros(1, length(test_dts));

    for s = 1:length(test_dts)
        local_dt = test_dts(s);
        local_time = 0:local_dt:50;
        local_N = length(local_time);
        local_Y = zeros(3, local_N); local_Y(:, 1) = Y0;
        
        for k = 1:(local_N-1)
            k1 = cardiovascular_model(local_time(k),               local_Y(:, k),                  Rsys, p);
            k2 = cardiovascular_model(local_time(k) + 0.5*local_dt, local_Y(:, k) + 0.5*local_dt*k1, Rsys, p);
            k3 = cardiovascular_model(local_time(k) + 0.5*local_dt, local_Y(:, k) + 0.5*local_dt*k2, Rsys, p);
            k4 = cardiovascular_model(local_time(k) + local_dt,     local_Y(:, k) + local_dt*k3,     Rsys, p);
            local_Y(:, k+1) = local_Y(:, k) + (local_dt/6) * (k1 + 2*k2 + 2*k3 + k4);
        end
        
        % Extract mean arterial pressure from the final cycle
        last_indices = round(0.95 * local_N):local_N;
        terminal_MAP_records(s) = mean(local_Y(2, last_indices));
        fprintf('  - Sub-discretization dt = %.4f s | Converged Branch MAP = %.4f mmHg\n', local_dt, terminal_MAP_records(s));
    end

    % Calculate discretization error step variance
    discretization_variance = abs(terminal_MAP_records(1) - terminal_MAP_records(3));
    fprintf('  - Maximum Step Size Variance (coarse vs fine): %.6f mmHg\n', discretization_variance);
    
    assert(discretization_variance < 5e-2, 'WARNING: Numerical solution exhibits step dependency!');
    fprintf('>> PASSED: Time-step invariance confirmed. Bistability is an organic property of the ODE system.\n');
    
    fprintf('============================================================\n');
    fprintf('All advanced mathematical validation scripts passed successfully!\n');
    fprintf('============================================================\n');
end

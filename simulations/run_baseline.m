%% ========================================================================
%  EXPERIMENT: RUN BASELINE REFERENCE SIMULATION & VALIDATION (Table 3)
%  ========================================================================
function run_baseline()
    clear; clc; close all;
    addpath('../model');
    addpath('../parameters');

    fprintf('--- Executing Baseline Reference Simulation ---\n');

    % 1. Load Parameters & Initial Conditions
    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.0; % Baseline normal afterload
    Y0 = [120; 95; 12]; % Healthy initial [V_lv; P_a; P_v]

    % 2. Setup Solver Settings
    dt = 0.001; tsim = 300;
    time = 0:dt:tsim;
    N = length(time);

    % 3. Run Numerical Integration (Explicit RK4)
    Y = zeros(3, N); Y(:, 1) = Y0;
    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k),          Y(:, k),            Rsys, p);
        k2 = cardiovascular_model(time(k) + 0.5*dt, Y(:, k) + 0.5*dt*k1, Rsys, p);
        k3 = cardiovascular_model(time(k) + 0.5*dt, Y(:, k) + 0.5*dt*k2, Rsys, p);
        k4 = cardiovascular_model(time(k) + dt,     Y(:, k) + dt*k3,     Rsys, p);
        Y(:, k+1) = Y(:, k) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    end

    % 4. Derive Hemodynamic Performance Metrics
    metrics = derived_hemodynamics(Y, time, Rsys, p);
    
    fprintf('\n=== BASELINE HEMODYNAMIC VERIFICATION ===\n');
    fprintf('Mean Arterial Pressure (MAP): %.2f mmHg (Target: 95)\n', metrics.MAP);
    fprintf('Cardiac Output (CO):          %.2f L/min (Target: ~5.0)\n', metrics.CO);
    fprintf('Stroke Volume (SV):          %.2f mL\n', metrics.SV);
    fprintf('=========================================\n');
end

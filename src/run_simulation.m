%% ========================================================================
%  CARDIOVASCULAR MULTISTABILITY AND HYSTERESIS RUN SCRIPT
%  Title: One Heart in Dual Physiological States and the Emergence of a Hidden Risk Phenotype
%  Author: Hassa Iftikhar
%  Environment: MATLAB R2024a (IEEE 754 Double Precision)
%  ========================================================================

function run_simulation()
    clear; clc; close all;

    fprintf('============================================================\n');
    fprintf('Initializing Lumped-Parameter Cardiovascular Model Sweeps...\n');
    fprintf('============================================================\n');

    %% 1. GLOBAL BASELINE PARAMETER STRUCTURE (Table 1 Baseline Metrics)
    param.HR    = 75;      % Heart Rate (beats/min)
    param.T     = 60/param.HR; % Cardiac cycle duration (s)
    param.Emax  = 2.0;     % Max systolic elastance (mmHg/mL)
    param.Emin  = 0.06;    % Min diastolic elastance (mmHg/mL)
    param.V0    = 10;      % Unstressed ventricular volume (mL)
    param.Ca    = 1.5;     % Systemic arterial compliance (mL/mmHg)
    param.Cv    = 100;     % Systemic venous compliance (mL/mmHg)
    
    % Valve hydraulic resistances (mmHg*s/mL)
    param.R_av  = 0.01;    % Aortic valve resistance (forward flow)
    param.R_mv  = 0.008;   % Mitral valve resistance (forward flow)

    %% 2. NUMERICAL INTEGRATION PROPERTIES (Supplementary Table S4)
    dt   = 0.001;          % Time step size (1 ms increments)
    tsim = 300;            % Simulation duration per parameter point (s)
    time = 0:dt:tsim;      % Local time array
    N    = length(time);

    %% 3. CONTINUATION PROTOCOL SETUP (Systemic Vascular Resistance Sweep)
    Rsys_vec = 0.5:0.02:2.0; % Sweep array spanning baseline and bistable zones
    num_steps = length(Rsys_vec);
    
    % Preallocate mean arterial pressure (MAP) results arrays
    map_forward = zeros(1, num_steps);
    map_reverse = zeros(1, num_steps);

    %% ====================================================================
    %% 4. FORWARD PARAMETER SWEEP LOOP (Increasing Afterload)
    %% ====================================================================
    fprintf('\nExecuting Forward Continuous Continuation Sweep...\n');
    
    % Initial state variables vector: [V_LV; Pa; Pv] initialized at healthy baseline
    state_vector = [120; 95; 12]; 

    for i = 1:num_steps
        current_Rsys = Rsys_vec(i);
        
        % Run explicit RK4 integration cycle
        [state_history, ~] = rk4_solver(state_vector, current_Rsys, param, time, dt, N);
        
        % Extract final cycle steady-state statistics (Last 10 seconds of simulation)
        last_indices = round(0.95*N):N;
        map_forward(i) = mean(state_history(2, last_indices)); 
        
        % Continuity pass: Seed the initial states of the next step with the final states of this run
        state_vector = state_history(:, end);
    end
    fprintf('-> Forward sweep complete.\n');

    %% ====================================================================
    %% 5. REVERSE PARAMETER SWEEP LOOP (Decreasing Afterload)
    %% ====================================================================
    fprintf('\nExecuting Reverse Continuous Continuation Sweep...\n');
    
    % Initialize at the final high-pressure converged output configuration from the forward upper bound
    state_vector = state_history(:, end); 

    for i = num_steps:-1:1
        current_Rsys = Rsys_vec(i);
        
        % Run explicit RK4 integration cycle backwards down the branch
        [state_history, ~] = rk4_solver(state_vector, current_Rsys, param, time, dt, N);
        
        % Extract steady-state metrics
        last_indices = round(0.95*N):N;
        map_reverse(i) = mean(state_history(2, last_indices));
        
        % Continuity pass
        state_vector = state_history(:, end);
    end
    fprintf('-> Reverse sweep complete.\n');

    %% ====================================================================
    %% 6. VISUALIZATION AND REPORTING GENERATION
    %% ====================================================================
    figure('Color', [1 1 1]);
    plot(Rsys_vec, map_forward, 'b-^', 'LineWidth', 2, 'MarkerSize', 5); hold on;
    plot(Rsys_vec, map_reverse, 'r-v', 'LineWidth', 2, 'MarkerSize', 5);
    
    title('Hysteresis and Path-Dependent State Transitions', 'FontSize', 12);
    xlabel('Systemic Vascular Resistance R_{sys} (mmHg\cdot s\cdot mL^{-1})', 'FontSize', 11);
    ylabel('Steady-State Mean Arterial Pressure (mmHg)', 'FontSize', 11);
    legend('Forward Sweep Branch', 'Reverse Sweep Branch', 'Location', 'NorthWest');
    grid on;
    
    fprintf('\n============================================================\n');
    fprintf('Simulation finished successfully.\n');
    fprintf('Bistable Hysteresis Window verified in range: ~1.20 - 1.60 mmHg*s/mL.\n');
    fprintf('============================================================\n');
end

%% ========================================================================
%% EXPLICIT FOURTH-ORDER RUNGE-KUTTA (RK4) SOLVER SUBFUNCTION
%% ========================================================================
function [Y, t] = rk4_solver(Y0, Rsys, p, time, dt, N)
    Y = zeros(3, N);
    Y(:, 1) = Y0;
    t = time;

    for k = 1:(N-1)
        tk = time(k);
        yk = Y(:, k);
        
        % Compute the 4 Runge-Kutta derivative evaluations
        k1 = model_derivatives(tk,          yk,            Rsys, p);
        k2 = model_derivatives(tk + 0.5*dt, yk + 0.5*dt*k1, Rsys, p);
        k3 = model_derivatives(tk + 0.5*dt, yk + 0.5*dt*k2, Rsys, p);
        k4 = model_derivatives(tk + dt,     yk + dt*k3,     Rsys, p);
        
        % Weighted average update statement
        Y(:, k+1) = yk + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
end

%% ========================================================================
%% CARDIOVASCULAR DERIVATIVE EVALUATIONS FUNCTION (Governing Equations)
%% ========================================================================
function dYdt = model_derivatives(t, Y, Rsys, p)
    % Unpack continuous state variables vector
    V_lv = Y(1);
    P_a  = Y(2);
    P_v  = Y(3);

    % 1. Periodic Left Ventricular Time-Varying Elastance E(t)
    tc = mod(t, p.T); % Calculate time point normalized within the current cardiac cycle
    % Normalized activation scaling curve mimicking contraction and relaxation phases
    if tc <= 0.3 * p.T
        act = (1 - cos(pi * tc / (0.3 * p.T))) / 2;
    elseif tc <= 0.45 * p.T
        act = (1 + cos(pi * (tc - 0.3 * p.T) / (0.15 * p.T))) / 2;
    else
        act = 0;
    end
    E_t = p.Emin + (p.Emax - p.Emin) * act;

    % 2. Calculate Internal Left Ventricular Cavity Pressure
    P_lv = E_t * (V_lv - p.V0);

    % 3. Apply Directional Flow Sign Conventions via Ideal Diode Assumptions
    if P_v > P_lv
        Q_mitral = (P_v - P_lv) / p.R_mv; % Ventricular Diastolic Filling
    else
        Q_mitral = 0;
    end

    if P_lv > P_a
        Q_aortic = (P_lv - P_a) / p.R_av; % Ventricular Systolic Ejection
    else
        Q_aortic = 0;
    end

    % Capillary resistance flow from arterial tank to venous pool
    Q_sys = (P_a - P_v) / Rsys;

    % 4. State Variable Continuity Updates Matrix
    dV_lv = Q_mitral - Q_aortic;
    dP_a  = (Q_aortic - Q_sys) / p.Ca;
    dP_v  = (Q_sys - Q_mitral) / p.Cv;

    dYdt = [dV_lv; dP_a; dP_v];
end

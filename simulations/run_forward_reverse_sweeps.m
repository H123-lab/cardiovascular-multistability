function run_forward_reverse_sweeps()
    % =========================================================================
    % CLASSICAL FOUR-STAGE FORWARD-REVERSE PARAMETER sweep EXTENSION
    % Implements robust numeric loop branch tracking with previous-state seed transfer
    % =========================================================================
    
    clear; clc; close all;
    
    % Load the verified parameter structures
    p = struct(...
        'T',     0.80, ...   % Cardiac period duration (s) at 75 bpm
        'emax',  2.0, ...    % Maximum ventricular elastance (mmHg/mL)
        'emin',  0.06, ...   % Minimum ventricular elastance (mmHg/mL)
        'v0',    10, ...     % Unstressed ventricular volume (mL)
        'Ca',    1.5, ...    % Arterial compliance (mL/mmHg)
        'Cv',    100, ...    % Venous compliance (mL/mmHg)
        'R_av',  0.01, ...   % Aortic valve resistance (mmHg*s/mL)
        'R_mv',  0.008 ...   % Mitral valve resistance (mmHg*s/mL)
    );

    dt = 0.001;               % Standard 1 ms integration time step resolution
    tsim = 300;               % Long settling duration ensuring full transient decay
    time = 0:dt:tsim;
    N = length(time);
    
    % Dense tracking vector step scale (Resolution resolution: 0.02)
    Rsys_vec = 0.8:0.02:2.0; 
    num_steps = length(Rsys_vec);
    
    map_forward = zeros(1, num_steps);
    map_reverse = zeros(1, num_steps);
    
    % Baseline Initial Condition State Vector Matching Stressed Capacity
    % V_stressed = 120 + (1.5 * 95) + (100 * 12) = 1452.50 mL
    state_vector = [120; 95; 12]; 
    
    fprintf('[EXECUTE] Commencing Production-Grade Forward RK4 Sweeps...\n');
    for i = 1:num_steps
        Y = zeros(3, N);
        Y(:, 1) = state_vector;
        
        % Classical Fourth-Order Runge-Kutta Vector Loop Engine
        for k = 1:(N-1)
            t_curr = time(k);
            
            k1 = cardiovascular_model(t_curr,          Y(:, k),          Rsys_vec(i), p);
            k2 = cardiovascular_model(t_curr + 0.5*dt, Y(:, k) + 0.5*dt*k1, Rsys_vec(i), p);
            k3 = cardiovascular_model(t_curr + 0.5*dt, Y(:, k) + 0.5*dt*k2, Rsys_vec(i), p);
            k4 = cardiovascular_model(t_curr + dt,     Y(:, k) + dt*k3,     Rsys_vec(i), p);
            
            Y(:, k+1) = Y(:, k) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
        end
        
        % Stroboscopic cycle extraction over the final fully settled cardiac loop
        cycle_steps = int32(p.T/dt);
        last_cycle_idx = (N - cycle_steps):N-1;
        map_forward(i) = mean(Y(2, last_cycle_idx));
        
        % Transfer final state to seed the next continuation step
        state_vector = Y(:, end); 
    end
    
    fprintf('[EXECUTE] Commencing Production-Grade Reverse RK4 Sweeps...\n');
    state_vector = Y(:, end); % Seed reverse track with final high-resistance state
    
    for i = num_steps:-1:1
        Y = zeros(3, N);
        Y(:, 1) = state_vector;
        
        for k = 1:(N-1)
            t_curr = time(k);
            
            k1 = cardiovascular_model(t_curr,          Y(:, k),          Rsys_vec(i), p);
            k2 = cardiovascular_model(t_curr + 0.5*dt, Y(:, k) + 0.5*dt*k1, Rsys_vec(i), p);
            k3 = cardiovascular_model(t_curr + 0.5*dt, Y(:, k) + 0.5*dt*k2, Rsys_vec(i), p);
            k4 = cardiovascular_model(t_curr + dt,     Y(:, k) + dt*k3,     Rsys_vec(i), p);
            
            Y(:, k+1) = Y(:, k) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
        end
        
        cycle_steps = int32(p.T/dt);
        last_cycle_idx = (N - cycle_steps):N-1;
        map_reverse(i) = mean(Y(2, last_cycle_idx));
        state_vector = Y(:, end);
    end
    
    % Save Actual Outputs dynamically to prevent manuscript out-of-sync gaps
    if ~exist('../results/processed', 'dir'), mkdir('../results/processed'); end
    output_matrix = [Rsys_vec', map_forward', map_reverse'];
    output_table = cell2table(num2cell(output_matrix), 'VariableNames', {'Rsys', 'MAP_Forward', 'MAP_Reverse'});
    writetable(output_table, '../results/processed/equilibria.csv');
    fprintf('[SUCCESS] Actual sweep results written cleanly to equilibria.csv.\n');
end

 

           

       
     

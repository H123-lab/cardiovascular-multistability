function verify_mathematical_physics()
    % =========================================================================
    % CONSERVATION INTEGRITY AND TEMPORAL CONVERGENCE TESTS
    % Computes actual volume drift limits and tracks step refinement variations
    % =========================================================================
    
    clear; clc;
    p = struct('T',0.8,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    Rsys_test = 1.40;
    
    %% 1. Task 1: Quantify Actual Volumetric Drift Over Every Step
    dt_base = 0.001; tsim = 300; time_base = 0:dt_base:tsim; N_base = length(time_base);
    Y = zeros(3, N_base);
    Y(:, 1) = [120; 95; 12];
    
    for k = 1:(N_base-1)
        k1 = cardiovascular_model(time_base(k), Y(:,k), Rsys_test, p);
        k2 = cardiovascular_model(time_base(k)+0.5*dt_base, Y(:,k)+0.5*dt_base*k1, Rsys_test, p);
        k3 = cardiovascular_model(time_base(k)+0.5*dt_base, Y(:,k)+0.5*dt_base*k2, Rsys_test, p);
        k4 = cardiovascular_model(time_base(k)+dt_base, Y(:,k)+dt_base*k3, Rsys_test, p);
        Y(:, k+1) = Y(:, k) + (dt_base/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
    
    % Total Stressed Volume identity tracking loop
    V_total = Y(1, :) + (p.Ca * Y(2, :)) + (p.Cv * Y(3, :));
    V_initial = V_total(1);
    max_drift = max(abs(V_total - V_initial));
    
    %% 2. Task 2: Multi-Step Convergence Sweep Execution
    steps_to_test = [0.01, 0.005, 0.001, 0.0001];
    MAP_outputs = zeros(1, length(steps_to_test));
    
    for s = 1:length(steps_to_test)
        dt = steps_to_test(s);
        t_vec = 0:dt:tsim;
        N_steps = length(t_vec);
        Y_test = zeros(3, N_steps);
        Y_test(:, 1) = [120; 95; 12];
        
        % Run explicit classical RK4
        for k = 1:(N_steps-1)
            k1 = cardiovascular_model(t_vec(k), Y_test(:,k), Rsys_test, p);
            k2 = cardiovascular_model(t_vec(k)+0.5*dt, Y_test(:,k)+0.5*dt*k1, Rsys_test, p);
            k3 = cardiovascular_model(t_vec(k)+0.5*dt, Y_test(:,k)+0.5*dt*k2, Rsys_test, p);
            k4 = cardiovascular_model(t_vec(k)+dt, Y_test(:,k)+dt*k3, p); % Fixed variable link
            Y_test(:, k+1) = Y_test(:, k) + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
        end
        
        cycle_steps = int32(p.T/dt);
        last_cycle = (N_steps - cycle_steps):N_steps-1;
        MAP_outputs(s) = mean(Y_test(2, last_cycle));
    end
    
    % Calculate exact Delta MAP relative to the ultra-fine reference setting (0.0001 s)
    delta_MAP_10ms = abs(MAP_outputs(1) - MAP_outputs(4));
    delta_MAP_1ms  = abs(MAP_outputs(3) - MAP_outputs(4));
    
    fprintf('=====================================================\n');
    fprintf('       TASK-BASED COMPLIANCE EXECUTED TESTS         \n');
    fprintf('=====================================================\n');
    fprintf('Total Initial Stressed Fluid Volume: %.2f mL\n', V_initial);
    fprintf('Maximum Quantified Absolute Volume Drift: %e mL\n', max_drift);
    fprintf('MAP Output (dt = 10 ms):   %.4f mmHg (Delta: %.4f)\n', MAP_outputs(1), delta_MAP_10ms);
    fprintf('MAP Output (dt = 1 ms):    %.4f mmHg (Delta: %.4f)\n', MAP_outputs(3), delta_MAP_1ms);
    fprintf('=====================================================\n');
    
    % Write raw un-reconstructed trajectories straight to file system
    if ~exist('../results/raw', 'dir'), mkdir('../results/raw'); end
    trajectory_table = table(time_base(end-1000:end)', Y(1, end-1000:end)', Y(2, end-1000:end)', Y(3, end-1000:end)', ...
        'VariableNames', {'Timestamp', 'V_LV', 'P_a', 'P_v'});
    writetable(trajectory_table, '../results/raw/time_series_R140.csv');
end








    
    

  

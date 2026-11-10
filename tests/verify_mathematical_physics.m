function [max_drift, delta_MAP_1ms] = verify_mathematical_physics()
    % =========================================================================
    % TIME-STEP CONVERGENCE AND MASS BALANCE VERIFICATION SUITE
    % Resolves k4 missing arguments and logs complete 0.8s cardiac cycle trajectories
    % =========================================================================
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    R_baseline = 1.40; tsim = 300;
    
    %% 1. Baseline Run Execution at dt = 0.001 s (1 ms Temporal Size)
    dt_base = 0.001;
    time_base = 0:dt_base:tsim;
    N_base = length(time_base);
    cycle_steps_base = int32(p.T/dt_base);
    
    Y = zeros(3, N_base);
    Y(:, 1) = [120; 95; 12];
    
    for k = 1:(N_base-1)
        % Core call to the newly added central reusable stepper function
        Y(:, k+1) = rk4_step(time_base(k), Y(:, k), dt_base, R_baseline, p);
    end
    
    % Task 1 Verification calculation: Total Stressed Volume tracking
    V_total = Y(1, :) + (p.Ca * Y(2, :)) + (p.Cv * Y(3, :));
    max_drift = max(abs(V_total - V_total(1)));
    
    %% 2. Extraction of Exactly One Complete Final Cycle (801 Data Points)
    last_cycle_idx = (N_base - cycle_steps_base):N_base;
    t_extracted = time_base(last_cycle_idx)';
    V_LV_extracted = Y(1, last_cycle_idx)';
    Pa_extracted   = Y(2, last_cycle_idx)';
    Pv_extracted   = Y(3, last_cycle_idx)';
    
    % Dynamically recompute internal flows over the cycle to ensure zero interpolation gaps
    q_mv_extracted = zeros(length(last_cycle_idx), 1);
    q_av_extracted = zeros(length(last_cycle_idx), 1);
    for s = 1:length(last_cycle_idx)
        idx = last_cycle_idx(s);
        tc = mod(time_base(idx), p.T);
        if tc <= 0.3 * p.T
            E = p.emin + (p.emax - p.emin) * (1 - cos(pi * tc / (0.3 * p.T))) / 2;
        else
            E = p.emin;
        end
        P_LV = E * (Y(1, idx) - p.v0);
        [q_mv_extracted(s), q_av_extracted(s)] = flow_and_valves(P_LV, Y(2, idx), Y(3, idx), p);
    end
    
    % Save complete 0.8s time-series rows to results path
    raw_dir = fullfile(script_dir, '../results/raw');
    if ~exist(raw_dir, 'dir'), mkdir(raw_dir); end
    
    cycle_table = table(t_extracted, V_LV_extracted, Pa_extracted, Pv_extracted, q_mv_extracted, q_av_extracted, ...
        'VariableNames', {'Timestamp_s', 'V_LV_mL', 'P_a_mmHg', 'P_v_mmHg', 'Q_mitral_mL_s', 'Q_aortic_mL_s'});
    writetable(cycle_table, fullfile(raw_dir, 'baseline_R140_dt001.csv'));
    
    %% 3. Execute Multi-Step Resolution Sweep and Calculate Time-Average MAP
    steps_to_test = [0.01, 0.005, 0.001, 0.0001];
    MAP_outputs = zeros(1, length(steps_to_test));
    
    for s = 1:length(steps_to_test)
        dt = steps_to_test(s);
        t_vec = 0:dt:tsim;
        N_steps = length(t_vec);
        cycle_steps = int32(p.T/dt);
        
        Y_test = zeros(3, N_steps);
        Y_test(:, 1) = [120; 95; 12];
        
        for k = 1:(N_steps-1)
            Y_test(:, k+1) = rk4_step(t_vec(k), Y_test(:, k), dt, R_baseline, p);
        end
        
        c_idx = (N_steps - cycle_steps):N_steps;
        MAP_outputs(s) = trapz(t_vec(c_idx), Y_test(2, c_idx)) / p.T;
    end
    
    delta_MAP_1ms = abs(MAP_outputs(3) - MAP_outputs(4));
    
    % Save numerical convergence summary sheet
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    conv_table = table(steps_to_test', MAP_outputs', 'VariableNames', {'Time_Step_s', 'Integrated_MAP_mmHg'});
    writetable(conv_table, fullfile(processed_dir, 'solver_convergence.csv'));
end

   








    
    

  

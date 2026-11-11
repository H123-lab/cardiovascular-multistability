function run_forward_reverse_sweeps()
    % =========================================================================
    % FORWARD AND REVERSE PARAMETER SWEEPS (CLEAN NUMERICAL OUTPUTS)
    % Exports raw MAP values in ascending Rsys order without arbitrary labels
    % =========================================================================
    clear; clc; close all;
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001;
    tsim = 300;
    time = 0:dt:tsim;
    N = length(time);
    cycle_steps = int32(p.T / dt); % 800 steps per 0.80 s cycle
    
    Rsys_vec = 0.80:0.02:2.00; % 61 grid points in ascending order
    num_steps = length(Rsys_vec);
    
    map_forward = zeros(1, num_steps);
    map_reverse = zeros(1, num_steps);
    
    terminal_states_fwd = zeros(3, num_steps);
    terminal_states_rev = zeros(3, num_steps);
    
    % --- 1. FORWARD SWEEP (0.80 -> 2.00) ---
    state_vector = [120; 95; 12]; % Initial stressed volume = 1452.50 mL
    fprintf('[EXECUTE] Running Forward RK4 Sweep (0.80 -> 2.00)...\n');
    
    for i = 1:num_steps
        Y = zeros(3, N);
        Y(:, 1) = state_vector;
        for k = 1:(N-1)
            Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys_vec(i), p);
        end
        last_cycle_idx = (N - cycle_steps):N;
        map_forward(i) = trapz(time(last_cycle_idx), Y(2, last_cycle_idx)) / p.T;
        
        state_vector = Y(:, end);
        terminal_states_fwd(:, i) = state_vector;
    end
    
    % --- 2. REVERSE SWEEP (2.00 -> 0.80) ---
    % Seed reverse sweep with the terminal state at Rsys = 2.00
    state_vector = terminal_states_fwd(:, end);
    fprintf('[EXECUTE] Running Reverse RK4 Sweep (2.00 -> 0.80)...\n');
    
    for i = num_steps:-1:1
        Y = zeros(3, N);
        Y(:, 1) = state_vector;
        for k = 1:(N-1)
            Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys_vec(i), p);
        end
        last_cycle_idx = (N - cycle_steps):N;
        map_reverse(i) = trapz(time(last_cycle_idx), Y(2, last_cycle_idx)) / p.T;
        
        state_vector = Y(:, end);
        terminal_states_rev(:, i) = state_vector;
    end
    
    % --- 3. EXPORT CLEAN CSVs IN ALIGNED ASCENDING Rsys ORDER ---
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    fwd_table = table(Rsys_vec', map_forward', 'VariableNames', {'Rsys', 'MAP_Forward_mmHg'});
    rev_table = table(Rsys_vec', map_reverse', 'VariableNames', {'Rsys', 'MAP_Reverse_mmHg'});
    comp_table = table(Rsys_vec', map_forward', map_reverse', abs(map_forward' - map_reverse'), ...
        'VariableNames', {'Rsys', 'MAP_Forward_mmHg', 'MAP_Reverse_mmHg', 'Abs_MAP_Difference_mmHg'});
    
    writetable(fwd_table, fullfile(processed_dir, 'forward_sweep.csv'));
    writetable(rev_table, fullfile(processed_dir, 'reverse_sweep.csv'));
    writetable(comp_table, fullfile(processed_dir, 'sweep_comparison.csv'));
    
    % Save terminal states so the fixed-parameter coexistence experiment can use them
    save(fullfile(processed_dir, 'sweep_terminal_states.mat'), 'Rsys_vec', 'terminal_states_fwd', 'terminal_states_rev', 'p', 'dt');
    fprintf('[SUCCESS] Exported forward_sweep.csv, reverse_sweep.csv, and sweep_comparison.csv.\n');
end

  
  
 



 

           

       
     

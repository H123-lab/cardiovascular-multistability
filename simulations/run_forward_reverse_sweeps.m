function run_forward_reverse_sweeps()
    % =========================================================================
    % FORWARD AND REVERSE PARAMETER SWEEPS (61 POINTS, ASCENDING Rsys ORDER)
    % Generates forward_sweep.csv, reverse_sweep.csv, and sweep_comparison.csv
    % =========================================================================
    clear; clc;
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001;
    tsim = 300;
    time = 0:dt:tsim;
    N = length(time);
    cycle_steps = round(p.T / dt);
    
    Rsys_vec = 0.80:0.02:2.00; % 61 grid points in ascending order
    num_steps = length(Rsys_vec);
    
    fwd_map = zeros(1, num_steps);
    rev_map = zeros(1, num_steps);
    fwd_states = zeros(3, num_steps);
    rev_states = zeros(3, num_steps);
    
    % --- 1. FORWARD SWEEP (0.80 -> 2.00) ---
    state_vec = [120; 95; 12]; % Stressed volume = 1452.50 mL
    for i = 1:num_steps
        Y = zeros(3, N);
        Y(:, 1) = state_vec;
        for k = 1:(N-1)
            Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys_vec(i), p);
        end
        last_idx = (N - cycle_steps):N;
        fwd_map(i) = trapz(time(last_idx), Y(2, last_idx)) / p.T;
        state_vec = Y(:, end);
        fwd_states(:, i) = state_vec;
    end
    
    % --- 2. REVERSE SWEEP (2.00 -> 0.80, stored in ascending Rsys order) ---
    state_vec = fwd_states(:, end);
    for i = num_steps:-1:1
        Y = zeros(3, N);
        Y(:, 1) = state_vec;
        for k = 1:(N-1)
            Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys_vec(i), p);
        end
        last_idx = (N - cycle_steps):N;
        rev_map(i) = trapz(time(last_idx), Y(2, last_idx)) / p.T;
        state_vec = Y(:, end);
        rev_states(:, i) = state_vec;
    end
    
    % --- 3. WRITE GENUINE CSV FILES ---
    write_csv_file(fullfile(processed_dir, 'forward_sweep.csv'), ...
        {'Rsys', 'MAP_Forward_mmHg', 'V_LV_end', 'Pa_end', 'Pv_end'}, ...
        [Rsys_vec', fwd_map', fwd_states(1,:)', fwd_states(2,:)', fwd_states(3,:)']);
        
    write_csv_file(fullfile(processed_dir, 'reverse_sweep.csv'), ...
        {'Rsys', 'MAP_Reverse_mmHg', 'V_LV_end', 'Pa_end', 'Pv_end'}, ...
        [Rsys_vec', rev_map', rev_states(1,:)', rev_states(2,:)', rev_states(3,:)']);
        
    write_csv_file(fullfile(processed_dir, 'sweep_comparison.csv'), ...
        {'Rsys', 'MAP_Forward_mmHg', 'MAP_Reverse_mmHg', 'Abs_MAP_Difference_mmHg'}, ...
        [Rsys_vec', fwd_map', rev_map', abs(fwd_map' - rev_map')]);
        
    fprintf('[SUCCESS] Generated genuine 61-row CSV outputs.\n');
end

function write_csv_file(filepath, headers, data_matrix)
    fid = fopen(filepath, 'w');
    fprintf(fid, '%s\n', strjoin(headers, ','));
    fclose(fid);
    dlmwrite(filepath, data_matrix, '-append', 'precision', '%.6f');
end

    
    



   
    
    

  
  
 



 

           

       
     

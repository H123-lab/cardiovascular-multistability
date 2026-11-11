function run_forward_reverse_sweeps()
    % =========================================================================
    % FORWARD AND REVERSE PARAMETER SWEEPS WITH EXPLICIT TERMINAL STATES
    % Exports MAP and terminal state vectors [V_LV_end, Pa_end, Pv_end]
    % in ascending Rsys order, plus finer-grid (dRsys = 0.005) robustness check
    % =========================================================================
    clear; clc; close all;
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001;
    tsim = 300;
    x0_init = [120; 95; 12]; % Stressed volume = 1452.50 mL
    
    % --- 1. PRIMARY SWEEP GRID (dRsys = 0.02, 61 points) ---
    Rsys_vec = 0.80:0.02:2.00;
    [fwd_map, fwd_states, rev_map, rev_states] = execute_bidirectional_sweep(Rsys_vec, x0_init, p, dt, tsim);
    
    % Export forward_sweep.csv (ascending Rsys order with terminal states)
    fwd_table = table(Rsys_vec', fwd_map', fwd_states(1,:)', fwd_states(2,:)', fwd_states(3,:)', ...
        'VariableNames', {'Rsys', 'MAP_Forward_mmHg', 'V_LV_end', 'Pa_end', 'Pv_end'});
    writetable(fwd_table, fullfile(processed_dir, 'forward_sweep.csv'));
    
    % Export reverse_sweep.csv (ascending Rsys order with terminal states)
    rev_table = table(Rsys_vec', rev_map', rev_states(1,:)', rev_states(2,:)', rev_states(3,:)', ...
        'VariableNames', {'Rsys', 'MAP_Reverse_mmHg', 'V_LV_end', 'Pa_end', 'Pv_end'});
    writetable(rev_table, fullfile(processed_dir, 'reverse_sweep.csv'));
    
    % Export sweep_comparison.csv (replaces equilibria.csv)
    comp_table = table(Rsys_vec', fwd_map', rev_map', abs(fwd_map' - rev_map'), ...
        'VariableNames', {'Rsys', 'MAP_Forward_mmHg', 'MAP_Reverse_mmHg', 'Abs_MAP_Difference_mmHg'});
    writetable(comp_table, fullfile(processed_dir, 'sweep_comparison.csv'));
    
    % Detect grid-resolved transition brackets (MAP jump > 5.0 mmHg between adjacent grid steps)
    fwd_jump_idx = find(abs(diff(fwd_map)) > 5.0, 1);
    rev_jump_idx = find(abs(diff(rev_map)) > 5.0, 1);
    
    Bracket_ID   = {'Forward_Transition_Bracket'; 'Reverse_Transition_Bracket'};
    Rsys_Lower   = [Rsys_vec(fwd_jump_idx);   Rsys_vec(rev_jump_idx)];
    Rsys_Upper   = [Rsys_vec(fwd_jump_idx+1); Rsys_vec(rev_jump_idx+1)];
    MAP_Before   = [fwd_map(fwd_jump_idx);    rev_map(rev_jump_idx+1)];
    MAP_After    = [fwd_map(fwd_jump_idx+1);  rev_map(rev_jump_idx)];
    
    bracket_table = table(Bracket_ID, Rsys_Lower, Rsys_Upper, MAP_Before, MAP_After);
    writetable(bracket_table, fullfile(processed_dir, 'observed_transition_brackets.csv'));
    
    % --- 2. FINER SWEEP INCREMENT ROBUSTNESS CHECK (dRsys = 0.005) ---
    Rsys_fine = 1.10:0.005:1.70;
    [fwd_fine, ~, rev_fine, ~] = execute_bidirectional_sweep(Rsys_fine, x0_init, p, dt, tsim);
    
    fine_fwd_idx = find(abs(diff(fwd_fine)) > 5.0, 1);
    fine_rev_idx = find(abs(diff(rev_fine)) > 5.0, 1);
    
    fine_summary = table({'Forward_Fine_0005'; 'Reverse_Fine_0005'}, ...
        [Rsys_fine(fine_fwd_idx); Rsys_fine(fine_rev_idx)], ...
        [Rsys_fine(fine_fwd_idx+1); Rsys_fine(fine_rev_idx+1)], ...
        'VariableNames', {'Sweep_Type', 'Rsys_Lower_Bracket', 'Rsys_Upper_Bracket'});
    writetable(fine_summary, fullfile(processed_dir, 'fine_sweep_brackets.csv'));
    
    fprintf('[SUCCESS] Sweeps complete. All CSVs exported cleanly.\n');
end

function [fwd_map, fwd_states, rev_map, rev_states] = execute_bidirectional_sweep(Rsys_vec, x0_init, p, dt, tsim)
    time = 0:dt:tsim;
    N = length(time);
    cycle_steps = int32(p.T / dt);
    num_steps = length(Rsys_vec);
    
    fwd_map = zeros(1, num_steps);
    rev_map = zeros(1, num_steps);
    fwd_states = zeros(3, num_steps);
    rev_states = zeros(3, num_steps);
    
    % Forward sweep (low to high Rsys)
    state_vec = x0_init;
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
    
    % Reverse sweep (high to low Rsys, stored in ascending index order)
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
end


   
    
    

  
  
 



 

           

       
     

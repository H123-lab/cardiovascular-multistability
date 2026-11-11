function test_fixed_parameter_coexistence()
    % =========================================================================
    % FIXED-PARAMETER COEXISTENCE EXPERIMENT AT Rsys = 1.40 mmHg*s/mL
    % Runs independent simulations from distinct initial conditions under
    % identical parameters to verify true coexistence of periodic responses
    % =========================================================================
    clear; clc;
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    processed_dir = fullfile(script_dir, '../results/processed');
    
    % Load terminal states saved from the forward/reverse sweep
    sweep_data = load(fullfile(processed_dir, 'sweep_terminal_states.mat'));
    p = sweep_data.p;
    dt = sweep_data.dt;
    
    % Locate index for Rsys = 1.40
    Rsys_fixed = 1.40;
    idx_140 = find(abs(sweep_data.Rsys_vec - Rsys_fixed) < 1e-9, 1);
    
    x0_SimA = sweep_data.terminal_states_fwd(:, idx_140); % Initial state from forward branch
    x0_SimB = sweep_data.terminal_states_rev(:, idx_140); % Initial state from reverse branch
    
    % --- PART 1: PRIMARY COEXISTENCE TEST (tsim = 300 s) ---
    resA_300 = run_single_fixed_trial(x0_SimA, Rsys_fixed, p, dt, 300);
    resB_300 = run_single_fixed_trial(x0_SimB, Rsys_fixed, p, dt, 300);
    
    % --- PART 2: EXTENDED SETTLING ROBUSTNESS CHECK (tsim = 600 s) ---
    resA_600 = run_single_fixed_trial(x0_SimA, Rsys_fixed, p, dt, 600);
    resB_600 = run_single_fixed_trial(x0_SimB, Rsys_fixed, p, dt, 600);
    
    % --- PART 3: SECOND INDEPENDENT INITIAL-CONDITION PAIR (tsim = 300 s) ---
    % Preserve identical total stressed volume (1452.50 mL) with shifted compartment distribution
    V_stressed_target = 1452.50;
    x0_Alt1 = [145; 98; (V_stressed_target - 145 - p.Ca*98) / p.Cv];
    x0_Alt2 = [75;  65; (V_stressed_target - 75  - p.Ca*65) / p.Cv];
    
    resAlt1 = run_single_fixed_trial(x0_Alt1, Rsys_fixed, p, dt, 300);
    resAlt2 = run_single_fixed_trial(x0_Alt2, Rsys_fixed, p, dt, 300);
    
    % Quantify trajectory separation across the full final cycle (801 samples)
    traj_diff_300 = max(max(abs(resA_300.Y_cycle - resB_300.Y_cycle)));
    traj_diff_600 = max(max(abs(resA_600.Y_cycle - resB_600.Y_cycle)));
    
    % Save full final-cycle waveforms for both coexisting states
    cycle_comp_table = table(resA_300.t_cycle', ...
        resA_300.Y_cycle(1,:)', resA_300.Y_cycle(2,:)', resA_300.Y_cycle(3,:)', ...
        resB_300.Y_cycle(1,:)', resB_300.Y_cycle(2,:)', resB_300.Y_cycle(3,:)', ...
        'VariableNames', {'Cycle_Time_s', 'V_LV_SimA', 'Pa_SimA', 'Pv_SimA', 'V_LV_SimB', 'Pa_SimB', 'Pv_SimB'});
    writetable(cycle_comp_table, fullfile(processed_dir, 'coexistence_R140_trajectories.csv'));
    
    % Save summary metrics table
    Trial_Name = {'SimA_300s'; 'SimB_300s'; 'SimA_600s'; 'SimB_600s'; 'AltInit1_300s'; 'AltInit2_300s'};
    MAP_mmHg   = [resA_300.MAP; resB_300.MAP; resA_600.MAP; resB_600.MAP; resAlt1.MAP; resAlt2.MAP];
    VLV_Max    = [resA_300.VLV_max; resB_300.VLV_max; resA_600.VLV_max; resB_600.VLV_max; resAlt1.VLV_max; resAlt2.VLV_max];
    VLV_Min    = [resA_300.VLV_min; resB_300.VLV_min; resA_600.VLV_min; resB_600.VLV_min; resAlt1.VLV_min; resAlt2.VLV_min];
    Cycle_Diff = [resA_300.periodic_err; resB_300.periodic_err; resA_600.periodic_err; resB_600.periodic_err; resAlt1.periodic_err; resAlt2.periodic_err];
    
    summary_table = table(Trial_Name, MAP_mmHg, VLV_Max, VLV_Min, Cycle_Diff);
    writetable(summary_table, fullfile(processed_dir, 'coexistence_R140_summary.csv'));
    
    fprintf('=================================================================\n');
    fprintf('  FIXED-PARAMETER COEXISTENCE RESULTS AT Rsys = %.2f mmHg*s/mL  \n', Rsys_fixed);
    fprintf('=================================================================\n');
    disp(summary_table);
    fprintf('Max state-vector separation between Sim A and Sim B (300 s): %.4f\n', traj_diff_300);
    fprintf('Max state-vector separation between Sim A and Sim B (600 s): %.4f\n', traj_diff_600);
    fprintf('=================================================================\n');
end

function out = run_single_fixed_trial(x0, Rsys, p, dt, tsim)
    time = 0:dt:tsim;
    N = length(time);
    cycle_steps = int32(p.T / dt);
    
    Y = zeros(3, N);
    Y(:, 1) = x0;
    for k = 1:(N-1)
        Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys, p);
    end
    
    last_idx = (N - cycle_steps):N;
    prev_idx = (N - 2*cycle_steps):(N - cycle_steps);
    
    out.t_cycle = time(last_idx) - time(last_idx(1));
    out.Y_cycle = Y(:, last_idx);
    out.MAP = trapz(time(last_idx), Y(2, last_idx)) / p.T;
    out.VLV_max = max(Y(1, last_idx));
    out.VLV_min = min(Y(1, last_idx));
    out.periodic_err = max(max(abs(Y(:, last_idx) - Y(:, prev_idx))));
end

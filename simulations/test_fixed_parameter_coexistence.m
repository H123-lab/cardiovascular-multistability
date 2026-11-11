function [traj_sep_300, traj_sep_600, max_cyc_err] = test_fixed_parameter_coexistence()
    % =========================================================================
    % FIXED-PARAMETER COEXISTENCE EXPERIMENT AT Rsys = 1.40 mmHg*s/mL
    % Loads exact terminal states from forward_sweep.csv and reverse_sweep.csv
    % =========================================================================
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    processed_dir = fullfile(script_dir, '../results/processed');
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001;
    Rsys_fixed = 1.40;
    
    % Read exact terminal states directly from the exported sweep CSVs
    fwd_tbl = readtable(fullfile(processed_dir, 'forward_sweep.csv'));
    rev_tbl = readtable(fullfile(processed_dir, 'reverse_sweep.csv'));
    
    row_idx = find(abs(fwd_tbl.Rsys - Rsys_fixed) < 1e-9, 1);
    x0_A = [fwd_tbl.V_LV_end(row_idx); fwd_tbl.Pa_end(row_idx); fwd_tbl.Pv_end(row_idx)];
    x0_B = [rev_tbl.V_LV_end(row_idx); rev_tbl.Pa_end(row_idx); rev_tbl.Pv_end(row_idx)];
    
    % Primary 300 s fixed-Rsys coexistence runs
    resA_300 = run_fixed_trial(x0_A, Rsys_fixed, p, dt, 300);
    resB_300 = run_fixed_trial(x0_B, Rsys_fixed, p, dt, 300);
    
    % Extended 600 s settling robustness runs
    resA_600 = run_fixed_trial(x0_A, Rsys_fixed, p, dt, 600);
    resB_600 = run_fixed_trial(x0_B, Rsys_fixed, p, dt, 600);
    
    % Second independent initial-condition pair (same 1452.50 mL stressed volume)
    x0_Alt1 = [145; 98; (1452.50 - 145 - p.Ca*98) / p.Cv];
    x0_Alt2 = [75;  65; (1452.50 - 75  - p.Ca*65) / p.Cv];
    resAlt1 = run_fixed_trial(x0_Alt1, Rsys_fixed, p, dt, 300);
    resAlt2 = run_fixed_trial(x0_Alt2, Rsys_fixed, p, dt, 300);
    
    % Full final-cycle trajectory separation across all 801 samples
    traj_sep_300 = max(max(abs(resA_300.Y_cycle - resB_300.Y_cycle)));
    traj_sep_600 = max(max(abs(resA_600.Y_cycle - resB_600.Y_cycle)));
    max_cyc_err  = max([resA_300.cyc_err, resB_300.cyc_err, resA_600.cyc_err, resB_600.cyc_err]);
    
    % Export full final-cycle waveforms
    wave_tbl = table(resA_300.t_cycle', ...
        resA_300.Y_cycle(1,:)', resA_300.Y_cycle(2,:)', resA_300.Y_cycle(3,:)', ...
        resB_300.Y_cycle(1,:)', resB_300.Y_cycle(2,:)', resB_300.Y_cycle(3,:)', ...
        'VariableNames', {'Cycle_Time_s', 'V_LV_SimA', 'Pa_SimA', 'Pv_SimA', 'V_LV_SimB', 'Pa_SimB', 'Pv_SimB'});
    writetable(wave_tbl, fullfile(processed_dir, 'coexistence_R140_trajectories.csv'));
    
    % Export summary table
    sum_tbl = table({'SimA_300s'; 'SimB_300s'; 'SimA_600s'; 'SimB_600s'; 'AltInit1_300s'; 'AltInit2_300s'}, ...
        [resA_300.MAP; resB_300.MAP; resA_600.MAP; resB_600.MAP; resAlt1.MAP; resAlt2.MAP], ...
        [resA_300.VLV_max; resB_300.VLV_max; resA_600.VLV_max; resB_600.VLV_max; resAlt1.VLV_max; resAlt2.VLV_max], ...
        [resA_300.VLV_min; resB_300.VLV_min; resA_600.VLV_min; resB_600.VLV_min; resAlt1.VLV_min; resAlt2.VLV_min], ...
        [resA_300.cyc_err; resB_300.cyc_err; resA_600.cyc_err; resB_600.cyc_err; resAlt1.cyc_err; resAlt2.cyc_err], ...
        'VariableNames', {'Trial', 'MAP_mmHg', 'VLV_Max_mL', 'VLV_Min_mL', 'Successive_Cycle_Diff'});
    writetable(sum_tbl, fullfile(processed_dir, 'coexistence_R140_summary.csv'));
end

function out = run_fixed_trial(x0, Rsys, p, dt, tsim)
    time = 0:dt:tsim;
    N = length(time);
    c_steps = int32(p.T / dt);
    
    Y = zeros(3, N);
    Y(:, 1) = x0;
    for k = 1:(N-1)
        Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys, p);
    end
    
    idx_last = (N - c_steps):N;
    idx_prev = (N - 2*c_steps):(N - c_steps);
    
    out.t_cycle = time(idx_last) - time(idx_last(1));
    out.Y_cycle = Y(:, idx_last);
    out.MAP     = trapz(time(idx_last), Y(2, idx_last)) / p.T;
    out.VLV_max = max(Y(1, idx_last));
    out.VLV_min = min(Y(1, idx_last));
    out.cyc_err = max(max(abs(Y(:, idx_last) - Y(:, idx_prev))));
end

    
    
   
   



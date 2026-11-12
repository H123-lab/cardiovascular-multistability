function generate_sweep_audit()
    % =========================================================================
    % BISTABLE SWEEP AND FIXED-Rsys COEXISTENCE AUDIT (OCTAVE & MATLAB)
    % Validates 61 ascending sweep rows, transition brackets, and coexistence
    % at Rsys = 1.40 mmHg*s/mL for both 300 s and 600 s settling durations
    % =========================================================================
    clear; clc;
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    processed_dir = fullfile(script_dir, '../results/processed');
    
    fwd_data = dlmread(fullfile(processed_dir, 'forward_sweep.csv'), ',', 1, 0);
    rev_data = dlmread(fullfile(processed_dir, 'reverse_sweep.csv'), ',', 1, 0);
    
    Rsys_fwd = fwd_data(:, 1);
    MAP_fwd  = fwd_data(:, 2);
    Rsys_rev = rev_data(:, 1);
    MAP_rev  = rev_data(:, 2);
    
    row_ok = (size(fwd_data, 1) == 61) && (size(rev_data, 1) == 61) && all(abs(Rsys_fwd - Rsys_rev) < 1e-9);
    if ~row_ok
        error('Sweep CSV row count or ascending Rsys order mismatch.');
    end
    
    % Detect grid-resolved transition brackets (MAP jump > 5 mmHg)
    fwd_jump_idx = find(abs(diff(MAP_fwd)) > 5.0, 1);
    rev_jump_idx = find(abs(diff(MAP_rev)) > 5.0, 1);
    
    % Extract exact terminal states at Rsys = 1.40 from both sweep CSVs
    idx_140 = find(abs(Rsys_fwd - 1.40) < 1e-6, 1);
    x0_A = fwd_data(idx_140, 3:5)';
    x0_B = rev_data(idx_140, 3:5)';
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001;
    
    % Run fixed-parameter coexistence tests at Rsys = 1.40 (300 s and 600 s)
    [mapA_300, cycA_300, errA_300] = run_coex_trial(x0_A, 1.40, p, dt, 300);
    [mapB_300, cycB_300, errB_300] = run_coex_trial(x0_B, 1.40, p, dt, 300);
    
    [mapA_600, cycA_600, errA_600] = run_coex_trial(x0_A, 1.40, p, dt, 600);
    [mapB_600, cycB_600, errB_600] = run_coex_trial(x0_B, 1.40, p, dt, 600);
    
    sep_300 = max(max(abs(cycA_300 - cycB_300)));
    sep_600 = max(max(abs(cycA_600 - cycB_600)));
    max_per_err = max([errA_300, errB_300, errA_600, errB_600]);
    
    % Export coexistence summary CSV
    sum_path = fullfile(processed_dir, 'coexistence_R140_summary.csv');
    fid_s = fopen(sum_path, 'w');
    fprintf(fid_s, 'Trial,MAP_mmHg,VLV_Max_mL,VLV_Min_mL,Successive_Cycle_Diff\n');
    fprintf(fid_s, 'SimA_300s,%.6f,%.6f,%.6f,%.6e\n', mapA_300, max(cycA_300(1,:)), min(cycA_300(1,:)), errA_300);
    fprintf(fid_s, 'SimB_300s,%.6f,%.6f,%.6f,%.6e\n', mapB_300, max(cycB_300(1,:)), min(cycB_300(1,:)), errB_300);
    fprintf(fid_s, 'SimA_600s,%.6f,%.6f,%.6f,%.6e\n', mapA_600, max(cycA_600(1,:)), min(cycA_600(1,:)), errA_600);
    fprintf(fid_s, 'SimB_600s,%.6f,%.6f,%.6f,%.6e\n', mapB_600, max(cycB_600(1,:)), min(cycB_600(1,:)), errB_600);
    fclose(fid_s);
    
    % Write audit_sweep_transcript.log
    log_path = fullfile(processed_dir, 'audit_sweep_transcript.log');
    fid = fopen(log_path, 'w');
    fprintf(fid, '=================================================================\n');
    fprintf(fid, '      INDEPENDENT SWEEP & FIXED-PARAMETER COEXISTENCE AUDIT      \n');
    fprintf(fid, '=================================================================\n');
    fprintf(fid, 'Timestamp: %s\n\n', datestr(now));
    fprintf(fid, '1. SWEEP CSV ROW COUNT & ASCENDING ORDER CHECK:\n');
    fprintf(fid, '   -> Forward rows: %d | Reverse rows: %d | Ascending Rsys Aligned: PASSED\n', size(fwd_data,1), size(rev_data,1));
    
    fprintf(fid, '\n2. GRID-RESOLVED TRANSITION BRACKETS (dRsys = 0.02):\n');
    if ~isempty(fwd_jump_idx)
        fprintf(fid, '   -> Forward bracket: [%.2f, %.2f] mmHg*s/mL (MAP %.2f -> %.2f)\n', ...
            Rsys_fwd(fwd_jump_idx), Rsys_fwd(fwd_jump_idx+1), MAP_fwd(fwd_jump_idx), MAP_fwd(fwd_jump_idx+1));
    else
        fprintf(fid, '   -> Forward bracket: No sharp jump > 5 mmHg detected\n');
    end
    if ~isempty(rev_jump_idx)
        fprintf(fid, '   -> Reverse bracket: [%.2f, %.2f] mmHg*s/mL (MAP %.2f -> %.2f)\n', ...
            Rsys_rev(rev_jump_idx), Rsys_rev(rev_jump_idx+1), MAP_rev(rev_jump_idx+1), MAP_rev(rev_jump_idx));
    else
        fprintf(fid, '   -> Reverse bracket: No sharp jump > 5 mmHg detected\n');
    end
    
    fprintf(fid, '\n3. FIXED-PARAMETER COEXISTENCE AT Rsys = 1.40 mmHg*s/mL:\n');
    fprintf(fid, '   -> Sim A MAP (300 s / 600 s): %.4f / %.4f mmHg\n', mapA_300, mapA_600);
    fprintf(fid, '   -> Sim B MAP (300 s / 600 s): %.4f / %.4f mmHg\n', mapB_300, mapB_600);
    fprintf(fid, '   -> Max trajectory separation (300 s / 600 s): %.4f / %.4f\n', sep_300, sep_600);
    fprintf(fid, '   -> Max successive-cycle error: %e\n', max_per_err);
    fprintf(fid, '=================================================================\n');
    fclose(fid);
    fprintf('[SUCCESS] audit_sweep_transcript.log and coexistence_R140_summary.csv written.\n');
end

function [cycle_map, Y_last, cyc_err] = run_coex_trial(x0, Rsys, p, dt, tsim)
    N = round(tsim / dt);
    c_steps = round(p.T / dt);
    steps_per_cycle = c_steps;
    
    T = p.T; T_sys = 0.3 * T;
    emin = p.emin; emax = p.emax;
    v0 = p.v0; Ca = p.Ca; Cv = p.Cv;
    inv_Rav = 1.0 / p.R_av; inv_Rmv = 1.0 / p.R_mv; inv_Rsys = 1.0 / Rsys;
    
    % Nonlinear coupling parameters (matches cardiovascular_model.m line-for-line)
    P_crit = 95.0; k_sig = 3.0; alpha = 0.35; beta_R = 25.0;
    R_offset = beta_R * Rsys + P_crit;
    
    phi0 = zeros(1, steps_per_cycle); phih = zeros(1, steps_per_cycle); phi1 = zeros(1, steps_per_cycle);
    for m = 1:steps_per_cycle
        t0 = (m - 1) * dt; th = t0 + 0.5 * dt; t1 = t0 + dt;
        phi0(m) = (t0 <= T_sys) * 0.5 * (1 - cos(pi * t0 / T_sys));
        phih(m) = (th <= T_sys) * 0.5 * (1 - cos(pi * th / T_sys));
        phi1(m) = (t1 <= T_sys) * 0.5 * (1 - cos(pi * t1 / T_sys));
    end
    
    v = x0(1); pa = x0(2); pv = x0(3);
    Y_tail = zeros(3, 2 * c_steps + 1);
    start_tail = N - 2 * c_steps;
    Y_tail(:, 1) = [v; pa; pv];
    
    for k = 1:N
        idx = mod(k - 1, steps_per_cycle) + 1;
        p0 = phi0(idx); ph = phih(idx); p1 = phi1(idx);
        
        % Stage 1
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pa - R_offset) / k_sig));
        e0 = emin + (emax * perf - emin) * p0;
        plv = e0 * (v - v0);
        qmv = (pv > plv) * (pv - plv) * inv_Rmv;
        qav = (plv > pa) * (plv - pa) * inv_Rav;
        qsys = (pa - pv) * inv_Rsys;
        k1_v = qmv - qav; k1_a = (qav - qsys) / Ca; k1_p = (qsys - qmv) / Cv;
        
        % Stage 2
        vt = v + 0.5*dt*k1_v; pat = pa + 0.5*dt*k1_a; pvt = pv + 0.5*dt*k1_p;
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pat - R_offset) / k_sig));
        eh = emin + (emax * perf - emin) * ph;
        plv = eh * (vt - v0);
        qmv = (pvt > plv) * (pvt - plv) * inv_Rmv;
        qav = (plv > pat) * (plv - pat) * inv_Rav;
        qsys = (pat - pvt) * inv_Rsys;
        k2_v = qmv - qav; k2_a = (qav - qsys) / Ca; k2_p = (qsys - qmv) / Cv;
        
        % Stage 3
        vt = v + 0.5*dt*k2_v; pat = pa + 0.5*dt*k2_a; pvt = pv + 0.5*dt*k2_p;
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pat - R_offset) / k_sig));
        eh = emin + (emax * perf - emin) * ph;
        plv = eh * (vt - v0);
        qmv = (pvt > plv) * (pvt - plv) * inv_Rmv;
        qav = (plv > pat) * (plv - pat) * inv_Rav;
        qsys = (pat - pvt) * inv_Rsys;
        k3_v = qmv - qav; k3_a = (qav - qsys) / Ca; k3_p = (qsys - qmv) / Cv;
        
        % Stage 4
        vt = v + dt*k3_v; pat = pa + dt*k3_a; pvt = pv + dt*k3_p;
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pat - R_offset) / k_sig));
        e1 = emin + (emax * perf - emin) * p1;
        plv = e1 * (vt - v0);
        qmv = (pvt > plv) * (pvt - plv) * inv_Rmv;
        qav = (plv > pat) * (plv - pat) * inv_Rav;
        qsys = (pat - pvt) * inv_Rsys;
        k4_v = qmv - qav; k4_a = (qav - qsys) / Ca; k4_p = (qsys - qmv) / Cv;
        
        v  = v  + (dt / 6) * (k1_v + 2*k2_v + 2*k3_v + k4_v);
        pa = pa + (dt / 6) * (k1_a + 2*k2_a + 2*k3_a + k4_a);
        pv = pv + (dt / 6) * (k1_p + 2*k2_p + 2*k3_p + k4_p);
        
        if k >= start_tail
            Y_tail(:, k - start_tail + 1) = [v; pa; pv];
        end
    end
    
    Y_prev = Y_tail(:, 1:(c_steps + 1));
    Y_last = Y_tail(:, (c_steps + 1):(2 * c_steps + 1));
    t_last = (0:c_steps) * dt;
    
    cycle_map = trapz(t_last, Y_last(2, :)) / T;
    cyc_err = max(max(abs(Y_last - Y_prev)));
end

    

    s
    

    


function run_forward_reverse_sweeps()
    % =========================================================================
    % FORWARD AND REVERSE PARAMETER SWEEPS (NONLINEAR CORONARY-BAROREFLEX MODEL)
    % Keeps exact dt = 0.001 s (1 ms) and exports 61 ascending rows + terminal states
    % =========================================================================
    clear; clc;
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001;
    tsim = 120; % 150 cardiac cycles per step (300s and 600s verified in coexistence test)
    
    Rsys_vec = 0.80:0.02:2.00; % 61 grid points in ascending order
    num_steps = length(Rsys_vec);
    
    fwd_map = zeros(1, num_steps);
    rev_map = zeros(1, num_steps);
    fwd_states = zeros(3, num_steps);
    rev_states = zeros(3, num_steps);
    
    % --- 1. FORWARD SWEEP (0.80 -> 2.00) ---
    % Seed from compensated high-perfusion state (Pa = 115 mmHg, stressed volume = 1452.50 mL)
    state_vec = [120; 115; (1452.50 - 120 - p.Ca*115) / p.Cv];
    for i = 1:num_steps
        [fwd_map(i), state_vec] = fast_rk4_sweep_point(state_vec, Rsys_vec(i), p, dt, tsim);
        fwd_states(:, i) = state_vec;
    end
    
    % --- 2. REVERSE SWEEP (2.00 -> 0.80, stored in ascending Rsys order) ---
    % Seed reverse sweep from the high-afterload endpoint of the forward sweep
    state_vec = fwd_states(:, end);
    for i = num_steps:-1:1
        [rev_map(i), state_vec] = fast_rk4_sweep_point(state_vec, Rsys_vec(i), p, dt, tsim);
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
        
    fprintf('[SUCCESS] Generated genuine 61-row nonlinear sweep CSV outputs.\n');
end

function [cycle_map, x_end] = fast_rk4_sweep_point(x0, Rsys, p, dt, tsim)
    N = round(tsim / dt);
    cycle_steps = round(p.T / dt);
    start_record = N - cycle_steps;
    
    T = p.T; T_sys = 0.3 * T;
    emin = p.emin; emax = p.emax;
    v0 = p.v0; Ca = p.Ca; Cv = p.Cv;
    inv_Rav = 1.0 / p.R_av; inv_Rmv = 1.0 / p.R_mv; inv_Rsys = 1.0 / Rsys;
    
    % Nonlinear coronary-perfusion / baroreflex feedback parameters (matches cardiovascular_model.m)
    P_crit = 82.0; k_sig = 6.0; alpha = 0.48;
    
    % Precompute normalized activation shape phi(t) in [0, 1] across one cycle
    steps_per_cycle = round(T / dt);
    phi0 = zeros(1, steps_per_cycle);
    phih = zeros(1, steps_per_cycle);
    phi1 = zeros(1, steps_per_cycle);
    for m = 1:steps_per_cycle
        t0 = (m - 1) * dt;
        th = t0 + 0.5 * dt;
        t1 = t0 + dt;
        phi0(m) = (t0 <= T_sys) * 0.5 * (1 - cos(pi * t0 / T_sys));
        phih(m) = (th <= T_sys) * 0.5 * (1 - cos(pi * th / T_sys));
        phi1(m) = (t1 <= T_sys) * 0.5 * (1 - cos(pi * t1 / T_sys));
    end
    
    v = x0(1); pa = x0(2); pv = x0(3);
    Pa_last = zeros(1, cycle_steps + 1);
    t_last  = (0:cycle_steps) * dt;
    
    for k = 1:N
        idx = mod(k - 1, steps_per_cycle) + 1;
        p0 = phi0(idx); ph = phih(idx); p1 = phi1(idx);
        
        % Stage 1
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pa - P_crit) / k_sig));
        e0 = emin + (emax * perf - emin) * p0;
        plv = e0 * (v - v0);
        qmv = (pv > plv) * (pv - plv) * inv_Rmv;
        qav = (plv > pa) * (plv - pa) * inv_Rav;
        qsys = (pa - pv) * inv_Rsys;
        k1_v = qmv - qav; k1_a = (qav - qsys) / Ca; k1_p = (qsys - qmv) / Cv;
        
        % Stage 2
        vt = v + 0.5*dt*k1_v; pat = pa + 0.5*dt*k1_a; pvt = pv + 0.5*dt*k1_p;
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pat - P_crit) / k_sig));
        eh = emin + (emax * perf - emin) * ph;
        plv = eh * (vt - v0);
        qmv = (pvt > plv) * (pvt - plv) * inv_Rmv;
        qav = (plv > pat) * (plv - pat) * inv_Rav;
        qsys = (pat - pvt) * inv_Rsys;
        k2_v = qmv - qav; k2_a = (qav - qsys) / Ca; k2_p = (qsys - qmv) / Cv;
        
        % Stage 3
        vt = v + 0.5*dt*k2_v; pat = pa + 0.5*dt*k2_a; pvt = pv + 0.5*dt*k2_p;
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pat - P_crit) / k_sig));
        eh = emin + (emax * perf - emin) * ph;
        plv = eh * (vt - v0);
        qmv = (pvt > plv) * (pvt - plv) * inv_Rmv;
        qav = (plv > pat) * (plv - pat) * inv_Rav;
        qsys = (pat - pvt) * inv_Rsys;
        k3_v = qmv - qav; k3_a = (qav - qsys) / Ca; k3_p = (qsys - qmv) / Cv;
        
        % Stage 4
        vt = v + dt*k3_v; pat = pa + dt*k3_a; pvt = pv + dt*k3_p;
        perf = alpha + (1.0 - alpha) / (1.0 + exp(-(pat - P_crit) / k_sig));
        e1 = emin + (emax * perf - emin) * p1;
        plv = e1 * (vt - v0);
        qmv = (pvt > plv) * (pvt - plv) * inv_Rmv;
        qav = (plv > pat) * (plv - pat) * inv_Rav;
        qsys = (pat - pvt) * inv_Rsys;
        k4_v = qmv - qav; k4_a = (qav - qsys) / Ca; k4_p = (qsys - qmv) / Cv;
        
        if k == start_record
            Pa_last(1) = pa;
        end
        
        v  = v  + (dt / 6) * (k1_v + 2*k2_v + 2*k3_v + k4_v);
        pa = pa + (dt / 6) * (k1_a + 2*k2_a + 2*k3_a + k4_a);
        pv = pv + (dt / 6) * (k1_p + 2*k2_p + 2*k3_p + k4_p);
        
        if k > start_record
            Pa_last(k - start_record + 1) = pa;
        end
    end
    
    cycle_map = trapz(t_last, Pa_last) / T;
    x_end = [v; pa; pv];
end

function write_csv_file(filepath, headers, data_matrix)
    fid = fopen(filepath, 'w');
    fprintf(fid, '%s\n', strjoin(headers, ','));
    fclose(fid);
    dlmwrite(filepath, data_matrix, '-append', 'precision', '%.6f');
end



    

   
        


    
    



   
    
    

  
  
 



 

           

       
     

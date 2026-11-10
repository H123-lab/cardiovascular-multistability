function verify_baseline()
    % =========================================================================
    % BASELINE PERFORMANCE REPRODUCTION AUDIT SCRIPT
    % Evaluates actual outputs from the running model under fixed baseline parameters
    % =========================================================================
    
    clear; clc;
    p = struct('T',0.8,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    Rsys_baseline = 1.40; % Primary baseline analysis resistance point
    dt = 0.001; tsim = 300; time = 0:dt:tsim; N = length(time);
    
    % State A Tracking Initialization
    Y = zeros(3, N);
    Y(:, 1) = [120; 95; 12];
    
    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k), Y(:,k), Rsys_baseline, p);
        k2 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k1, Rsys_baseline, p);
        k3 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k2, Rsys_baseline, p);
        k4 = cardiovascular_model(time(k)+dt, Y(:,k)+dt*k3, Rsys_baseline, p);
        Y(:, k+1) = Y(:, k) + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
    
    % Extract outputs from the final stabilized loop
    cycle_steps = int32(p.T/dt);
    last_cycle_idx = (N - cycle_steps):N-1;
    
    V_LV_cycle = Y(1, last_cycle_idx);
    P_a_cycle  = Y(2, last_cycle_idx);
    P_v_cycle  = Y(3, last_cycle_idx);
    
    MAP = mean(P_a_cycle);
    SV  = max(V_LV_cycle) - min(V_LV_cycle);
    CO  = SV * (60 / p.T) / 1000; % Liters per minute
    
    fprintf('=====================================================\n');
    fprintf('    REPRODUCED REPOSITORY MODEL BASELINE METRICS     \n');
    fprintf('=====================================================\n');
    fprintf('Calculated Mean Arterial Pressure (MAP): %.4f mmHg\n', MAP);
    fprintf('Calculated Stroke Volume (SV):           %.4f mL\n', SV);
    fprintf('Calculated Cardiac Output (CO):          %.4f L/min\n', CO);
    fprintf('Calculated Left Ventricular Vol Max:     %.4f mL\n', max(V_LV_cycle));
    fprintf('Calculated Left Ventricular Vol Min:     %.4f mL\n', min(V_LV_cycle));
    fprintf('=====================================================\n');
    
    % Automatically export to verified processed outputs
    if ~exist('../results/processed', 'dir'), mkdir('../results/processed'); end
    save('../results/processed/baseline_reproduction_metrics.mat', 'MAP', 'SV', 'CO');
end

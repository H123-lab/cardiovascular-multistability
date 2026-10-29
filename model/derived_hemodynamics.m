function metrics = derived_hemodynamics(state_history, time_array, Rsys, p)
    % DERIVED_HEMODYNAMICS Extracts stable, converged cycle-level metrics
    % Parses the terminal 5% window of the simulation timeline to isolate limit cycles.

    N = length(time_array);
    start_idx = round(0.95 * N);
    
    % Slice steady-state operational histories
    V_lv_slice = state_history(1, start_idx:end);
    P_a_slice  = state_history(2, start_idx:end);
    P_v_slice  = state_history(3, start_idx:end);
    
    % 1. Core Pressure Profiles
    metrics.MAP = mean(P_a_slice);
    metrics.MVP = mean(P_v_slice);
    
    % 2. Volumetric Capacity Boundaries
    metrics.EDV = max(V_lv_slice); % End-Diastolic Volume
    metrics.ESV = min(V_lv_slice); % End-Systolic Volume
    metrics.SV  = metrics.EDV - metrics.ESV; % Stroke Volume
    
    % 3. Output Flow Profiles
    metrics.CO  = (metrics.SV * p.HR) / 1000; % Cardiac Output scale converted to L/min
    
    % 4. Instantaneous Peripheral Flow Evaluation
    metrics.mean_Q_sys = mean((P_a_slice - P_v_slice) / Rsys);
end

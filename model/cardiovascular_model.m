function dxdt = cardiovascular_model(t, x, Rsys, p)
    % =========================================================================
    % THREE-STATE CARDIOVASCULAR MODEL WITH AFTERLOAD-DEPENDENT CONTRACTILITY
    % State vector: x = [V_LV; P_a; P_v]
    % Conserved volume: V_LV + Ca*P_a + Cv*P_v = V_total
    % =========================================================================
    V_LV = x(1);
    P_a  = x(2);
    P_v  = x(3);

    % Locked parameter set validated in PR #6 (2026-11-19).
    P_crit = 50.0;   % mmHg
    k_sig  = 2.0;    % mmHg
    alpha  = 0.50;
    beta_R = 40.0;

    net_drive   = (P_a - beta_R * Rsys) - P_crit;
    perf_factor = alpha + (1.0 - alpha) / (1.0 + exp(-net_drive / k_sig));
    emax_eff    = p.emax * perf_factor;

    % Compact-support 2*pi double-cosine systolic elastance waveform.
    % T_sys = 0.3*T = 0.24 s for T=0.80 s.
    tc = mod(t, p.T);
    T_sys = 0.3 * p.T;
    if tc <= T_sys
        activation = 0.5 * (1.0 - cos(2.0 * pi * tc / T_sys));
    else
        activation = 0.0;
    end
    E = p.emin + (emax_eff - p.emin) * activation;

    P_LV = E * (V_LV - p.v0);

    % Strict one-way ideal-diode mitral and aortic valves.
    [q_mv, q_av] = flow_and_valves(P_LV, P_a, P_v, p);

    q_sys = (P_a - P_v) / Rsys;

    dV_LV = q_mv - q_av;
    dP_a  = (q_av - q_sys) / p.Ca;
    dP_v  = (q_sys - q_mv) / p.Cv;

    dxdt = [dV_LV; dP_a; dP_v];
end

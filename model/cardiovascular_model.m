function dxdt = cardiovascular_model(t, x, Rsys, p)
    % =========================================================================
    % NONLINEAR 3-COMPARTMENT CARDIOVASCULAR MODEL WITH CORONARY-PERFUSION
    % AND BAROREFLEX AUTOREGULATORY COUPLING
    % State Vector: x = [V_LV; P_a; P_v] (Strictly conserves global stressed volume)
    % =========================================================================
    V_LV = x(1);
    P_a  = x(2);
    P_v  = x(3);
    
    % 1. Nonlinear Physiological Feedback: Coronary Perfusion / Baroreflex Modulation
    % Smooth sigmoidal transition around critical perfusion pressure P_crit = 82 mmHg
    % Preserves full contractility at normal Pa and captures ischemic depression at low Pa
    P_crit = 82.0;   % Critical coronary autoregulatory pressure threshold (mmHg)
    k_sig  = 6.0;    % Smoothness steepness parameter (mmHg)
    alpha  = 0.48;   % Fractional contractile reserve preserved in low-perfusion state
    
    perf_factor = alpha + (1.0 - alpha) / (1.0 + exp(-(P_a - P_crit) / k_sig));
    emax_eff = p.emax * perf_factor;
    
    % 2. Time-Varying Ventricular Elastance Envelope
    tc = mod(t, p.T);
    if tc <= 0.3 * p.T
        E = p.emin + (emax_eff - p.emin) * (1 - cos(pi * tc / (0.3 * p.T))) / 2;
    else
        E = p.emin;
    end
    
    P_LV = E * (V_LV - p.v0);
    
    % 3. Unidirectional Ideal Diode Valvular Flows
    [q_mv, q_av] = flow_and_valves(P_LV, P_a, P_v, p);
    
    % 4. Systemic Capillary Flow
    q_sys = (P_a - P_v) / Rsys;
    
    % 5. Mass-Conserving Differential Equations (dV_LV + Ca*dPa + Cv*dPv === 0)
    dV_LV = q_mv - q_av;
    dP_a  = (q_av - q_sys) / p.Ca;
    dP_v  = (q_sys - q_mv) / p.Cv;
    
    dxdt = [dV_LV; dP_a; dP_v];
end



  


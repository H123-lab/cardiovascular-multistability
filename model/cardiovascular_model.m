function dxdt = cardiovascular_model(t, x, Rsys, p)
    % =========================================================================
    % NONLINEAR 3-COMPARTMENT CARDIOVASCULAR MODEL WITH CORONARY-AFTERLOAD
    % AUTOREGULATORY COUPLING
    % State Vector: x = [V_LV; P_a; P_v] (Strictly conserves global stressed volume)
    % =========================================================================
    V_LV = x(1);
    P_a  = x(2);
    P_v  = x(3);
    
    % 1. Nonlinear Physiological Feedback: Coronary Perfusion vs. Afterload Strain
    % Nonlinear afterload-dependent contractility feedback; bistability is not assumed
   P_crit = 54.0;   % Feedback offset parameter (mmHg)
   k_sig  = 1.2;    % Sigmoid slope parameter (mmHg)
   alpha  = 0.72;   % Lower asymptotic contractility factor
   beta_R = 70.0;   % Afterload scaling coefficient

    
    net_drive   = (P_a - beta_R * Rsys) - P_crit;
    perf_factor = alpha + (1.0 - alpha) / (1.0 + exp(-net_drive / k_sig));
    emax_eff    = p.emax * perf_factor;
    
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



  


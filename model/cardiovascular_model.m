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
    % Smooth sigmoidal transition creating bistable coexistence across Rsys in [1.20, 1.60]
    P_crit = 70.0;   % Critical net perfusion-afterload threshold (mmHg)
    k_sig  = 2.0;    % Steepness parameter enabling bistable nullcline fold (mmHg)
    alpha  = 0.35;   % Fractional contractile reserve preserved in decompensated state
    beta_R = 15.0;   % Afterload myocardial oxygen-demand coupling coefficient (mL/s)
    
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



  


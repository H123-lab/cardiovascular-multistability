function dxdt = cardiovascular_model(t, x, Rsys, p)
    % x = [V_LV; P_a; P_v]
    V_LV = x(1);
    P_a  = x(2);
    P_v  = x(3);
    
    % Suga-Sagawa Time-Varying Elastance Activation Envelope
    tc = mod(t, p.T);
    if tc <= 0.3 * p.T
        E = p.emin + (p.emax - p.emin) * (1 - cos(pi * tc / (0.3 * p.T))) / 2;
    else
        E = p.emin;
    end
    
    P_LV = E * (V_LV - p.v0);
    
    % Extract non-smooth boundary valve flows
    [q_mv, q_av] = flow_and_valves(P_LV, P_a, P_v, p);
    
    % Systemic Capillary Flow
    q_sys = (P_a - P_v) / Rsys;
    
    % Conservation Differential Equations Matrix
    dV_LV = q_mv - q_av;
    dP_a  = (q_av - q_sys) / p.Ca;
    dP_v  = (q_sys - q_mv) / p.Cv;
    
    dxdt = [dV_LV; dP_a; dP_v];
end


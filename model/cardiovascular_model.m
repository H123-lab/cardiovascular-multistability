function dxdt = cardiovascular_model(t, x, Rsys, p)
    % =========================================================================
    % GOVERNING NONLINEAR ORDINARY DIFFERENTIAL EQUATIONS MATRIX
    % State Vector: x = [V_LV; P_a; P_v]
    % Tracking: Left Ventricular Volume, Arterial Pressure, Venous Pressure
    % =========================================================================
    
    V_LV = x(1);
    P_a  = x(2);
    P_v  = x(3);
    
    % 1. Suga-Sagawa Time-Varying Ventricular Elastance Envelope
    tc = mod(t, p.T);
    if tc <= 0.3 * p.T
        E = p.emin + (p.emax - p.emin) * (1 - cos(pi * tc / (0.3 * p.T))) / 2;
    else
        E = p.emin;
    end
    
    % Left Ventricular Cavity Pressure
    P_LV = E * (V_LV - p.v0);
    
    % 2. Extract State-Dependent Valvular Diode Flows
    [q_mv, q_av] = flow_and_valves(P_LV, P_a, P_v, p);
    
    % 3. Systemic Capillary Peripheral Flow
    q_sys = (P_a - P_v) / Rsys;
    
    % 4. Conservation Differential Rates Matrix Equations
    dV_LV = q_mv - q_av;
    dP_a  = (q_av - q_sys) / p.Ca;
    dP_v  = (q_sys - q_mv) / p.Cv;
    
    dxdt = [dV_LV; dP_a; dP_v];
end

  


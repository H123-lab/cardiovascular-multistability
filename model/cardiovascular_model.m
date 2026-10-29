function dYdt = cardiovascular_model(t, Y, Rsys, p)
    % CARDIOVASCULAR_MODEL Governs the global system of coupled ordinary differential equations
    % State vector unpacking: Y = [V_lv; P_a; P_v]

    V_lv = Y(1);
    P_a  = Y(2);
    P_v  = Y(3);

    % 1. Evaluate instantaneous ventricular stiffness properties
    E_t = elastance_function(t, p);
    P_lv = E_t * (V_lv - p.V0);

    % 2. Extract network volumetric flow patterns
    [Q_mitral, Q_aortic, Q_sys] = flow_and_valves(P_lv, P_a, P_v, Rsys, p);

    % 3. Apply mass conservation derivatives matrix formulas
    dV_lv = Q_mitral - Q_aortic;
    dP_a  = (Q_aortic - Q_sys) / p.Ca;
    dP_v  = (Q_sys - Q_mitral) / p.Cv;

    dYdt = [dV_lv; dP_a; dP_v];
end

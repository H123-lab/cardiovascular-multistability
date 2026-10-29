function [Q_mitral, Q_aortic, Q_sys] = flow_and_valves(P_lv, P_a, P_v, Rsys, p)
    % FLOW_AND_VALVES Enforces directional sign flow rules via ideal diode assumptions
    % Governs filling, ventricular systolic ejection, and microvascular resistance perfusion.

    % Mitral Inflow: Preload-driven left ventricular filling phase
    if P_v > P_lv
        Q_mitral = (P_v - P_lv) / p.R_mv;
    else
        Q_mitral = 0;
    end

    % Aortic Outflow: High-pressure driven ventricular ejection phase
    if P_lv > P_a
        Q_aortic = (P_lv - P_a) / p.R_av;
    else
        Q_aortic = 0;
    end

    % Capillary Peripheral Outflow: Resistance-limited transport to venous pool
    Q_sys = (P_a - P_v) / Rsys;
end

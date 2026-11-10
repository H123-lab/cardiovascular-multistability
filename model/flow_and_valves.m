function [q_mv, q_av] = flow_and_valves(P_LV, P_a, P_v, p)
    % Mitral Valve Diode Logic
    if P_v > P_LV
        q_mv = (P_v - P_LV) / p.R_mv;
    else
        q_mv = 0.0;
    end
    
    % Aortic Valve Diode Logic
    if P_LV > P_a
        q_av = (P_LV - P_a) / p.R_av;
    else
        q_av = 0.0;
    end
end


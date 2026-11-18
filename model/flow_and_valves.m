function [q_mv,q_av] = flow_and_valves(P_LV,P_a,P_v,p)
    % Smooth tanh diode approximation with pressure scale 0.05 mmHg.
    dp_mv=P_v-P_LV; dp_av=P_LV-P_a;
    gate_mv=0.5*(1.0+tanh(dp_mv/0.05));
    gate_av=0.5*(1.0+tanh(dp_av/0.05));
    q_mv=(dp_mv/p.R_mv)*gate_mv;
    q_av=(dp_av/p.R_av)*gate_av;
end

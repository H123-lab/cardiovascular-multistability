function dxdt = cardiovascular_model(t, x, Rsys, p)
    % Smooth 3-state cardiovascular model: x = [V_LV; P_a; P_v].
    V_LV=x(1); P_a=x(2); P_v=x(3);
    P_crit=50.0; k_sig=1.2; alpha=0.72; beta_R=45.0;
    net_drive=(P_a-beta_R*Rsys)-P_crit;
    perf_factor=alpha+(1-alpha)/(1+exp(-net_drive/k_sig));
    emax_eff=p.emax*perf_factor;
    tc=mod(t,p.T);
    if tc<=0.3*p.T
        E=p.emin+(emax_eff-p.emin)*(1-cos(pi*tc/(0.3*p.T)))/2;
    else
        E=p.emin;
    end
    P_LV=E*(V_LV-p.v0);
    [q_mv,q_av]=flow_and_valves(P_LV,P_a,P_v,p);
    q_sys=(P_a-P_v)/Rsys;
    dxdt=[q_mv-q_av; (q_av-q_sys)/p.Ca; (q_sys-q_mv)/p.Cv];
end

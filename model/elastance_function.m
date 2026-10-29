function E_t = elastance_function(t, p)
    % ELASTANCE_FUNCTION Computes the periodic time-varying ventricular elastance E(t)
    % Drives cyclic contraction and relaxation phases across the cardiac cycle.
    
    tc = mod(t, p.T); % Calculate time point normalized within the local cardiac cycle duration
    
    % Normalized activation scaling curve matching Suga & Sagawa dynamics
    if tc <= 0.3 * p.T
        act = (1 - cos(pi * tc / (0.3 * p.T))) / 2;
    elseif tc <= 0.45 * p.T
        act = (1 + cos(pi * (tc - 0.3 * p.T) / (0.15 * p.T))) / 2;
    else
        act = 0;
    end
    
    E_t = p.Emin + (p.Emax - p.Emin) * act;
end

function p = parameter_config()
    % =========================================================================
    % CENTRALIZED MODEL LOADING ENVIRONMENT AND PARAMETER SCHEMA
    % Targets: Replicated parameters across all test and simulation modules
    % =========================================================================
    
    p = struct(...
        'HR',     75, ...     % Heart Rate (beats/min)
        'T',      0.80, ...   % Cardiac cycle duration forcing window (s)
        'emax',   2.0, ...    % Maximum systolic left ventricular elastance (mmHg/mL)
        'emin',   0.06, ...   % Minimum diastolic left ventricular elastance (mmHg/mL)
        'v0',     10, ...     % Ventricular dead-volume intercept volume (mL)
        'Ca',     1.5, ...    % Systemic arterial compliance reservoir element (mL/mmHg)
        'Cv',     100, ...    % Systemic venous compliance preload reservoir (mL/mmHg)
        'R_av',   0.01, ...   % Aortic valve patent hydraulic resistance (mmHg*s/mL)
        'R_mv',   0.008 ...   % Mitral valve patent hydraulic resistance (mmHg*s/mL)
    );
end

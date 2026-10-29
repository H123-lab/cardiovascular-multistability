%% ========================================================================
%  EXPERIMENT: LOCAL ONE-AT-A-TIME (OAT) PARAMETER SWEEPS (Supp. Fig. S1)
%  =======================================================================
function run_parameter_sweeps()
    clear; clc; close all;
    addpath('../model');

    fprintf('--- Executing Local One-At-A-Time Sensitivity Sweeps ---\n');

    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.0;
    Y0 = [120; 95; 12];
    dt = 0.001; tsim = 100; % Reduced runtime for screening sweeps
    time = 0:dt:tsim; N = length(time);

    % Sweep Maximum Ventricular Contractility (Emax)
    Emax_range = 1.5:0.5:3.0;
    fprintf('\nSweeping Emax (Ventricular Contractility Limits):\n');
    
    for i = 1:length(Emax_range)
        p_sweep = p;
        p_sweep.Emax = Emax_range(i);
        
        % Fixed integration loop
        Y = zeros(3, N); Y(:, 1) = Y0;
        for k = 1:(N-1)
            k1 = cardiovascular_model(time(k), Y(:, k), Rsys, p_sweep);
            Y(:, k+1) = Y(:, k) + dt*k1; % Euler approximation for fast screening
        end
        metrics = derived_hemodynamics(Y, time, Rsys, p_sweep);
        fprintf('  Emax = %.2f mmHg/mL --> Steady-State MAP = %.2f mmHg\n', p_sweep.Emax, metrics.MAP);
    end
end

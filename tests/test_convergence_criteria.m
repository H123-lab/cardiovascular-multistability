%% ========================================================================
%  UNIT TEST: LIMIT-CYCLE STEADY-STATE CONVERGENCE TESTS (Supp. Table S4)
%  ========================================================================
function test_convergence_criteria()
    clear; clc;
    addpath('../model');
    addpath('../analysis');
    fprintf('--- Running Unit Test: Convergence Stability Thresholds ---\n');

    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.0; Y0 = [120; 95; 12];
    
    % Run short test duration simulation (30 seconds vs baseline 300)
    dt = 0.001; tsim = 30; time = 0:dt:tsim; N = length(time);
    Y = zeros(3, N); Y(:, 1) = Y0;
    
    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k), Y(:, k), Rsys, p);
        Y(:, k+1) = Y(:, k) + dt*k1;
    end

    % Parse the output using the automated state classifier script
    state_type = classify_operating_states(Y, time, dt);
    
    % Verify that transients decay and the system finds a stable orbit branch
    assert(~strcmp(state_type, 'Divergent/Unstable'), 'CRITICAL ERROR: System fails to converge within time window.');
    assert(contains(state_type, 'State A'), 'CRITICAL ERROR: State classification sorting mismatch.');

    fprintf('>> SUCCESS: Limit-cycle convergence criteria unit test passed.\n');
end

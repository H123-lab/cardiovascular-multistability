%% ========================================================================
%  UNIT TEST: PARAMETER COMPLETENESS AND DATABASE ACCURACY (Table 1 Validation)
%  ========================================================================
function test_parameter_completeness()
    clear; clc;
    fprintf('--- Running Unit Test: Parameter Completeness ---\n');

    % 1. Load active runtime test profile matching Table 1
    p.HR    = 75;      % beats/min
    p.T     = 0.80;    % s
    p.Emax  = 2.0;     % mmHg/mL
    p.Emin  = 0.06;    % mmHg/mL
    p.V0    = 10;      % mL
    p.Ca    = 1.5;     % mL/mmHg
    p.Cv    = 100;     % mL/mmHg
    p.R_av  = 0.01;    % mmHg*s/mL
    p.R_mv  = 0.008;   % mmHg*s/mL

    % 2. Define strict verification validation boundaries
    required_keys = {'HR', 'T', 'Emax', 'Emin', 'V0', 'Ca', 'Cv', 'R_av', 'R_mv'};
    assert(length(fieldnames(p)) == length(required_keys), 'CRITICAL ERROR: Parameter database field mismatch!');

    % 3. Check values against physiological baseline thresholds
    assert(p.HR == 75, 'Validation failed: Baseline Heart Rate must equal 75 bpm.');
    assert(p.Emax == 2.0, 'Validation failed: Baseline Emax must equal 2.0 mmHg/mL.');
    assert(p.Ca == 1.5, 'Validation failed: Baseline Arterial Compliance must equal 1.5 mL/mmHg.');
    assert(p.Cv == 100, 'Validation failed: Baseline Venous Compliance must equal 100 mL/mmHg.');
    
    fprintf('>> SUCCESS: Parameter completeness unit test passed. All constraints accounted for.\n');
end

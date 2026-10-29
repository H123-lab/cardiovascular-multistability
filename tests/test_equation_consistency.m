%% ========================================================================
%  UNIT TEST: CONSERVATION OF MASS AND VALVE SIGN CONVENTIONS
%  ========================================================================
function test_equation_consistency()
    clear; clc;
    addpath('../model');
    fprintf('--- Running Unit Test: Equation Consistency & Flow Rules ---\n');

    p = struct('HR',75, 'T',0.80, 'Emax',2.0, 'Emin',0.06, 'V0',10, 'Ca',1.5, 'Cv',100, 'R_av',0.01, 'R_mv',0.008);
    Rsys = 1.0;

    % Test Scenario A: Isovolumetric Contraction/Relaxation Phase (Both valves shut)
    % Left ventricular pressure balanced perfectly between reservoirs
    Y_isovolumetric = [100; 120; 10]; 
    dY_iso = cardiovascular_model(0.15, Y_isovolumetric, Rsys, p);
    
    % Net change in ventricular volume must equal zero when both valves are closed
    assert(abs(dY_iso(1)) < 1e-6, 'CRITICAL ERROR: Volume preservation violation during isovolumetric phase!');

    % Test Scenario B: Ideal Diode Valve Flow Sign Exclusions
    % Under reverse gradients (P_lv > P_v), mitral flow back into the venous pool must be 0
    P_lv = 140; P_a = 90; P_v = 10;
    [Q_mitral, Q_aortic, ~] = flow_and_valves(P_lv, P_a, P_v, Rsys, p);
    
    assert(Q_mitral == 0, 'CRITICAL ERROR: Mitral valve regurgitation detected under negative pressure gradients!');
    assert(Q_aortic > 0, 'CRITICAL ERROR: Aortic valve failed to open under forward ejection gradients!');

    fprintf('>> SUCCESS: Equation consistency unit test passed. Conservation equations verified.\n');
end

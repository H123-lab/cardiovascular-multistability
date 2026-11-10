function generate_audit_transcript()
    % =========================================================================
    % REAL MATHEMATICAL AUDIT TRANSCRIPT GENERATOR
    % Executes underlying verification routines and asserts explicit decisions
    % =========================================================================
    
    clear; clc;
    script_dir = fileparts(mfilename('fullpath'));
    
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    log_path = fullfile(processed_dir, 'audit_execution_transcript.log');
    fid = fopen(log_path, 'w');
    if fid == -1, error('Unable to create output transcript log file.'); end
    
    fprintf(fid, '=====================================================\n');
    fprintf(fid, '     DYNAMICAL SYSTEMS REPRODUCIBILITY AUDIT LOG      \n');
    fprintf(fid, '=====================================================\n');
    fprintf(fid, 'Execution Verification Runtime Check: %s\n', datestr(now));
    fprintf(fid, 'Numerical Core Setup: Central Shared rk4_step Function\n\n');
    
    try
        % Execute the underlying physics convergence validations
        [max_drift, delta_MAP_1ms] = verify_mathematical_physics();
        
        % ASSERTION 1: Strict Stressed Fluid Mass Conservation
        fprintf(fid, 'Evaluating Task 1 (Fluid Conservation Identity):\n');
        fprintf(fid, '  -> Calculated Absolute Fluid Vol Drift: %e mL\n', max_drift);
        if max_drift <= 1e-5
            fprintf(fid, '  -> CONCLUSION: [ PASSED ] Closed hydraulic boundaries remain invariant.\n\n');
        else
            fprintf(fid, '  -> CONCLUSION: [ FAILED ] Mass leakage detected in system matrix.\n\n');
            fclose(fid); error('Audit failed: Volume drift violation.');
        end
        
        % ASSERTION 2: Discretization Step Invariance Delta Bound
        fprintf(fid, 'Evaluating Task 2 (Temporal Step Convergence):\n');
        fprintf(fid, '  -> MAP Delta (dt=1ms vs fine reference dt=0.1ms): %e mmHg\n', delta_MAP_1ms);
        if delta_MAP_1ms <= 1e-3
            fprintf(fid, '  -> CONCLUSION: [ PASSED ] Solver truncation error has plateaued.\n\n');
        else
            fprintf(fid, '  -> CONCLUSION: [ FAILED ] Temporal discretization error detected.\n\n');
            fclose(fid); error('Audit failed: Solver truncation divergence.');
        end
        
        fprintf(fid, '=====================================================\n');
        fprintf(fid, '  ALL ASSERTIONS SECURED. REPRODUCIBILITY VERIFIED.  \n');
        fprintf(fid, '=====================================================\n');
        fclose(fid);
        fprintf('[SUCCESS] Real, assertion-checked audit transcript written cleanly to log.\n');
        
    catch ME
        fprintf(fid, '\n[CRITICAL ERROR] Audit execution terminated: %s\n', ME.message);
        fclose(fid);
        rethrow(ME);
    end
end



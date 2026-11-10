function verify_mathematical_physics()
    % This test suite directly runs calculations to prove numerical reliability
    p = struct('T',0.8,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    Rsys_test = 1.40; dt = 0.001; tsim = 300; time = 0:dt:tsim; N = length(time);
    
    Y = zeros(3, N); Y(:, 1) = [120; 95; 12];
    for k = 1:(N-1)
        k1 = cardiovascular_model(time(k), Y(:,k), Rsys_test, p);
        k2 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k1, Rsys_test, p);
        k3 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k2, Rsys_test, p);
        k4 = cardiovascular_model(time(k)+dt, Y(:,k)+dt*k3, Rsys_test, p);
        Y(:, k+1) = Y(:, k) + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
    
    % Task 1 Check: Mass Conservation Tracker at every integration step
    V_total_states = Y(1, :) + (p.Ca * Y(2, :)) + (p.Cv * Y(3, :));
    initial_mass = V_total_states(1);
    max_drift = max(abs(V_total_states - initial_mass));
    relative_drift = max_drift / initial_mass;
    
    % Task 3 Check: Periodic Response cycle-to-cycle tolerance match
    cycle_steps = int32(p.T/dt);
    cycle_n_minus_1 = Y(:, (N - 2*cycle_steps):(N - cycle_steps));
    cycle_n = Y(:, (N - cycle_steps):N-1);
    max_periodic_variance = max(max(abs(cycle_n - cycle_n_minus_1)));
    
    fprintf('=====================================================\n');
    fprintf('           CORE MATHEMATICAL AUDIT RESULTS           \n');
    fprintf('=====================================================\n');
    fprintf('Task 1: Initial Stressed Volume Mass: %.4f mL\n', initial_mass);
    fprintf('Task 1: Maximum Measured Absolute Volume Drift: %e mL\n', max_drift);
    fprintf('Task 1: Relative Volume Drift Status: %e\n', relative_drift);
    fprintf('Task 3: Cycle-to-Cycle Periodic Variance: %e\n', max_periodic_variance);
    fprintf('=====================================================\n');
end








    
    

  

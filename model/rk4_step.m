function x_next = rk4_step(t, x, dt, Rsys, p)
    % =========================================================================
    % CENTRAL REUSABLE EXPLICIT FOURTH-ORDER RUNGE-KUTTA INTEGRATION SOLVER
    % Evaluates four distinct vector slope projections over interval step dt
    % =========================================================================
    
    k1 = cardiovascular_model(t,             x,             Rsys, p);
    k2 = cardiovascular_model(t + 0.5 * dt,  x + 0.5*dt*k1, Rsys, p);
    k3 = cardiovascular_model(t + 0.5 * dt,  x + 0.5*dt*k2, Rsys, p);
    k4 = cardiovascular_model(t + dt,        x + dt*k3,     Rsys, p);
    
    x_next = x + (dt / 6) * (k1 + 2*k2 + 2*k3 + k4);
end

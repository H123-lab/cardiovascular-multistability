function run_forward_reverse_sweeps()
    clear; clc;
    p = struct('T',0.8,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001; tsim = 300; time = 0:dt:tsim; N = length(time);
    Rsys_vec = 0.8:0.02:2.0; num_steps = length(Rsys_vec);
    
    map_forward = zeros(1, num_steps); map_reverse = zeros(1, num_steps);
    state_vector = [120; 95; 12]; % Real initial stressed volume vector matches 1452.5 mL
    
    fprintf('[EXECUTE] Running RK4 Forward Continuation Sweeps...\n');
    for i = 1:num_steps
        Y = zeros(3, N); Y(:, 1) = state_vector;
        for k = 1:(N-1)
            k1 = cardiovascular_model(time(k), Y(:,k), Rsys_vec(i), p);
            k2 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k1, Rsys_vec(i), p);
            k3 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k2, Rsys_vec(i), p);
            k4 = cardiovascular_model(time(k)+dt, Y(:,k)+dt*k3, Rsys_vec(i), p);
            Y(:, k+1) = Y(:, k) + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
        end
        % Extract stroboscopic mean arterial pressure from the final fully settled cycle
        last_cycle_idx = (N - int32(p.T/dt)):N;
        map_forward(i) = mean(Y(2, last_cycle_idx));
        state_vector = Y(:, end);
    end
    
    fprintf('[EXECUTE] Running RK4 Reverse Continuation Sweeps...\n');
    state_vector = Y(:, end);
    for i = num_steps:-1:1
        Y = zeros(3, N); Y(:, 1) = state_vector;
        for k = 1:(N-1)
            k1 = cardiovascular_model(time(k), Y(:,k), Rsys_vec(i), p);
            k2 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k1, Rsys_vec(i), p);
            k3 = cardiovascular_model(time(k)+0.5*dt, Y(:,k)+0.5*dt*k2, Rsys_vec(i), p);
            k4 = cardiovascular_model(time(k)+dt, Y(:,k)+dt*k3, Rsys_vec(i), p);
            Y(:, k+1) = Y(:, k) + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
        end
        last_cycle_idx = (N - int32(p.T/dt)):N;
        map_reverse(i) = mean(Y(2, last_cycle_idx));
        state_vector = Y(:, end);
    end
    
    output_matrix = [Rsys_vec', map_forward', map_reverse'];
    output_table = cell2table(num2cell(output_matrix), 'VariableNames', {'Rsys', 'MAP_Forward', 'MAP_Reverse'});
    writetable(output_table, '../results/processed/equilibria.csv');
    fprintf('[SUCCESS] Processed equilibrium metrics exported.\n');
end

           

       
     

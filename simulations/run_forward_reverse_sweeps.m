function run_forward_reverse_sweeps()
    % =========================================================================
    % HYSTERESIS SWEEP TRACKING ENGINE WITH REUSABLE RK4 STEPPER
    % Calculates MAP via Numerical Integration over exactly one cycle
    % =========================================================================
    
    clear; clc; close all;
    
    % Establish directory paths dynamically relative to script file execution location
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, '../model'));
    
    p = struct('T',0.80,'emax',2.0,'emin',0.06,'v0',10,'Ca',1.5,'Cv',100,'R_av',0.01,'R_mv',0.008);
    dt = 0.001; tsim = 300; time = 0:dt:tsim; N = length(time);
    cycle_steps = int32(p.T/dt); % Exactly 800 steps for a 0.8s cardiac cycle
    
    Rsys_vec = 0.8:0.02:2.0; 
    num_steps = length(Rsys_vec);
    map_forward = zeros(1, num_steps);
    map_reverse = zeros(1, num_steps);
    
    state_vector = [120; 95; 12]; % Initial condition state matching baseline capacity
    
    fprintf('[EXECUTE] Commencing Reusable Solver Forward Continuation Loop...\n');
    for i = 1:num_steps
        Y = zeros(3, N);
        Y(:, 1) = state_vector;
        
        for k = 1:(N-1)
            Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys_vec(i), p);
        end
        
        % Extract exactly one complete final cycle index segment (length 801)
        last_cycle_idx = (N - cycle_steps):N;
        t_cycle = time(last_cycle_idx);
        Pa_cycle = Y(2, last_cycle_idx);
        
        % Mathematically rigorous Time-Average Mean Arterial Pressure calculation
        map_forward(i) = trapz(t_cycle, Pa_cycle) / p.T;
        state_vector = Y(:, end);
    end
    
    fprintf('[EXECUTE] Commencing Reusable Solver Reverse Continuation Loop...\n');
    state_vector = Y(:, end); 
    
    for i = num_steps:-1:1
        Y = zeros(3, N);
        Y(:, 1) = state_vector;
        
        for k = 1:(N-1)
            Y(:, k+1) = rk4_step(time(k), Y(:, k), dt, Rsys_vec(i), p);
        end
        
        last_cycle_idx = (N - cycle_steps):N;
        t_cycle = time(last_cycle_idx);
        Pa_cycle = Y(2, last_cycle_idx);
        
        map_reverse(i) = trapz(t_cycle, Pa_cycle) / p.T;
        state_vector = Y(:, end);
    end
    
    % Save outputs relative to repository root
    processed_dir = fullfile(script_dir, '../results/processed');
    if ~exist(processed_dir, 'dir'), mkdir(processed_dir); end
    
    output_matrix = [Rsys_vec', map_forward', map_reverse'];
    output_table = cell2table(num2cell(output_matrix), 'VariableNames', {'Rsys', 'MAP_Forward', 'MAP_Reverse'});
    writetable(output_table, fullfile(processed_dir, 'equilibria.csv'));
    fprintf('[SUCCESS] Processed equilibrium parameters written cleanly to data sheets.\n');
end



 

           

       
     

function state_type = classify_operating_states(state_history, time_array, dt)
    % CLASSIFY_OPERATING_STATES Evaluates limit-cycle convergence metrics
    % Categorizes states by Mean Arterial Pressure (MAP) thresholds.

    pacing_period = 0.80; % Target cardiac cycle period length (s)
    steps_per_cycle = round(pacing_period / dt);
    
    if size(state_history, 2) < 2 * steps_per_cycle
        state_type = 'Transient/Incomplete';
        return;
    end

    % Harvest terminal consecutive cardiac cycles
    cycle_2 = state_history(:, end - steps_per_cycle + 1 : end);
    cycle_1 = state_history(:, end - 2*steps_per_cycle + 1 : end - steps_per_cycle);

    % Verify cycle-to-cycle convergence tolerance (Strict < 0.1% check)
    cycle_variance = mean((cycle_2(2,:) - cycle_1(2,:)).^2);
    
    if cycle_variance > 1e-3
        state_type = 'Divergent/Unstable';
    else
        mean_MAP = mean(cycle_2(2, :));
        if mean_MAP < 110.0
            state_type = 'State A (Normal/Low Pressure Branch)';
        else
            state_type = 'State B (Fragile/High Pressure Branch)';
        end
    end
end

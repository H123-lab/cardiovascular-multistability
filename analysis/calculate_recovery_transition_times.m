function [outcome, action_time] = calculate_recovery_transition_times(time_array, MAP_history, baseline_MAP, transition_MAP, dt)
    % CALCULATE_RECOVERY_TRANSITION_TIMES Tracks post-perturbation response metrics
    % Identifies recovery durations versus irreversible state-switching failures.

    stress_index = round(0.10 * length(time_array)); % Perturbation point (10% timeline marker)
    post_stress_MAP = MAP_history(stress_index:end);
    post_stress_time = time_array(stress_index:end);

    % Find when the system settles back into a stable state band
    convergence_tolerance = 0.5; % Settling window boundary (mmHg)
    
    is_recovering = abs(post_stress_MAP(end) - baseline_MAP) < convergence_tolerance;
    is_switching  = abs(post_stress_MAP(end) - transition_MAP) < convergence_tolerance;

    if is_recovering
        outcome = 'Resilient Recovery';
        % Calculate recovery time (when it enters and stays within tolerance band)
        steady_indices = find(abs(post_stress_MAP - baseline_MAP) > convergence_tolerance);
        if isempty(steady_indices)
            action_time = 0;
        else
            action_time = post_stress_time(steady_indices(end)) - post_stress_time(1);
        end
    elseif is_switching
        outcome = 'Attractor Transition State Failure';
        % Calculate transition time (when it crosses mid-point threshold)
        midpoint_threshold = (baseline_MAP + transition_MAP) / 2;
        crossing_idx = find(post_stress_MAP >= midpoint_threshold, 1);
        if isempty(crossing_idx)
            action_time = NaN;
        else
            action_time = post_stress_time(crossing_idx) - post_stress_time(1);
        end
    else
        outcome = 'Unconverged/Indeterminate';
        action_time = NaN;
    end
end

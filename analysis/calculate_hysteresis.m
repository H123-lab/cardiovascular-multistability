function [loop_detected, lower_bound, upper_bound, loop_width] = calculate_hysteresis(Rsys_vec, map_forward, map_reverse)
    % CALCULATE_HYSTERESIS Identifies bistable parameter splitting
    % Quantifies the precise separation window between continuation loops.

    branch_deviation = abs(map_forward - map_reverse);
    bistable_indices = find(branch_deviation > 1.5); % Threshold mapping divergence (mmHg)

    if isempty(bistable_indices)
        loop_detected = false;
        lower_bound = NaN; upper_bound = NaN; loop_width = 0;
        fprintf('No bistable hysteresis regime identified across selected coordinates.\n');
    else
        loop_detected = true;
        lower_bound = Rsys_vec(bistable_indices(1));
        upper_bound = Rsys_vec(bistable_indices(end));
        loop_width = upper_bound - lower_bound;
        
        fprintf('=== HYSTERESIS TRANSITION METRICS ===\n');
        fprintf('Bistable Regime Detected: Yes\n');
        fprintf('Lower Saddle-Node Limit:  %.2f mmHg*s/mL\n', lower_bound);
        fprintf('Upper Saddle-Node Limit:  %.2f mmHg*s/mL\n', upper_bound);
        fprintf('Hysteresis Loop Width:    %.2f mmHg*s/mL\n', loop_width);
        fprintf('=====================================\n');
    end
end

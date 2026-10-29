function basin_summary = analyze_attractor_basins(grid_V_lv, grid_P_a, grid_outcomes)
    % ANALYZE_ATTRACTOR_BASINS Quantifies structural basin volumes
    % Calculates capture probability densities over initialization sweeps.

    total_runs = length(grid_outcomes);
    state_A_count = sum(grid_outcomes < 110.0); % Low Pressure branch branch selector
    state_B_count = total_runs - state_A_count;  % High Pressure branch branch selector

    basin_summary.total_trajectories = total_runs;
    basin_summary.probability_A = state_A_count / total_runs;
    basin_summary.probability_B = state_B_count / total_runs;
    basin_summary.volumetric_ratio_A_B = state_A_count / max(1, state_B_count);
    
    fprintf('=== ATTRACTOR BASIN QUANTIFICATION ===\n');
    fprintf('Total Initialization Coordinates: %d\n', total_runs);
    fprintf('State Basin A Capture Density:     %.2f%%\n', basin_summary.probability_A * 100);
    fprintf('State Basin B Capture Density:     %.2f%%\n', basin_summary.probability_B * 100);
    fprintf('Basin Dominance Ratio (A/B):      %.2f\n', basin_summary.volumetric_ratio_A_B);
    fprintf('======================================\n');
end

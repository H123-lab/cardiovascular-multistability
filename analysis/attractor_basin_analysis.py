"""
ANALYSIS MODULE: ATTRACTOR BASIN GEOMETRY ANALYSIS
Maps initialization state arrays to quantify basin volumes and separatrix limits.
"""

import numpy as np

def calculate_basin_densities(grid_results):
    """
    Parses a dictionary matrix of converged initial condition seeds to calculate
    the geometric size and capture probability density of State Branch A vs. State Branch B.
    grid_results: list of dict items containing {'seed': [V_lv, P_a], 'converged_MAP': val}
    """
    total_seeds = len(grid_results)
    if total_seeds == 0:
        return {"density_A": 0.0, "density_B": 0.0}
        
    state_a_counts = 0
    state_b_counts = 0
    
    for run in grid_results:
        # Separate outcomes based on target limit cycle blood pressures
        if run["converged_MAP"] < 110.0:
            state_a_counts += 1 # Low-Pressure branch attractor destination
        else:
            state_b_counts += 1 # High-Pressure branch attractor destination
            
    return {
        "total_evaluated_trajectories": total_seeds,
        "basin_A_capture_probability": state_a_counts / total_seeds,
        "basin_B_capture_probability": state_b_counts / total_seeds,
        "geometric_dominance_ratio": state_a_counts / max(1, state_b_counts)
    }

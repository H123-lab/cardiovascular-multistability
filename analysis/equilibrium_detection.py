"""
ANALYSIS MODULE: AUTOMATED EQUILIBRIUM DETECTION
Identifies and characterizes stable limit cycles versus unstable transition vectors.
"""

import numpy as np

def detect_limit_cycle_stability(history, dt, cycle_period):
    """
    Evaluates cycle-to-cycle convergence using mean Euclidean distance tracking.
    Confirms numerical stability of the final attractor limit orbit.
    """
    steps_per_cycle = int(cycle_period / dt)
    if history.shape[1] < 2 * steps_per_cycle:
        return {"stable": False, "reason": "Insufficient timeline data"}
        
    # Extract last two consecutive cardiac cycles
    cycle_2 = history[:, -steps_per_cycle:]
    cycle_1 = history[:, -2*steps_per_cycle:-steps_per_cycle]
    
    # Calculate Mean Squared Error (MSE) deviation between consecutive trajectories
    trajectory_variance = np.mean((cycle_2 - cycle_1) ** 2)
    
    # Check if cycle variations fall below the strict 0.1% convergence tolerance
    is_converged = trajectory_variance < 1e-4
    
    return {
        "stable": is_converged,
        "residual_variance": trajectory_variance,
        "mean_MAP": np.mean(cycle_2[1, :]),
        "mean_EDV": np.max(cycle_2[0, :]),
        "mean_ESV": np.min(cycle_2[0, :])
    }

"""
Description: Post-processing mathematical helper functions to calculate cycle steady-state 
             hemodynamic metrics and mean arterial pressure tracking profiles.
"""

import numpy as np

def calculate_cycle_metrics(history, time_array, p):
    """
    Parses the terminal 5% window of the transient timeline to extract stable, 
    converged limit-cycle mean performance indices avoiding transient tracking artifacts.
    """
    num_steps = len(time_array)
    start_idx = int(0.95 * num_steps)
    
    # Extract structural state tracks from slicing
    arterial_pressure_track = history[1, start_idx:]
    
    # Calculate Mean Arterial Pressure (MAP)
    mean_arterial_pressure = np.mean(arterial_pressure_track)
    
    return {
        "MAP": mean_arterial_pressure,
        "steady_state_slice_V_lv": history[0, start_idx:],
        "steady_state_slice_P_a": arterial_pressure_track,
        "steady_state_slice_P_v": history[2, start_idx:]
    }

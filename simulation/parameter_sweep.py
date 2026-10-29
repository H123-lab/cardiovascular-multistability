"""
EXPERIMENT: LOCAL ONE-AT-A-TIME (OAT) SENSITIVITY SWEEPS
Sweeps model constraints to evaluate baseline configuration sensitivity.
"""

import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def run_sensitivity_sweeps():
    print("--- Executing Local One-At-A-Time Sensitivity Sweeps ---")
    
    p = get_baseline_parameters()
    Rsys_baseline = 1.0
    initial_states = np.array([120.0, 95.0, 12.0])
    
    # Define an evaluation array to sweep Left Ventricular Contractility (Emax bounds)
    emax_sweep_bounds = np.array([1.5, 2.0, 2.5, 3.0])
    
    print("\nSweeping Emax (Ventricular Contractility Thresholds):")
    for custom_emax in emax_sweep_bounds:
        # Create an independent local parameter instance for isolation
        local_p = p.copy()
        local_p["Emax"] = custom_emax
        
        # Execute integration
        history, time_array = run_rk4_integration(initial_states, Rsys_baseline, local_p)
        metrics = calculate_cycle_metrics(history, time_array, local_p)
        
        print(f"  Emax = {custom_emax:.2f} mmHg/mL --> Calculated Steady-State MAP = {metrics['MAP']:.2f} mmHg")

if __name__ == "__main__":
    run_sensitivity_sweeps()

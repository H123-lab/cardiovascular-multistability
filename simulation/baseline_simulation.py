"""
EXPERIMENT: RUN BASELINE REFERENCE SIMULATION & HE MODYNAMIC VALIDATION (Table 3)
Tracks the model performance at normal healthy resting configurations.
"""

import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def run_baseline_experiment():
    print("--- Executing Baseline Reference Simulation ---")
    
    # 1. Load baseline parameters database structure
    p = get_baseline_parameters()
    Rsys_baseline = 1.0  # Normal systemic afterload resistance
    
    # 2. Define healthy baseline state vectors initialization [V_lv, P_a, P_v]
    initial_states = np.array([120.0, 95.0, 12.0])
    
    # 3. Execute fixed-step fourth-order Runge-Kutta numerical solver
    history, time_array = run_rk4_integration(initial_states, Rsys_baseline, p)
    
    # 4. Extract steady-state limit-cycle average metrics
    metrics = calculate_cycle_metrics(history, time_array, p)
    
    print("\n=== BASELINE HEMODYNAMIC VERIFICATION ===")
    print(f"Mean Arterial Pressure (MAP): {metrics['MAP']:.2f} mmHg (Target: 95.0)")
    print(f"Terminal Ventricular Vol Maximum: {np.max(metrics['steady_state_slice_V_lv']):.2f} mL")
    print(f"Terminal Venous Pool Pressure Mean: {np.mean(metrics['steady_state_slice_P_v']):.2f} mmHg")
    print("=========================================")

if __name__ == "__main__":
    run_baseline_experiment()

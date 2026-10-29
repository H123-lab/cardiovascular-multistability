"""
EXPERIMENT: INITIAL CONDITIONS GRID SEARCH & ATTRACTOR BASIN MAPPING (Supp. Fig. S3)
Maps out attractor destination boundaries across various initialization fields.
"""

import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def evaluate_initialization_grid():
    print("--- Executing Attractor Basin Initialization Grid Search ---")
    p = get_baseline_parameters()
    Rsys_bistable = 1.40  # Lock within the verified bistable interval
    
    # Grid arrays sampling alternative coordinate origins
    sampled_V_lv_seeds = np.array([45.0, 120.0])   # Low Volume vs High Volume initializations
    sampled_P_a_seeds  = np.array([160.0, 90.0])   # High Pressure vs Low Pressure initializations
    
    print("\nTracking trajectory endpoints across divergent state grid origins:")
    for i in range(len(sampled_V_lv_seeds)):
        Y0 = np.array([sampled_V_lv_seeds[i], sampled_P_a_seeds[i], 10.0])
        
        history, time_array = run_rk4_integration(Y0, Rsys_bistable, p)
        metrics = calculate_cycle_metrics(history, time_array, p)
        
        print(f"  Initial State Seed vector [{Y0[0]} mL; {Y0[1]} mmHg] --> Settled on Stable MAP: {metrics['MAP']:.2f} mmHg")

if __name__ == "__main__":
    evaluate_initialization_grid()

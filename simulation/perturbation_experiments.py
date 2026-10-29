"""
EXPERIMENT: TRANSIENT VOLUMETRIC PERTURBATIONS & RESILIENCE TRAJECTORIES (Fig. 5D-E)
Injects blood volume stressors inside the bistable parameter zone.
"""

import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.equations import compute_derivatives

def run_perturbed_integration(initial_states, Rsys, p, stress_timestamp, delta_ratio):
    """
    Custom integration solver loop that introduces a sudden volume stressor at a specific timestamp.
    """
    dt = p["dt"]
    tsim = p["tsim"]
    time_array = np.arange(0.0, tsim + dt, dt)
    num_steps = len(time_array)
    
    history = np.zeros((3, num_steps))
    history[:, 0] = initial_states
    
    stress_index = int(stress_timestamp / dt)
    
    for k in range(num_steps - 1):
        t = time_array[k]
        yk = history[:, k].copy()
        
        # Inject the acute volumetric perturbation spike (e.g., 10% volume impact)
        if k == stress_index:
            yk[0] = yk[0] * (1.0 + delta_ratio)
            
        k1 = compute_derivatives(t,           yk,             Rsys, p)
        k2 = compute_derivatives(t + 0.5*dt,  yk + 0.5*dt*k1, Rsys, p)
        k3 = compute_derivatives(t + 0.5*dt,  yk + 0.5*dt*k2, Rsys, p)
        k4 = compute_derivatives(t + dt,      yk + dt*k3,      Rsys, p)
        
        history[:, k+1] = yk + (dt / 6.0) * (k1 + 2.0*k2 + 2.0*k3 + k4)
        
    return history, time_array

def run_perturbation_test():
    print("--- Executing Transient Volumetric Perturbation Stress Test ---")
    p = get_baseline_parameters()
    
    # Set systemic vascular resistance within the coexisting bistable zone
    Rsys_bistable = 1.40
    
    # Initial vector [V_lv, P_a, P_v]
    system_a_initial = np.array([120.0, 95.0, 12.0])
    
    # Execute integration with a 10% fluid volume change injected at t = 30 seconds
    history, time_array = run_perturbed_integration(system_a_initial, Rsys_bistable, p, stress_timestamp=30.0, delta_ratio=0.10)
    
    # Calculate performance over final cycle
    start_idx = int(0.95 * len(time_array))
    final_map = np.mean(history[1, start_idx:])
    print(f"Post-perturbation final stable MAP configuration settles at: {final_map:.2f} mmHg")

if __name__ == "__main__":
    run_perturbation_test()

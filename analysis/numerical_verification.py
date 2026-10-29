"""
ANALYSIS MODULE: NUMERICAL ACCURACY AND VERIFICATION LOGS
Runs step refinement checks to confirm that bistability is not an integration artifact.
"""

import numpy as np

def verify_discretization_independence(step_sizes, simulation_launcher, parameter_set, Rsys_test=1.40):
    """
    Compares terminal outputs across multiple independent step-size increments (dt).
    Verifies numerical invariant boundaries under explicit fourth-order Runge-Kutta execution.
    """
    verification_log = {}
    base_states = np.array([120.0, 95.0, 12.0])
    
    print("Executing Temporal Step Refinement Matrices...")
    for dt in step_sizes:
        # Create unique simulation configurations matching local time metrics
        local_p = parameter_set.copy()
        local_p["dt"] = dt
        
        # Execute run
        history, time_array = simulation_launcher(base_states, Rsys_test, local_p)
        final_map = np.mean(history[1, -int(10.0/dt):]) # Harvest final 10 seconds average
        
        verification_log[f"dt_{dt}"] = final_map
        print(f"  Step Size dt = {dt:.4f} s --> Computed Mean Arterial Pressure = {final_map:.4f} mmHg")
        
    # Quantify max deviation between coarsest and finest step benchmarks
    max_step_error = np.abs(verification_log[f"dt_{step_sizes[0]}"] - verification_log[f"dt_{step_sizes[-1]}"])
    
    return {
        "step_independence_verified": max_step_error < 1e-2,
        "maximum_discretization_variance": max_step_error,
        "accuracy_logs": verification_log
    }

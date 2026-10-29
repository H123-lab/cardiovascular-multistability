"""
Description: Explicit fourth-order Runge-Kutta numerical integration solver routine.
"""

import numpy as np
from src.model.equations import compute_derivatives

def run_rk4_integration(initial_states, Rsys, p):
    """
    Runs fixed-step fourth-order Runge-Kutta evaluation over the configured timeline.
    initial_states = [V_lv_0, P_a_0, P_v_0]
    """
    dt = p["dt"]
    tsim = p["tsim"]
    time_array = np.arange(0.0, tsim + dt, dt)
    num_steps = len(time_array)
    
    # Preallocate trajectory arrays
    history = np.zeros((3, num_steps))
    history[:, 0] = initial_states
    
    for k in range(num_steps - 1):
        t = time_array[k]
        yk = history[:, k]
        
        # Calculate the 4 standard vector slopes
        k1 = compute_derivatives(t,           yk,             Rsys, p)
        k2 = compute_derivatives(t + 0.5*dt,  yk + 0.5*dt*k1, Rsys, p)
        k3 = compute_derivatives(t + 0.5*dt,  yk + 0.5*dt*k2, Rsys, p)
        k4 = compute_derivatives(t + dt,      yk + dt*k3,      Rsys, p)
        
        # Final weighted displacement update statement
        history[:, k+1] = yk + (dt / 6.0) * (k1 + 2.0*k2 + 2.0*k3 + k4)
        
    return history, time_array

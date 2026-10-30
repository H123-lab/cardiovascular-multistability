"""
UNIT TEST: CONSERVATION OF MASS AND VALVE SIGN CONVENTIONS
Validates the structural physics of the non-linear ordinary differential equations.
"""

import numpy as np
import pytest
from src.model.parameters import get_baseline_parameters
from src.model.equations import compute_derivatives

def test_mass_conservation_identity():
    """
    Verifies that the sum of the derivatives cancels out identically to zero,
    proving absolute closed-loop mass preservation under arbitrary states.
    """
    p = get_baseline_parameters()
    Rsys_arbitrary = 1.40
    
    # Generate an arbitrary testing state vector: [V_lv, P_a, P_v]
    test_states = np.array([100.0, 120.0, 10.0])
    
    # Compute system derivatives array vector
    derivs = compute_derivatives(0.15, test_states, Rsys_arbitrary, p)
    
    # Extract scalar derivatives using clean array indexing
    dV_lv_dt = derivs[0]
    dP_a_dt  = derivs[1]
    dP_v_dt  = derivs[2]
    
    # Calculate scalar sum: dVtot/dt = dV_lv/dt + Ca*dP_a/dt + Cv*dP_v/dt
    global_volume_derivative = dV_lv_dt + (p["Ca"] * dP_a_dt) + (p["Cv"] * dP_v_dt)
    
    # Assert zero fluid drift down to floating-point precision bounds
    assert abs(global_volume_derivative)  P_v)
    high_systolic_states = np.array([110.0, 90.0, 12.0])
    
    # Run a localized derivative evaluation step
    derivs = compute_derivatives(0.20, high_systolic_states, Rsys, p)
    
    # During ventricular contraction, volume can only decrease or stay constant (dV_lv/dt <= 0)
    dV_lv_dt = derivs[0]
    assert dV_lv_dt <= 0.0, "Mitral valve leakage or volume preservation error detected!"





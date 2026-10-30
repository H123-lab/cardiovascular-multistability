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
    
    # Compute system derivatives at an arbitrary time point
    derivs = compute_derivatives(0.15, test_states, Rsys_arbitrary, p)
    
    # Calculate scalar sum: dVtot/dt = dV_lv/dt + Ca*dP_a/dt + Cv*dP_v/dt
    global_volume_derivative = derivs[0] + (p["Ca"] * derivs[1]) + (p["Cv"] * derivs[2])
    
    # Assert zero fluid drift down to floating-point precision bounds
    assert abs(global_volume_derivative)  P_v)
    high_systolic_states = np.array([110.0, 90.0, 12.0])
    
    # Run a localized derivative evaluation step
    derivs = compute_derivatives(0.20, high_systolic_states, Rsys, p)
    
    # Under high systolic load, filling must stop (dV_lv/dt should be negative during ejection)
    assert derivs[0] <= 0.0, "Mitral valve leakage or volume preservation error detected!"



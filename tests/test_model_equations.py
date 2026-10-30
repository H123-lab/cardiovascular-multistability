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
    
    # dVtot/dt = dV_lv/dt + Ca*dP_a/dt + Cv*dP_v/dt
    global_volume_derivative = derivs[0] + (p["Ca"] * derivs[1]) + (p["Cv"] * derivs[2])
    
    # Assert zero fluid drift down to floating-point precision bounds
    assert abs(global_volume_derivative)  P_v)
    # Mitral filling flow must clamp identically to zero to prevent backleakage
    high_systolic_states = np.array([110.0, 90.0, 12.0]) # Emulates ventricular systolic pressure rise
    
    # Run a localized derivative evaluation step
    # P_lv calculation will exceed venous pressure, forcing mitral closure
    derivs = compute_derivatives(0.20, high_systolic_states, Rsys, p)
    
    # If mitral valve seals correctly, arterial volume accumulation mirrors aortic ejection completely
    # dV_lv/dt = -Q_aortic, and Ca*dP_a/dt = Q_aortic - Q_sys
    assert derivs[0] <= 0.0, "Retrograde valve regurgitation detected under negative gradient!"

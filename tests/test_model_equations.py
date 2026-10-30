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
    assert abs(global_volume_derivative) < 1e-10, f"Mass conservation identity drifted: {global_volume_derivative}"

def test_valve_diode_exclusions():
    """
    Tests ideal diode sign exclusions to confirm that retrograde backflow is zero
    under zero gradient boundary conditions.
    """
    p = get_baseline_parameters()
    Rsys = 1.0
    
    # Initialize a perfectly balanced equilibrium state where all pressures align
    # This isolates valve boundaries, testing that flow cannot manifest without gradients
    balanced_states = np.array([10.0, 0.0, 0.0]) # Forces P_lv = 0, P_a = 0, P_v = 0
    
    # Run derivative evaluation
    derivs = compute_derivatives(0.50, balanced_states, Rsys, p)
    
    # Under zero mechanical pressure gradients, filling and ejection must equal zero
    dV_lv_dt = derivs[0]
    assert abs(dV_lv_dt) < 1e-12, f"Valve diode leakage identified: {dV_lv_dt}"


    
 





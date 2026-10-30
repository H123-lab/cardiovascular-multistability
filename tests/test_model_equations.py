"""
UNIT TEST: CONSERVATION OF MASS AND VALVE SIGN CONVENTIONS
Validates the structural physics of the non-linear ordinary differential equations.
"""
import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.equations import compute_derivatives

def test_mass_conservation_identity():
    p = get_baseline_parameters()
    Rsys_arbitrary = 1.40
    test_states = np.array([100.0, 120.0, 10.0])
    derivs = compute_derivatives(0.15, test_states, Rsys_arbitrary, p)
    
    global_volume_derivative = derivs[0] + (p["Ca"] * derivs[1]) + (p["Cv"] * derivs[2])
    assert abs(global_volume_derivative) < 1e-6, f"Mass drift: {global_volume_derivative}"

def test_valve_diode_exclusions():
    p = get_baseline_parameters()
    test_states = np.array([10.0, 0.0, 0.0]) # Forces P_lv = 0, P_a = 0, P_v = 0
    derivs = compute_derivatives(0.50, test_states, 1.0, p)
    assert abs(derivs[0]) < 1e-6, f"Mitral leak: {derivs[0]}"

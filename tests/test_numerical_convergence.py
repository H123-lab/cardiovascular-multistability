"""
UNIT TEST: TIMESTEP DISCRETIZATION CONVERGENCE TESTS
Confirms numerical step-independence down to ultra-fine criteria margins.
"""

import numpy as np
import pytest
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def test_temporal_discretization_error_bounds():
    """
    Compares terminal outputs across multiple independent step-size increments (dt).
    Verifies that discretization error deviations are bounded below 0.05 mmHg.
    """
    p = get_baseline_parameters()
    Rsys_test = 1.0
    base_seed = np.array([120.0, 95.0, 12.0])
    
    # Profile A: Coarse tracking resolution (dt = 5 ms)
    p_coarse = p.copy()
    p_coarse["dt"] = 0.005
    history_c, time_c = run_rk4_integration(base_seed, Rsys_test, p_coarse)
    metrics_coarse = calculate_cycle_metrics(history_c, time_c, p_coarse)
    
    # Profile B: Baseline fine precision tracking resolution (dt = 1 ms)
    p_fine = p.copy()
    p_fine["dt"] = 0.001
    history_f, time_f = run_rk4_integration(base_seed, Rsys_test, p_fine)
    metrics_fine = calculate_cycle_metrics(history_f, time_f, p_fine)
    
    # Quantify step refinement numerical variance deviation
    discretization_error = abs(metrics_coarse["MAP"] - metrics_fine["MAP"])
    
    # Assert convergence step-independence to rule out code execution anomalies
    assert discretization_error < 0.05, f"Step size dependency error: {discretization_error} mmHg"
    print(f"\nDiscretization refinement convergence verified. Delta error: {discretization_error:.6f} mmHg")

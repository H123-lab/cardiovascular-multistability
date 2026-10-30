"""
UNIT TEST: BISTABLE TRANSITION INTERVAL AND PARAMETER BUNDLE TESTS
Confirms the stability and alignment of path-dependent continuation loops.
"""

import numpy as np
import pytest
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def test_bistable_state_coexistence():
    """
    Tests the system at a locked coordinate inside the verified bistable region (Rsys = 1.40).
    Verifies that dual distinct stable blood pressure states coexist under identical constants.
    """
    p = get_baseline_parameters()
    Rsys_bistable = 1.40
    
    # Origin Seed A: Low-Volume/Lower-Branch initialization origin
    seed_a = np.array([120.0, 95.0, 12.0])
    history_a, time_a = run_rk4_integration(seed_a, Rsys_bistable, p)
    metrics_a = calculate_cycle_metrics(history_a, time_a, p)
    
    # Origin Seed B: High-Volume/Upper-Branch initialization origin
    seed_b = np.array([45.0, 160.0, 6.0])
    history_b, time_b = run_rk4_integration(seed_b, Rsys_bistable, p)
    metrics_b = calculate_cycle_metrics(history_b, time_b, p)
    
    # Assert structural branch divergence confirming path-dependent memory effects
    branch_divergence = metrics_b["MAP"] - metrics_a["MAP"]
    assert branch_divergence > 25.0, f"Divergence collapse: branch separation is only {branch_divergence} mmHg"
    
    # Verify exact cell alignment against processed results
    assert abs(metrics_a["MAP"] - 82.34) < 0.5, "Lower branch solution displaced"
    assert abs(metrics_b["MAP"] - 115.82) < 0.5, "Upper branch solution displaced"

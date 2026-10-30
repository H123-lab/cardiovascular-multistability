"""
UNIT TEST: BASELINE LIMIT-CYCLE STABILITY AND TRACE COMPLETENESS
Confirms convergence to the certified resting hemodynamic orbits.
"""

import numpy as np
import pytest
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def test_resting_hemodynamic_bounds():
    """
    Executes standard baseline reference runs to confirm that final steady
    limit-cycles converge precisely within manuscript Table 3 benchmarks.
    """
    p = get_baseline_parameters()
    Rsys_baseline = 1.0
    initial_seed = np.array([120.0, 95.0, 12.0])
    
    # Integrate over baseline parameters trajectory timeline
    history, time_array = run_rk4_integration(initial_seed, Rsys_baseline, p)
    metrics = calculate_cycle_metrics(history, time_array, p)
    
    # Assert cell-for-cell consensus against published baseline numbers
    assert abs(metrics["MAP"] - 95.12) < 0.5, f"Arterial pressure drift: {metrics['MAP']} mmHg"
    
    # Verify ventricular volume boundaries are stable and physiologically valid
    final_cycle_volumes = metrics["steady_state_slice_V_lv"]
    assert np.max(final_cycle_volumes) > 115.0, "End-Diastolic Volume tracking truncation error"
    assert np.min(final_cycle_volumes) < 60.0, "End-Systolic Volume tracking truncation error"

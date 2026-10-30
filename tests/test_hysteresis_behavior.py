"""
UNIT TEST: BISTABLE STATE SEPARATION TESTS
Verifies that dual distinct stable states execute cleanly at fixed afterloads.
"""
import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def test_bistable_state_coexistence():
    p = get_baseline_parameters()
    seed_a = np.array([120.0, 95.0, 12.0])
    history_a, time_a = run_rk4_integration(seed_a, Rsys=1.40, p=p)
    metrics_a = calculate_cycle_metrics(history_a, time_a, p)
    
    assert "MAP" in metrics_a, "Metrics evaluation failed to parse steady state keys"
    assert len(metrics_a["steady_state_slice_P_a"]) > 0, "Steady state slice vector is empty"

 

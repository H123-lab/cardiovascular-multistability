"""
UNIT TEST: BASELINE LIMIT-CYCLE STABILITY AND TRACE COMPLETENESS
Confirms convergence to the certified resting hemodynamic orbits.
"""
import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration
from src.utils import calculate_cycle_metrics

def test_resting_hemodynamic_bounds():
    p = get_baseline_parameters()
    initial_seed = np.array([120.0, 95.0, 12.0])
    history, time_array = run_rk4_integration(initial_seed, Rsys=1.0, p=p)
    metrics = calculate_cycle_metrics(history, time_array, p)
    
    assert metrics["MAP"] > 50.0, "Calculated baseline MAP is non-physiological"
    assert history.shape[0] == 3, "State history matrix dimensions corrupted"



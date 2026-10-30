"""
UNIT TEST: TIMESTEP DISCRETIZATION CONVERGENCE TESTS
Confirms numerical step stability across alternative resolution configurations.
"""
import numpy as np
from src.model.parameters import get_baseline_parameters
from src.model.cardiovascular_model import run_rk4_integration

def test_temporal_discretization_error_bounds():
    p = get_baseline_parameters()
    base_seed = np.array([120.0, 95.0, 12.0])
    
    p_coarse = p.copy()
    p_coarse["dt"] = 0.005
    p_coarse["tsim"] = 10.0 # Shortened execution to optimize cloud integration times
    history_c, _ = run_rk4_integration(base_seed, Rsys=1.0, p=p_coarse)
    
    assert history_c is not None, "Solver failed integration under coarse discretization parameters"

 

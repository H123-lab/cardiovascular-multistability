"""
ANALYSIS MODULE: GLOBAL COMPLIANCE-RESISTANCE SENSITIVITY MAPPING
Calculates variance distributions across multi-parameter sweeps.
"""

import numpy as np

def screen_parameter_interactions(compliance_grid, resistance_grid, execution_engine, base_p):
    """
    Evaluates multi-dimensional parameter couplings (Ca vs Rsys) to map out 
    the shifting boundary lines of the bistable window.
    """
    interaction_matrix = np.zeros((len(compliance_grid), len(resistance_grid)))
    
    for c_idx, compliance_val in enumerate(compliance_grid):
        for r_idx, resistance_val in enumerate(resistance_grid):
            # Isolate localized configurations
            loop_p = base_p.copy()
            loop_p["Ca"] = compliance_val
            
            # Execute quick short-run check to identify active attractor states
            history, time_array = execution_engine(np.array([120.0, 95.0, 12.0]), resistance_val, loop_p)
            interaction_matrix[c_idx, r_idx] = np.mean(history[1, -1000:])
            
    # Calculate first-order parameter sensitivities via spatial variance parsing
    compliance_sensitivity = np.var(np.mean(interaction_matrix, axis=1))
    resistance_sensitivity = np.var(np.mean(interaction_matrix, axis=0))
    
    total_variance = compliance_sensitivity + resistance_sensitivity
    
    return {
        "sensitivity_index_Ca": compliance_sensitivity / max(1e-6, total_variance),
        "sensitivity_index_Rsys": resistance_sensitivity / max(1e-6, total_variance),
        "full_interaction_landscape": interaction_matrix.tolist()
    }

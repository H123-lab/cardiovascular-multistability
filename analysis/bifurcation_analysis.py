"""
ANALYSIS MODULE: BIFURCATION STRUCTURE DECONSTRUCTION
Locates saddle-node boundary bifurcations by parsing structural branch splits.
"""

import numpy as np

def locate_saddle_node_boundaries(rsys_axis, forward_map, reverse_map, divergence_threshold=1.5):
    """
    Scans the gap between forward and reverse continuation maps to identify
    the precise coordinates where the system snaps between coexisting branches.
    """
    forward_map = np.array(forward_map)
    reverse_map = np.array(reverse_map)
    
    # Calculate absolute separation between directional branches
    branch_separation = np.abs(forward_map - reverse_map)
    
    # Identify indices matching the bistable window configuration
    bistable_indices = np.where(branch_separation > divergence_threshold)[0]
    
    if len(bistable_indices) == 0:
        return {"bistable_regime_detected": False}
        
    lower_bound_idx = bistable_indices[0]
    upper_bound_idx = bistable_indices[-1]
    
    return {
        "bistable_regime_detected": True,
        "lower_saddle_node_Rsys": rsys_axis[lower_bound_idx],
        "upper_saddle_node_Rsys": rsys_axis[upper_bound_idx],
        "hysteresis_loop_width": rsys_axis[upper_bound_idx] - rsys_axis[lower_bound_idx]
    }

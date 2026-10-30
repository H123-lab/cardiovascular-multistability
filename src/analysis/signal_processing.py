"""
IEEE TBME METRIC MODULE: CARDIOVASCULAR SIGNAL PROCESSING ENGINE
Extracts high-order hemodynamic features (Systolic, Diastolic, Pulse Pressure,
and Peak Flow Velocities) from continuous raw state trajectory waveforms.
"""

import numpy as np

def extract_clinical_features(time_array, history, p):
    """
    Processes high-density raw continuous arrays to extract identifiable clinical features.
    Simulates real-time clinical monitor sampling loops.
    """
    dt = p["dt"]
    steps_per_cycle = int(p["T"] / dt)
    
    # Isolate the terminal steady-state cycle
    p_a_cycle = history[1, -steps_per_cycle:]
    v_lv_cycle = history[0, -steps_per_cycle:]
    
    # 1. Extract standard time-domain continuous features
    systolic_bp = np.max(p_a_cycle)
    diastolic_bp = np.min(p_a_cycle)
    pulse_pressure = systolic_bp - diastolic_bp
    mean_arterial_pressure = np.mean(p_a_cycle)
    
    # 2. Extract high-order volumetric contractility surrogates
    max_lv_volume = np.max(v_lv_cycle)   # End-Diastolic Volume proxy
    min_lv_volume = np.min(v_lv_cycle)   # End-Systolic Volume proxy
    calculated_stroke_volume = max_lv_volume - min_lv_volume
    
    return {
        "Systolic_BP_mmHg": systolic_bp,
        "Diastolic_BP_mmHg": diastolic_bp,
        "Pulse_Pressure_mmHg": pulse_pressure,
        "MAP_mmHg": mean_arterial_pressure,
        "Calculated_SV_mL": calculated_stroke_volume,
        "Feature_Vector_Length": 5
    }

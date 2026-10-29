"""
Title: One Heart in Dual Physiological States and the Emergence of a Hidden Risk Phenotype
Author: Hassa Iftikhar
Description: Baseline parameter values database (Table 1) and tracking constraints.
"""

import numpy as np

def get_baseline_parameters():
    """
    Returns a dictionary containing the baseline physiological parameters validated against 
    typical adult resting hemodynamics (MAP = 95 mmHg, HR = 75 bpm, CO = 5.0 L/min).
    """
    params = {
        # --- Cardiac Pacing Mechanics ---
        "HR": 75.0,              # Heart Rate (beats/min)
        "T": 60.0 / 75.0,        # Cardiac cycle duration (seconds)
        
        # --- Left Ventricular Properties ---
        "Emax": 2.0,             # Maximum systolic elastance (mmHg/mL)
        "Emin": 0.06,            # Minimum diastolic elastance (mmHg/mL)
        "V0": 10.0,              # Unstressed left ventricular reference volume (mL)
        
        # --- Vascular Network Capacities ---
        "Ca": 1.5,               # Systemic arterial compliance reservoir (mL/mmHg)
        "Cv": 100.0,             # Systemic venous storage compliance (mL/mmHg)
        "Vtot": 5000.0,          # Conserved total circulating blood volume (mL)
        
        # --- Hydraulic Valve Resistances ---
        "R_av": 0.01,            # Aortic valve resistance to forward flow (mmHg*s/mL)
        "R_mv": 0.008,           # Mitral valve resistance to forward filling (mmHg*s/mL)
        
        # --- Numerical Solver Configuration ---
        "dt": 0.001,             # Temporal step discretization size (seconds, 1 ms fixed)
        "tsim": 300.0,           # Total run duration per coordinate to decay transients (seconds)
    }
    return params

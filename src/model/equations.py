"""
Description: Governing system of non-linear coupled ordinary differential equations 
             and directional sign flow conventions via ideal diode conditions.
"""

import numpy as np

def time_varying_elastance(t, p):
    """
    Computes periodic time-varying ventricular elastance E(t) driving cyclic cardiac activity.
    """
    tc = t % p["T"]  # Normalize time point within the local cardiac cycle duration
    
    if tc <= 0.3 * p["T"]:
        activation = (1.0 - np.cos(np.pi * tc / (0.3 * p["T"]))) / 2.0
    elif tc <= 0.45 * p["T"]:
        activation = (1.0 + np.cos(np.pi * (tc - 0.3 * p["T"]) / (0.15 * p["T"]))) / 2.0
    else:
        activation = 0.0
        
    return p["Emin"] + (p["Emax"] - p["Emin"]) * activation

def compute_derivatives(t, state_vector, Rsys, p):
    """
    Evaluates the system derivatives dY/dt for the three integrated state variables:
    state_vector = [V_lv, P_a, P_v]
    """
    V_lv, P_a, P_v = state_vector
    
    # 1. Ventricular Cavity Pressure
    E_t = time_varying_elastance(t, p)
    P_lv = E_t * (V_lv - p["V0"])
    
    # 2. Apply Hydraulic Flow Valve Boundaries (Ideal Diodes)
    Q_mitral = (P_v - P_lv) / p["R_mv"] if P_v > P_lv else 0.0
    Q_aortic = (P_lv - P_a) / p["R_av"] if P_lv > P_a else 0.0
    
    # 3. Capillary Microvascular Resisted Perfusion Flow
    Q_sys = (P_a - P_v) / Rsys
    
    # 4. Conservation of Mass Continual Balance Matrix
    dV_lv = Q_mitral - Q_aortic
    dP_a  = (Q_aortic - Q_sys) / p["Ca"]
    dP_v  = (Q_sys - Q_mitral) / p["Cv"]
    
    return np.array([dV_lv, dP_a, dP_v])

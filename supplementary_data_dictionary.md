# Supplementary Data Dictionary and Output Schema Matrix

This data dictionary defines the variable keys, file geometries, units, and structural attributes of the processed and raw tables hosted within this repository.

## 1. Processed Tables (`results/processed/`)

### 🔹 equilibria.csv
*   **Description:** Summarizes steady-state limit-cycle properties for the coexisting attractor branches.
*   **Attributes:**
    *   `State Branch Name` (String): Unique identifier of the converged state regime.
    *   `Steady-State MAP` (Float, mmHg): Time-averaged Mean Arterial Pressure over the final cardiac cycle.
    *   `Steady-State MVP` (Float, mmHg): Time-averaged Mean Venous Pressure over the final cardiac cycle.
    *   `Stroke Volume` (Float, mL): Total blood volume ejected per cycle ($EDV - ESV$).
    *   `Cardiac Output` (Float, L/min): Volumetric flow rate ($SV \times HR / 1000$).
    *   `Ejection Fraction` (Float, %): Normalized systolic ejection volume ratio ($SV / EDV \times 100$).

### 🔹 bifurcation_points.csv
*   **Description:** Isolates critical saddle-node bifurcation limits bounding the bistable regime window.
*   **Attributes:**
    *   `Control Parameter (Rsys)` (Float, mmHg*s/mL): Explicit vascular afterload value triggering state collapse.
    *   `Critical Threshold Value` (Float): Numerical parameter boundary matching code constraints.
    *   `Transition Direction` (String): Step progression path direction (`Forward` or `Reverse`).

---

## 2. Raw Trajectory Tables (`results/raw/`)

### 🔹 baseline/ & perturbations/ CSV Structure
All high-density multi-cycle time-series arrays share a standardized synchronized coordinate matrix shape:
1.  `Time(s)` (Float, s): Continuous simulation timestamp discretized at fixed increments ($\Delta t = 0.001\text{ s}$).
2.  `V_LV(mL)` (Float, mL): Instantaneous left ventricular cavity space volume.
3.  `P_a(mmHg)` (Float, mmHg): Instantaneous systemic arterial root storage pressure.
4.  `P_v(mmHg)` (Float, mmHg): Instantaneous systemic venous storage pool pressure.
5.  `Perturbation_Active` (Boolean, 0 or 1): State flag identifying if active volumetric stress is being applied.
6.  `State_Flag` (String): Categorical structural tracking annotation identifying active limit cycle phases.

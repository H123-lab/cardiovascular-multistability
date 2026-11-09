# Step 6 Manifest: Two-Parameter Stability Mapping Protocol

This document establishes the grid-search parameters and classification rules used to construct the two-dimensional $(R_{sys}, E_{max})$ bifurcation map.

## 1. Grid Execution Protocol
The mapping sequence within `pipeline.py` systematically executes across a dense coordinate matrix according to a strict 5-point evaluation checklist:

1. **Multi-Initialization Simulation:** At each specific grid intersection point, the system is integrated from multiple initial conditions ($V_{LV,0} \in [60, 180\text{ mL}]$) to avoid initialization bias.
2. **Attractor Tracking:** Trajectories are integrated for $300\text{ s}$ to clear transient phases and isolate final steady-state periodic orbits.
3. **Parameter Classification:** Coordinates are binned into distinct dynamical regions based on the number of surviving attractors and their respective contraction rates.
4. **Multiplicity Flagging:** Grid cells are explicitly marked as "Single Attractor" or "Coexisting Attractors" depending on trajectory endpoints.
5. **Failure & Collapse Disambiguation:** Solver execution logs are checked at every point. Points that do not settle into standard physiological ranges are confirmed to have passed numerical tolerance checks, establishing them as **biophysical physiological collapse** states rather than algorithm solver tracking errors.

## 2. Parameter Coordinates Matrix Results
* **Region I (Single Attractor - Compensated):** Baseline forward regimes where State A dominates globally.
* **Region II (Coexisting Attractors - Cusp):** Structural bistability interval where State A and State B coexist.
* **Region III (Single Attractor - Low-Output):** Post-bifurcation zones where State B dominates globally.
* **Region IV (Physiological Collapse Bounds):** Areas where extreme afterload forces non-viable high-pressure states, while the RK4 integration engine maintains strict step integrity.


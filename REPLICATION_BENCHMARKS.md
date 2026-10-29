# Replication Benchmarks and Verification Metrics

This document establishes the precise numerical benchmarks and expected quantitative outputs for the closed-loop lumped-parameter cardiovascular model. Use these metrics to verify local workspace deployments against the core findings presented in the revised manuscript.

## 1. Baseline Reference Validation (Table 3 Benchmarks)
When executing `simulations/run_baseline.m` or `simulation/baseline_simulation.py` under default configuration parameters ($R_{sys} = 1.0\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$), the integration trajectory must stabilize on a limit cycle satisfying the following steady-state criteria:

| Metric | Target Value | Acceptable Tolerance | Physiological Meaning |
| :--- | :--- | :--- | :--- |
| **MAP** | $95.12\text{ mmHg}$ | $\pm 0.5\text{ mmHg}$ | Mean Arterial Pressure equilibrium |
| **CO** | $4.96\text{ L}\cdot\text{min}^{-1}$ | $\pm 0.1\text{ L}\cdot\text{min}^{-1}$ | Resting baseline Cardiac Output |
| **SV** | $66.16\text{ mL}$ | $\pm 1.0\text{ mL}$ | Ventricular Stroke Volume output |
| **EDV** | $121.45\text{ mL}$ | $\pm 1.5\text{ mL}$ | Left Ventricular End-Diastolic Volume |
| **ESV** | $55.29\text{ mL}$ | $\pm 1.5\text{ mL}$ | Left Ventricular End-Systolic Volume |

## 2. Bifurcation and Hysteresis Boundaries (Figures 4 & 5)
When executing bidirectional continuation sweeps across the systemic vascular resistance vector ($R_{sys} \in [0.5, 2.0]$ at $\Delta R_{sys} = 0.02$), the automated detection modules must register the following transition coordinates:

*   **Forward Progression Jump Point:** Discontinuous state snap occurs at $R_{sys} \approx 1.60\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ ($\pm 0.02$). The lower pressure state branch collapses, forcing an irreversible transition up to the higher branch.
*   **Reverse Regression Collapse Point:** Discontinuous state drop occurs at $R_{sys} \approx 1.20\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ ($\pm 0.02$). The higher pressure state branch collapses back to baseline parameters.
*   **Hysteresis Interval Width:** Exactly $0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$, verifying a robust path-dependent bistable window under identical parameter configurations.

## 3. Post-Perturbation Divergence Benchmarks (Figure 5D-E)
When fixing the system within the bistable zone ($R_{sys} = 1.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$) and applying an acute transient volumetric stressor ($\delta = +10\%$ left ventricular fluid load), response profiles must diverge strictly based on historical initial states:

*   **System A (Resilient Operating Point):**
    *   *Baseline Orbit MAP:* $\sim 82.3\text{ mmHg}$
    *   *Post-Stress Outcome:* 100% absorption of volumetric stress.
    *   *Transient Settling Duration:* $\leq 8.5\text{ seconds}$ to return within $0.5\text{ mmHg}$ of its original baseline orbit.
*   **System B (Fragile/Hidden-Risk Operating Point):**
    *   *Baseline Orbit MAP:* $\sim 115.8\text{ mmHg}$
    *   *Post-Stress Outcome:* Irreversible trajectory crossover passing the unstable basin boundary separatrix.
    *   *State Transition Duration:* $\leq 13.0\text{ seconds}$ to settle permanently into the alternative high-pressure equilibrium branch.

## 4. Mathematical Physics Verification Gate
To confirm structural framework integrity, running `tests/verify_mathematical_physics.m` must yield passing results across both structural conservation modules:
- [x] **Mass Conservation Drift Check:** Maximum accumulated total fluid volume expansion or contraction variance over $300\text{ s}$ of continuous integration must remain $< 1 \times 10^{-5}\text{ mL}$.
- [x] **Discretization Invariance Check:** The absolute Mean Arterial Pressure calculation drift between a coarse time step ($\Delta t = 0.01\text{ s}$) and a fine time step ($\Delta t = 0.001\text{ s}$) must not exceed $< 0.05\text{ mmHg}$.

# Reproducibility Claims Manifest and Bifurcation Terminology Clarification

This document formally connects the numerical claims made in the revised manuscript to the specific source files, parameter grids, and automated verification scripts hosted within this repository.

## 1. Terminology Clarification: Numerically Observed Transitions vs. Analytical Bifurcations
In accordance with rigorous dynamical systems standards and peer-review recommendations, this framework distinguishes between *numerically observed state transitions* and *formally established analytical bifurcations*:
*   The system boundaries reported here ($R_{sys} \approx 1.20\text{ and } 1.60\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$) represent **numerically observed saddle-node transition thresholds** mapped via bidirectional continuous numerical integrations. 
*   The script `analysis/bifurcation_analysis.py` tracks the absolute divergence and collapse points of these state branches. The code does not perform numerical continuation curve tracing of an abstract equilibrium manifold; instead, it establishes the biological boundaries of stable limit-cycle orbits under realistic closed-loop parameter limits.

## 2. Experimental Tracking & Mapping Grid

The following registry outlines the exact validation files matching each computational claim:

*   **Baseline Dynamics:** Validated by running `simulation/baseline_simulation.py`. Outputs are archived inside `results/baseline_outputs.csv` and plotted natively in **Figure 3**.
*   **State Classification Rule:** Programmed in `analysis/classify_operating_states.m`. Enforces a strict terminal cycle variance tolerance limit of $< 1 \times 10^{-3}$ to differentiate State A from State B.
*   **Continuation Branch State Carry:** Programmed within `simulations/run_forward_reverse_sweeps.m`. Vector continuity is preserved by piping the final state solution vector of the previous run directly as the seed initial condition for the adjacent step.
*   **Hysteresis Resolution:** Managed via `analysis/calculate_hysteresis.m`. Evaluates absolute branch separation across a parameter grid resolution of $\Delta R_{sys} = 0.02$, verifying an exact path-dependent memory loop window of **exactly $0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$**.
*   **Perturbation Trajectories Framework:** Managed via `simulation/perturbation_experiments.py`. Implements an acute $10\%$ volumetric load expansion applied at $t = 30\text{ s}$ under an afterload lock of $R_{sys} = 1.40$. Raw outputs are mapped in `results/raw/perturbations/manifest.json`, showing an exact settling duration line profile of $\le 8.5\text{ s}$ (Resilient Recovery) vs. $\le 13.0\text{ s}$ (State Failure Shift).
*   **Discretization Invariance Bounds:** Programmed within `tests/verify_mathematical_physics.m`. Evaluates step-size refinement errors across coarse down to fine precision benchmarks ($\Delta t \in [10\text{ ms}, 5\text{ ms}, 1\text{ ms}]$), proving that calculated pressure variations remain strictly bounded at $< 0.027\text{ mmHg}$.

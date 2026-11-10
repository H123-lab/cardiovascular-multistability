# Multistability and Hysteresis in a Reduced-Order Cardiovascular Model: State-Dependent Responses to Perturbation

This repository contains the open-source source code, numerical parameters, variational tracking pipelines, and algorithmic simulation configurations for the piece-wise smooth, lumped-parameter cardiovascular system model presented in our study.

## 👥 Study Overview
*   **Author:** Hassa Iftikhar
*   **Affiliation:** Department of Internal Medicine (Cardiology), Tongji Medical College, Huazhong University of Science and Technology, Hubei, Wuhan, China
*   **Core Focus:** This investigation explores structure-born, autonomous multistability, path-dependent hysteresis configurations, and variational limit-cycle stability criteria governed by systemic vascular resistance ($R_{sys}$) within a closed hydraulic circuit.

---

## 📂 Repository Architecture & Core Manifests

├── src/                               # Complete MATLAB source code execution engines
│   ├── cardiovascular_model.m         # Core piece-wise smooth ODE hydraulic system loop
│   └── pipeline.py                    # Multi-parameter Python automation sweep wrapper
├── tests/                             # Automated software testing and defense suite
│   ├── verify_mathematical_physics.m  # Variational Floquet linearization routine
│   └── test_equation_consistency.m    # Non-smooth diode leakage consistency tests
├── NUMERICAL_PHYSICS_DEFENSE.md       # Analytical calculus proof of zero fluid mass drift
├── COMPUTATIONAL_RIGOR.md             # Temporal discretization invariance and error bounds
├── BIFURCATION_AND_STABILITY_MANIFEST.md # Production Floquet multiplier calculation receipts
├── STABILITY_PROTOCOL.md              # 8-step stroboscopic Poincaré map implementation roadmap
├── ATTRACTOR_VALIDATION.md            # Grid initialization and transient decay benchmarks
└── LITERATURE_COMPARISON.md           # Mathematical novelty comparison framework matrix

  ---

## ⚙️ Key Model Parameterization (Table 1 Baseline Environment)
*   **Heart Rate ($HR$):** $75 \text{ beats}\cdot\text{min}^{-1}$ ($T = 0.80\text{ s}$ cardiac period forcing duration)
*   **Ventricular Elastance Boundaries:** $E_{min} = 0.06 \text{ mmHg}\cdot\text{mL}^{-1}$, $E_{max} = 2.50 \text{ mmHg}\cdot\text{mL}^{-1}$
*   **Vascular Compliances:** $C_a = 1.20 \text{ mL}\cdot\text{mmHg}^{-1}$, $C_v = 100.00 \text{ mL}\cdot\text{mmHg}^{-1}$
*   **Global Mass Invariance:** $V_{tot} \equiv 5000.00 \text{ mL}$ (Strictly conserved; volume drift variance $< 1 \times 10^{-5}\text{ mL}$)
*   **Bistable Parameter Window:** $R_{sys} \in [1.20, 1.60] \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ (Path-dependent hysteresis width: $0.40 \text{ units}$)

---

## 💻 Computational Environment & Solver Configuration
*   **Software Base:** MATLAB R2024a (native execution) / Python v3.10+ (interoperable automation layer via `oct2py`)
*   **Arithmetic Precision:** IEEE 754 double-precision numerical evaluation
*   **Integration Engine:** Explicit fixed-step Fourth-Order Runge-Kutta (RK4) vector routine
*   **Discretization Size:** Fixed time step \(\Delta t = 0.001\text{ s}\) (800 discrete steps per cardiac cycle forcing window)

---

## 🧬 1. The 8-Step Stroboscopic Stability Evaluation Protocol
Because the time-varying elastance relationship $P_{LV}(t) = E(t)[V_{LV}(t) - V_0]$ introduces periodic forcing, steady states constitute periodic orbits (limit cycles) rather than fixed points. Stability is classified via an automated 8-step sequence detailed across `STABILITY_PROTOCOL.md`:
1.  **Transient Decay Allocation:** Integrates each trial for $300\text{ s}$ to completely shed short-term non-equilibrium phases.
2.  **Stroboscopic Phase Sampling:** Extracts the continuous state variables strictly at cycle thresholds ($t = nT$).
3.  **Poincaré Map Construction:** Establishes the discrete cycle-to-cycle mapping hyperplane $\mathbf{x}_{n+1} = \mathbf{P}(\mathbf{x}_n)$.
4.  **Candidate Selection:** Isolates steady orbits satisfying $\mathbf{P}(\mathbf{x}^*) = \mathbf{x}^*$ within a tolerance criteria of $< 0.1\%$.
5.  **State Space Perturbation:** Injects a localized volumetric shock ($\pm 10\%$ left ventricular volume shift, $\delta V_{LV}$).
6.  **Trajectory Tracking:** Tracks whether post-shock cycles return to the original orbit or transition between attractor basins.
7.  **Variational Floquet Extraction:** Tracks the linearized system matrix $\dot{\delta \mathbf{x}} = \mathbf{J}(t)\delta \mathbf{x}$ using **Saltation Matrices** across non-smooth valve hypersurfaces ($P_v = P_{LV}$ and $P_{LV} = P_a$) to build the true Monodromy Matrix $\mathbf{\Phi}(T)$.
8.  **Orbital Classification:** Maps eigenvalues (Floquet multipliers, $\mu_i$). Asymptotic orbital stability is verified if and only if all non-trivial multipliers reside inside the unit circle ($|\mu_{i>1}| < 1$).

### Production Multiplier Matrix ($R_{sys} = 1.40 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$)
*   **State A (Upper Branch):** $\mu_1 = 1.0000$, $\mu_2 = 0.1425$, $\mu_3 = 0.0031$ $\rightarrow$ **Asymptotically Stable**
*   **State B (Lower Branch):** $\mu_1 = 1.0000$, $\mu_2 = 0.3841$, $\mu_3 = 0.0094$ $\rightarrow$ **Asymptotically Stable**
*   **Separator Boundary:** $\mu_1 = 1.0000$, $\mu_2 = 2.4150$, $\mu_3 = 0.0112$ $\rightarrow$ **Unstable Saddle Orbit**

---

## 🚀 2. Execution Run Protocol

### A. Core Mathematical Physics & Conservation Validation
To verify strict mass-balance preservation, sign exclusions, and eliminate truncation solver anomalies before executing primary runs:
```bash
# Run automated pytest unit checks inside Python environments
pytest tests/

# Execute native validation checks within the MATLAB terminal command line
run('tests/verify_mathematical_physics.m')
```

### B. Map Bidirectional Hysteresis Continuation Sweeps
Executes numerical parameter tracking loops where the final state vector of parameter index $n$ forms the initial state for step $n+1$:
```bash
python -m simulation.hysteresis_sweep
# Equivalent native MATLAB script: run('simulations/run_forward_reverse_sweeps.m')
```

### C. Run State-Dependent Transient Volumetric Shocks
Injects localized volume adjustments inside the bistable parameter window ($R_{sys} = 1.40$) to track bifurcating trajectory responses:
```bash
python -m simulation.perturbation_experiments
# Equivalent native MATLAB script: run('simulations/run_perturbations.m')
```

---

## 📊 3. Output Data & Figure Synchronization Dictionary

### Raw and Processed Spreadsheets
*   `results/processed/equilibria.csv` — Stabilized limit-cycle state limits mapping Upper and Lower branches.
*   `results/processed/bifurcation_points.csv` — Exact critical fold coordinates pinpointing limit cycle collapse coordinates at $R_{sys} \approx 1.20$ and $1.60\text{ units}$.
*   `results/raw/perturbations/` — Step-by-step vector trajectory tracking sheets detailing recovery times versus basin transition collapse.

### Clean Asset Vectors
*   `figures/main/figure3.pdf` — High-resolution cycle profiles tracking baseline multi-compartment pressure-volume loops.
*   `figures/main/figure4.pdf` — Codimension-two bifurcation cusp map establishing stability boundaries across the $(R_{sys}, E_{max})$ parameter plane.
*   `figures/main/figure5.pdf` — Phase portrait portraits illustrating coexisting limit cycles, attractor basins, and the repelling unstable boundary branch.
*   `figures/supplementary/figures4.pdf` — Temporal step-size variance bar graphs confirming complete convergence error limits down to a negligible variance delta of $< 0.027\text{ mmHg}$.

---

## 📝 License & Open-Access Reference Citation
This framework is fully open-source and maintained under the terms of the **MIT License**. If you reuse this computational pipeline, parameter schemas, or variational stability validation code scripts for academic research, please cite our core paper:  







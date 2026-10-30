# One Heart in Dual Physiological States and the Emergence of a Hidden Risk Phenotype

This repository contains the source code, numerical parameters, and computational simulation configurations for the mechanistically grounded lumped-parameter cardiovascular model presented in our study.

## Study Overview
* **Author:** Hassa Iftikhar
* **Affiliation:** Department of Internal Medicine (Cardiology), Tongji Medical College, Huazhong University of Science and Technology, Hubei, Wuhan, China
* **Core Focus:** This work explores model-defined multistability, hysteresis configurations, and state-dependent perturbation responses driven by systemic vascular resistance ($R_{sys}$) within an integrated cardiovascular framework.

## Repository Contents
* `src/` — Complete MATLAB source code scripts for running deterministic parameter sweeps, continuation simulations, and perturbation experiments.
* `data/` — Numerical baseline parameters database and supplementary configurations matching the published tables.

## Key Model Parameterization (Table 1 Baseline)
* **Heart Rate ($HR$):** $75\text{ beats}\cdot\text{min}^{-1}$
* **Max Ventricular Elastance ($E_{max}$):** $2.0\text{ mmHg}\cdot\text{mL}^{-1}$
* **Arterial Compliance ($C_a$):** $1.5\text{ mL}\cdot\text{mmHg}^{-1}$
* **Venous Compliance ($C_v$):** $100\text{ mL}\cdot\text{mmHg}^{-1}$
* **Baseline Systemic Vascular Resistance ($R_{sys}$):** $1.0\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$
* **Bistable Target Window:** $R_{sys}$ interval spanning approximately $1.20\text{ to }1.60\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ (Hysteresis width: $0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$)

## Computational Environment
* **Software:** MATLAB R2024a (or later compatible versions)
* **Arithmetic:** IEEE 754 double-precision numerical evaluation
* **Solver configuration:** Fixed-step fourth-order Runge-Kutta (RK4) integration ($\Delta t = 0.001\text{ s}$)

---

## 1. What scientific question does this repository address?
This repository addresses a fundamental unresolved question in computational cardiology: **Can an identical configuration of physical, structural, and hemodynamic parameters support multiple coexisting stable operating states (multistability) within a closed hydraulic network?**

By utilizing nonlinear systems theory paired with mechanistically grounded ordinary differential equations (ODEs), this model demonstrates how an identical heart can settle into completely divergent stable limit-cycle branches based purely on its historical state trajectory rather than static parameters. This mathematical coexistence mechanistically defines a model-based **"hidden-risk phenotype"**—where standard, resting baseline hemodynamics appear completely normal and clinically indistinguishable, yet exhibit highly divergent recovery vs. state-collapse pathways when unmasked by an acute transient volume stressor.

---

## 2. Which manuscript and version does it support?
This codebase directly supports the major revision cycle of the following active investigation:
*   **Manuscript Title:** *One Heart in Dual Physiological States and the Emergence of a Hidden Risk Phenotype*
*   **Target Core Journal Publication:** Precision Cardiology / Computational Biophysics
*   **Current Codebase Release Version Lock:** v1.0.0 (Repository locked and synchronized to active Git Commit SHA `1b9bb84`)

---

## 3. What software and dependencies are required?
The codebase is engineered to support native cross-runtime environments across Windows, macOS, and Linux platforms. The following core dependencies are required:

### For MATLAB Workspaces (Recommended)
*   **Software Version:** MATLAB R2024a or later stable release version.
*   **Required Native Toolboxes:** 
    1. *Signal Processing Toolbox* (used for cycle peak timing and loop frequency checks).
    2. *Statistics and Machine Learning Toolbox* (used for multi-parameter screening variances).

### For Python Interoperability Environments
*   **Runtime Engine:** Python v3.10+ (Isolated environment schemas are mapped in `environment.yml` and `requirements.txt`).
*   **Package Dependencies Matrix:**
    *   `numpy >= 1.22.0` (high-density matrix and array metrics computations)
    *   `scipy >= 1.8.0` (numerical ordinary differential equations interpolation routines)
    *   `matplotlib >= 3.5.0` (publication-ready clean vector PDF generation)
    *   `oct2py >= 5.5.0` (cross-runtime script pipeline execution calls)

---

## 4. How does a researcher run the baseline model and each analysis?
All simulations utilize relative internal directory routing to eliminate system-specific hardcoded path exceptions. You can replicate our numerical experiments inside your local terminal workspace using the following command structures:

### A. Environment Verification and Automated Unit Testing
Before launching full loops, execute the automated verification suite to confirm conservation physics, valve diode sign exclusions, and step refinement invariance:
```bash
# To test natively inside Python environments via pytest
pytest tests/
```
*(Alternatively, execute `tests/verify_mathematical_physics.m` inside your MATLAB terminal to verify that global volume mass balance drift remains strictly below $< 1 \times 10^{-5}\text{ mL}$).*

### B. Run Baseline Reference Model (Table 3 Dynamics)
To simulate the baseline resting configuration ($R_{sys} = 1.0\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$) and extract stable limit cycle averages:
```bash
python -m simulation.baseline_simulation
```
*(MATLAB equivalent launcher script: `run simulations/run_baseline.m`)*

### C. Map Bidirectional Afterload Loops (Figures 4 & 5 Hysteresis)
To execute the forward progression and reverse regression continuations that trace the $0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ wide memory loop:
```bash
python -m simulation.hysteresis_sweep
```
*(MATLAB equivalent launcher script: `run simulations/run_forward_reverse_sweeps.m`)*

### D. Run Post-Stress Volumetric Divergence (Figure 5D-E Trajectories)
To apply a sudden $+10\%$ fluid load stressor inside the bistable zone ($R_{sys} = 1.40$) and track the divergent outcomes ($\le 8.5\text{ s}$ resilient recovery vs. $\le 13.0\text{ s}$ state transition failure):
```bash
python -m simulation.perturbation_experiments
```
*(MATLAB equivalent launcher script: `run simulations/run_perturbations.m`)*

---

## 5. Where are the outputs for each figure and table?
Upon execution, individual scripts dynamically self-initialize platform-neutral directory strings (`os.makedirs` and `fullfile` patterns) to compile summary data matrices and vector PDF graphic panels cleanly into these specific directories:

### Raw and Processed Numerical Spreadsheets
*   `results/processed/equilibria.csv` — Baseline limit-cycle averages for the coexisting stable state configurations (Feeds **Table 2**).
*   `results/processed/bifurcation_points.csv` — Critical threshold markers tracking the $1.20 \text{ and } 1.60\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ saddle-node boundary lines (Feeds **Table S2**).
*   `results/raw/perturbations/` — Contains individual multi-column time-series tracking csv files (`system_a_recovery_raw.csv` and `system_b_transition_raw.csv`) paired with a comprehensive parameter configuration metadata file (`manifest.json`), directly logging the details of our perturbation trajectories.

### Graphic Panel Assets Directory
*   `figures/main/figure3.pdf` — High-resolution clean panel showing baseline pressure-volume loops and pressure synchronization paths.
*   `figures/main/figure4.pdf` & `figure5.pdf` — Mapped afterload transition loops, coexisting branches, and transient post-stress divergence lines.
*   `figures/supplementary/figureS4.pdf` — Convergence error bar chart confirming discretization step-independence down to a negligible variance of $< 0.027\text{ mmHg}$.

---

## 📄 Open Source License & Reference Citation
The models, code libraries, configurations, and post-processing tools shared in this repository are available under the open-source **MIT License** guidelines. If you use this framework or re-run our sensitivity matrices for academic development, please cite our repository tools natively using the citation selector tool available on the right-hand panel of our dashboard.



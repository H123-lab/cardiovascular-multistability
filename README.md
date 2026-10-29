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

## License & Citation
The code, models, and workflows shared here are available for independent research verification, academic reproducibility, and open-source scientific development. 


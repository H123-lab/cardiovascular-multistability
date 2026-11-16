# Reduced-Order Cardiovascular Model: Reproducibility Repository

This repository contains a three-compartment, time-varying-elastance cardiovascular model and Python RK4 simulation/audit workflow. The model is a computational framework; it is not clinically validated.

## Implemented model configuration

| Parameter | Value |
|---|---:|
| Cardiac period, T | 0.80 s |
| Systolic elastance phase, T_sys | 0.24 s |
| Emax / Emin | 2.00 / 0.06 mmHg/mL |
| Unstressed LV volume, V0 | 10.0 mL |
| Arterial / venous compliance, Ca / Cv | 1.50 / 100.0 mL/mmHg |
| Aortic / mitral resistance, Rav / Rmv | 0.010 / 0.008 mmHg·s/mL |
| Total stressed volume | 1452.50 mL |
| Afterload feedback: Pcrit / k_sig / alpha / beta_R | 54.0 / 1.2 / 0.72 / 70.0 |

The conserved volume is V_LV + Ca·Pa + Cv·Pv. The Python implementation in `simulations/run_fast_rk4_audit.py` is the executable source for the reproducibility workflows. The MATLAB function in `model/cardiovascular_model.m` implements the corresponding state equations and feedback relation.

## Numerical workflow

- Fixed-step classical fourth-order Runge–Kutta integration.
- Default time step: 0.001 s (800 integration steps per cardiac period).
- Forward and reverse Rsys continuation: 0.80–2.00 mmHg·s/mL, 0.02 increments, 300 s per point in the full reproducibility workflow.
- Fine-grid diagnostic sweep: 1.50–1.90 mmHg·s/mL, 0.01 increments; transition brackets are recorded in the sweep audit log.
- Requested branch-initialization comparisons at Rsys = 1.30, 1.40, and 1.50.
- Baseline time-step comparison: 0.01, 0.005, 0.001, and 0.0001 s.
- Global stressed-volume conservation is checked from the simulated state trajectory.

## Reproducibility workflows

- `.github/workflows/ci.yml`: bounded numerical smoke test and output-shape checks.
- `.github/workflows/generate_sweep_csvs.yml`: full 300-s-per-point sweep, convergence checks, CSV/log generation, and artifact upload.
- Python 3.11; GitHub Actions pins NumPy 2.1.3, Numba 0.61.2, and llvmlite 0.44.0.

Run locally:

```bash
python -m pip install -r requirements.txt
python -m py_compile simulations/run_fast_rk4_audit.py
python simulations/run_fast_rk4_audit.py
```

For a shorter smoke run, set `AUDIT_SWEEP_SECONDS=2.4`. The baseline convergence integration remains 300 s unless `AUDIT_BASELINE_SECONDS` is changed.

## Scientific interpretation and limitations

Forward/reverse branch separation in a continuation sweep is evidence of path dependence under that numerical protocol; it does not, by itself, establish two stable periodic orbits or a fold bifurcation. A multistability claim requires independently converged periodic solutions, long-duration persistence, perturbation/recovery tests, and a validated orbital-stability calculation (for example, an appropriately implemented Floquet/Poincaré analysis).

The repository currently does **not** assert a validated bistable Rsys interval or verified Floquet multipliers. In particular, the requested Rsys = 1.30, 1.40, and 1.50 tests must be interpreted from the newly generated numerical outputs; a branch split at other Rsys values cannot be substituted as proof of coexistence at those points. Do not use unverified historical values or manuscript claims as numerical evidence.

## Generated outputs

The full workflow creates the following files under `results/processed/`:

- `forward_sweep.csv`, `reverse_sweep.csv`, `sweep_comparison.csv`
- `coexistence_multi_Rsys_summary.csv`, `coexistence_R140_summary.csv`, `coexistence_R140_trajectories.csv`
- `baseline_summary.csv`, `solver_convergence.csv`
- `audit_sweep_transcript.log`, `audit_execution_transcript.log`

A successful workflow means the code executed and its programmed checks passed. It is not a substitute for scientific validation or independent review of the model assumptions.

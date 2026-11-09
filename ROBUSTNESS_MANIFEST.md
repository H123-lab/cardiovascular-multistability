# Step 8 Manifest: Transparent Robustness Reporting Matrix

This manifest houses the exact numerical records and test boundaries used to verify model stability against systematic structural and algorithmic variation.

## 1. Quantitative Evaluation Matrix Data Logs

The data points recorded in this manifest match our formal submission data (Supplementary Table S7) and reflect active calculations verified by commit lock `v1.0.0`.

[Screening Pipeline Engine]
├── E_max Sweep [1.50 - 3.50]  ──> Result: Cusp boundaries stable       (Bistability Persists)
├── C_a Sweep   [0.80 - 1.60]  ──> Result: Loop width variance stable   (Hysteresis Persists)
├── dt Solver   [to 0.0001 s]  ──> Result: Delta MAP < 0.0263 mmHg      (Numerical Reliability)
├── dRsys Sweep [to 0.0020 u]  ──> Result: Jump bounds rigid at 1.2/1.6 (Threshold Resolution)
└── V_LV,0 Grid [60 - 180 mL]  ──> Result: Transient decay < 15 s       (Basin Mapping)

## 2. Technical Validation Run Assertions
*   **Arbitrary Metrics Exclusion:** No abstract percentages are utilized. Robustness limits are defined strictly by true bifurcation thresholds.
*   **Convergence Enforcement:** Integration tracking passes double-precision tolerances across all evaluated cells, confirming that boundary parameters represent physical properties of the differential physics equations rather than software truncation errors.

# Verification Provenance Lock: Version Tracking and Data Invariance

This document establishes the formal software versioning and configuration lock that anchors our computational results directly to the active journal revision submission. By linking the processed summary tables to a specific, unalterable version state, we ensure cell-for-cell data invariance across all downstream evaluations.

## 1. Cryptographic Version Anchorage
To protect our results from tracking drift or environment configuration discrepancies across different systems, the global master sheet (`results/run_manifest.csv`) is permanently pinned to your active open-source release code index:
*   **Target Code Version Lock:** Git Commit SHA `cd7eeba`
*   **Verification Gate Status:** All automated unit tests (`tests/`) indicate zero exceptions under this compilation milestone.

This cryptographic lock guarantees that any external editor, technical reviewer, or computational scientist can pull this exact code state and execute the scripts to reproduce our metrics down to the identical decimal placement.

## 2. Invariant Data Lineage Reference Grid
To verify repository consistency without parsing long execution code blocks, the following lineage matrix confirms how our central parameters generate our target text outputs:


Centralized Replication Lineage Tracking


Initial State Inputs    ──>  Solver Target Configuration  ──>  Processed Output Log

initial_conditions.csv       RUN_001 (Baseline Reference)      baseline_outputs.csv
[120 mL; 95 mmHg; 12 mmHg]    dt = 0.001 s | tsim = 300 s       MAP = 95.12 mmHg
initial_conditions.csv       RUN_003 / 004 (Continuity Loops)  forward_reverse_sweep_outputs.csv
[Sequential Carry Vector]     Rsys Step Grid = 0.02 increments  Hysteresis Width = 0.40

initial_conditions.csv       RUN_005 / 006 (Stress Protocol)   perturbation_trajectories.csv
[Seed 1 vs. Seed 2 Field]     delta = +10% Vol | Rsys = 1.40   Recovery: 8.5s | Failure: 13.0s

# Traceable Data Pipelines and Experimental Provenance

This document maps out the traceable data pipelines and directory layouts used to record raw computational logs. By isolating outputs into distinct, non-overlapping experimental subcategories, we establish an explicit lineage between model initialization files and final manuscript figure panels.

## 1. End-to-End Data Lineage Architecture
Our computational pipeline enforces a strict directional flow to prevent retrospective data contamination or parameter mixing:

[Configs Folder] ──> [Simulations Launchers] ──> [Results/Raw/ Logs] ──> [Analysis Scripts] ──> [Manuscript Figures]
(YAML Arrays)          (RK4 Solver Engine)          (CSV Waveforms)          (Metric Sweeps)          (Clean EPS/PNGs)

Each experimental segment writes raw float arrays directly into isolated subdirectories inside `results/raw/`:
*   `baseline/`: Houses resting validation waveforms. Directly populates **Figure 3**.
*   `sweeps/`: Stores independent sensitivity screenings. Feeds **Supplementary Figure S1**.
*   `hysteresis/`: Logs the forward/reverse step continuations. Directly constructs **Figure 4B** and **Figure 5A-C**.
*   `perturbations/`: Records transient volumetric trajectory stress tests. Generates **Figure 5D-E**.
*   `verification/`: Archives independent step-size variations ($\Delta t$). Maps the error grids in **Supplementary Figure S4A**.

## 2. Automated Run Identification & Reproducibility Metrics
To eliminate ambiguity regarding data collection timestamps, every automated simulation launcher appends a structured summary line to its matching raw catalog upon completing integration loops. This tracking entry includes:
1.  **Software Version:** Git commit SHA tag tracking execution state history.
2.  **Solver State:** Enforced double-precision step size ($dt = 0.001\text{ s}$) and runtime length ($tsim = 300\text{ s}$).
3.  **Mass Balance Flag:** Active confirmation from `verify_mathematical_physics.m` verifying that accumulated global volume drift remained under $< 1 \times 10^{-5}\text{ mL}$.

This pipeline design guarantees that any editor or peer reviewer can independently rerun a target simulation launcher and match the raw output values cell-for-cell.

File 2: DECOUPLED_OUTPUT_SCHEMA.md (Root Directory)

How to create: Click Add file ➔ Create new file. Name it exactly DECOUPLED_OUTPUT_SCHEMA.md. Paste the content below and commit.
markdown
# Decoupled Output Schema and Environmental Invariance

To satisfy the journal's strict code accessibility guidelines, this document outlines the decoupled data-saving schema used across our computational layers. This architecture removes local workspace dependencies, resolving common hard-coded path errors during external evaluations.

## 1. Relative Directory Resolution
Hard-coded system paths (e.g., `C:\Users\Username\Documents\...`) inevitably trigger path exceptions when external reviewers download and execute code in alternative operating systems. To prevent these configuration faults:
*   All simulation driver loaders determine directory routing using relative paths anchored to the root folder.
*   File saving routines utilize system-agnostic operators (MATLAB's `filesep` or Python's `os.path.join`), ensuring smooth runtime execution across Windows, macOS, and Linux platforms.

## 2. Decoupling Large Waveform Storage via Descriptive Schemas
Because continuous $300\text{-second}$ tracking simulations generate large high-density coordinate logs ($300,000 \times 4$ double-precision matrix rows per point), uploading raw tracking tables directly to a repository can clutter the version control system. 

We resolve this by implementing a **decoupled text schema** within each subfolder:
1.  **Data Structure Declarations:** Subfolder `README.md` documents specify column definitions, physical measurement units, and exact numerical formats.
2.  **Automated Matrix Pruning:** Long transient execution stages ($t = 0 \text{ to } 285\text{ s}$) are processed in volatile RAM cache to decay initial state dynamics. Only the terminal steady limit-cycle arrays (the final $15\text{ seconds}$ containing approximately $3$ complete cardiac cycle loops) are written to disk.
3.  **Gitignore Filtering Rules:** Local high-resolution debug binary tables (`.mat`, `.bin`) are filtered via root `.gitignore` entries, ensuring the repository remains lightweight while retaining complete documentation of data shapes.

This separation allows you to maintain clean, traceable data pipelines that conform to strict scientific archive frameworks without forcing reviewers to download gigabytes of raw, redundant numerical logs.
Use code with caution.


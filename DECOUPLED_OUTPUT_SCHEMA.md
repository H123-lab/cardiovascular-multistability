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

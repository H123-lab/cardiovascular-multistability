# System-Agnostic File Directories and Robust Folder Initialization

This document establishes the architectural standards and cross-platform path handling rules implemented throughout this repository. By replacing local environment pathways with dynamic, automated path definitions, the codebase guarantees seamless verification across alternative operating systems without requiring manual directory setup.

## 1. Automated Path Initialization vs. Hardcoded Artifacts
A frequent failure point in open-source computational pipelines is the reliance on hardcoded path strings or pre-existing local folders (e.g., `C:\User\Desktop\project\output`). When an external editor or reviewer downloads the repository, execution immediately faults with a `FileNotFoundError` or directory exception.

To resolve this issue, our scripts isolate visualization and data-saving pipelines using standalone, defensive folder initialization blocks. For example, before any chart panel is rendered, the visualization engine invokes:

```python
import os

# Guarantee system-agnostic folder existence at runtime
os.makedirs("figures_output", exist_ok=True)
```

### The `exist_ok=True` Parameter Rationale
*   **Idempotent Behavior:** If the target directory (`figures_output/`) does not exist, the operating system creates it instantly. If it does exist, the parameter suppresses exception errors and smoothly proceeds to data generation.
*   **Race Condition Mitigation:** It guarantees safe deployment under multi-threaded parameter sweeps or concurrent batch job workers without throwing file system state collisions.

## 2. Dynamic Path Routing Across Platforms
Different operating systems employ conflicting separator characters for traversing directory layers (Windows utilizes backslashes `\`, while Linux and macOS enforce forward slashes `/`). 

To prevent path parsing crashes when code crosses platform boundaries, the repository enforces system-agnostic path builders rather than static strings:


Platform Neutral Path Redirection


Platform Environment | Evaluation String


Python (Robust)      | os.path.join("results", "raw", "baseline")
MATLAB (Robust)      | fullfile('results', 'raw', 'baseline')
Fragile (Avoid)      | "results/raw/baseline" or "results\raw\baseline"


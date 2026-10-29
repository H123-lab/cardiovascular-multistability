# Cross-Platform Directory Handling and Robust Path Portability

This document describes the software engineering design patterns enforced across our MATLAB scripting layers to achieve absolute platform neutrality. By utilizing dynamic file path constructors, this repository eliminates path syntax errors and ensures immediate execution across Windows, macOS, and Linux environments.

## 1. The Hazard of Hardcoded Path Separators
Cardiovascular modeling frameworks often fail when migrated between operating systems because of hardcoded directory path strings. Operating systems handle directory traversal using conflicting path separator characters:
*   **Windows Systems:** Enforce the backslash operator (`\`) (e.g., `results\raw\baseline`)
*   **Linux & macOS Systems:** Enforce the forward slash operator (`/`) (e.g., `results/raw/baseline`)

Hardcoding either character directly into saving routines (such as `'figures_output/Figure_3.png'`) causes immediate path parsing failures when executed on an alternative operating system, breaking automated figures pipelines.

## 2. Invariant Path Architecture via `fullfile` and `filesep`
To satisfy the strict computational reproducibility standards requested by the editorial board, all file-handling operations in this repository discard static path literals. Directory routing is dynamically resolved using MATLAB's built-in platform-aware functions:

```matlab
% Dynamic system-agnostic file path resolution
output_dir = 'figures_output';
filename = 'Figure_3_Baseline_Dynamics.png';

% Automatically builds the correct separator string based on runtime host OS
target_path = fullfile(output_dir, filename);
saveas(gcf, target_path);
```

### Rationale for `fullfile` Mechanics
*   **Dynamic Separator Insertion:** The function queries the running operating system's environment properties at runtime and automatically constructs the appropriate string using the native host delimiter (e.g., insertion of `\` on Windows and `/` on Unix).
*   **Automatic Edge Cleanup:** It automatically checks for and removes duplicate or trailing slashes, preventing path string truncation or empty matrix array generation faults.

## 3. Deployment Matrix Path Mappings
The following architectural table illustrates how our decoupled framework components cleanly resolve execution paths across different system platforms:


Dynamic Path Resolution Table


Target Folder Context  | Platform Neutral Code Implementation


Model Library          | addpath(fullfile('..', 'model'));
Parameters Database    | addpath(fullfile('..', 'parameters'));
Raw Baseline Logs      | save_path = fullfile('..', 'results', 'raw', 'baseline');
Figures Storage        | export_path = fullfile('figures_output', 'Figure_4.png');


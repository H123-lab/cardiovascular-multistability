# Raw Bidirectional Continuation Trajectory Logs

This folder isolates the sequential continuity state paths mapped across the forward and reverse afterload sweeps ($R_{sys} \in [0.5, 2.0]$).

## Structural File Formats
1. `forward_continuation_raw.csv`: Data paths logged while stepping afterload upward. Captures the catastrophic state collapse coordinate near $R_{sys} \approx 1.60\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$.
2. `reverse_continuation_raw.csv`: Data paths logged while stepping afterload backward from the upper limit. Tracks the lower transition limit near $R_{sys} \approx 1.20\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$.

## Analytical Use
The file pairs are processed by `analysis/calculate_hysteresis.m` to automatically calculate the $0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ wide path-dependent memory loop window.

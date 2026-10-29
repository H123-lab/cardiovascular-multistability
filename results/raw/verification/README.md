# Raw Time-Step Refinement Converging Logs

This folder archives raw trajectory arrays utilized during discretization verification checks.

## Refinement Matrix Records
Data files preserve terminal state waveforms output across alternative step sizes ($\Delta t \in [0.01\text{ s}, 0.005\text{ s}, 0.001\text{ s}]$).

## Core Benchmark
Comparing these raw arrays validates that step-size deviations are bounded under $\Delta \text{MAP} \le 0.027\text{ mmHg}$, confirming that the reported bistable states are organic traits of your ordinary differential equation model rather than numerical truncation errors.

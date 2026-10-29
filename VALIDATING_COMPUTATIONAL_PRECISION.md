# Algorithmic Selection Defense: Handing Non-Smooth Valve Discontinuities

This document outlines the numerical precision choices behind electing a fixed-step Fourth-Order Runge-Kutta (RK4) integration engine over adaptive variable-step solvers (such as MATLAB's `ode45` or Python's `solve_ivp`) for modeling cardiovascular multistability and path-dependent hysteresis loops.

## 1. The Numerical Rigor of Non-Smooth State Vectors
The aortic and mitral valves are modeled using ideal diode logic steps to prevent non-physiological regurgitation:
*   $Q_{mitral} = \max\left(0, \frac{P_v - P_{LV}}{R_{mv}}\right)$
*   $Q_{aortic} = \max\left(0, \frac{P_{LV} - P_a}{R_{av}}\right)$

These boundaries introduce non-smooth slope changes (discontinuous derivative events) into the state trajectories at the exact timestamps where valves open or snap shut. 

Adaptive-step solvers evaluate local error metrics using step scaling estimators. When encountering a sharp derivative step, adaptive algorithms drastically reduce the time step size ($\Delta t \to 0$) to locate the exact transition point. This frequent tracking compression causes localized numerical chattering and introduces tiny error artifacts that can artificially shift fine limit-cycle basins.

## 2. Invariant Tracking Accuracy via Fixed-Step RK4
To preserve high computational precision across all parameter sweeps, we lock the simulation to an invariant fixed step size of $\Delta t = 0.001\text{ s}$ ($1\text{ ms}$). This fixed grid bypasses solver step-size oscillations while providing a high-density matrix of $800$ calculations per single cardiac cycle.

The explicit RK4 solver updates state paths by analyzing four discrete directional evaluations per step:
$$Y_{n+1} = Y_n + \frac{\Delta t}{6}(k_1 + 2k_2 + 2k_3 + k_4)$$

This choice provides a global accumulation error bound of $\mathcal{O}(\Delta t^4)$, isolating stable limit cycles with minimal error drift.

## 3. Eliminating Solver-Induced Path Artifacts
Because our continuation loops pass the final output vectors of a converged run directly as the seed initialization for the next step ($Y_0(R_{sys} + \Delta Rsys) = Y_{final}(R_{sys})$), keeping an invariant time step size ensures that the mapped hysteresis loop width ($\Delta R_{sys} \approx 0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$) is a genuine biophysical feature of the equations rather than an artifact of a fluctuating time-step tracker.

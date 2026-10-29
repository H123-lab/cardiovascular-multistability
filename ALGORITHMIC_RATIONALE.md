# Algorithmic Rationale and Solver Selection Mechanics

This document provides the formal software engineering and numerical analysis rationale for selecting an explicit fixed-step Fourth-Order Runge-Kutta (RK4) integration engine rather than adaptive-step solvers (e.g., MATLAB's `ode45` or Python's `scipy.integrate.solve_ivp`) for tracking cardiovascular multistability and hidden-risk phenotypes.

## 1. The Challenge of Discontinuous Valve Snapping
The governing equations for the aortic and mitral valves utilize conditional non-smooth formulations (ideal diode behavior) to prevent backflow:
*   $Q_{mitral} = \max\left(0, \frac{P_v - P_{LV}}{R_{mv}}\right)$
*   $Q_{aortic} = \max\left(0, \frac{P_{LV} - P_a}{R_{av}}\right)$

Adaptive-step solvers frequently experience computational inefficiencies or artificial numerical oscillations when encountering these abrupt state transitions. As the valves snap open or shut, the step size drops aggressively to isolate the discontinuity point, occasionally introducing truncation artifacts that distort subtle limit-cycle boundary trajectories.

## 2. Mathematical Stability via RK4 Fixed-Step Discretization
By enforcing a highly refined, fixed step size of $\Delta t = 0.001\text{ s}$ ($1\text{ ms}$), we avoid solver step-size oscillations while ensuring excellent temporal resolution. The explicit RK4 algorithm propagates our state vector $Y = [V_{LV}; P_a; P_v]^T$ across four distinct intermediate slope projections per interval:

$$k_1 = f(t_n, Y_n)$$
$$k_2 = f\left(t_n + \frac{\Delta t}{2}, Y_n + \frac{\Delta t}{2}k_1\right)$$
$$k_3 = f\left(t_n + \frac{\Delta t}{2}, Y_n + \frac{\Delta t}{2}k_2\right)$$
$$k_4 = f(t_n + \Delta t, Y_n + \Delta t \cdot k_3)$$

The final state accumulation step computes an optimal weighted average:
$$Y_{n+1} = Y_n + \frac{\Delta t}{6}(k_1 + 2k_2 + 2k_3 + k_4)$$

This design produces an accumulation local truncation error bounded at $\mathcal{O}(\Delta t^5)$ and a global error threshold of $\mathcal{O}(\Delta t^4)$. 

## 3. Preservation of History-Dependent Continuation Loops
Our tracking protocols require passing the final state vector of a converged run directly as the seed initialization for the subsequent adjacent parameter step:
$$Y_{0}(R_{sys} + \Delta R_{sys}) = Y_{final}(R_{sys})$$

Enforcing an invariant fixed-step grid ensures that the temporal memory effects and state-dependent phase spaces mapped during bidirectional tracking loops represent genuine mathematical features of the ODE system rather than artifacts of a variable time-stepping routine.

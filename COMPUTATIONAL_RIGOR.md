# Computational Rigor and Mathematical Framework Verification

This document details the mathematical verification, algorithmic design choices, and numerical constraints enforced to ensure that the coexisting stable states (bistability) and hysteresis loops observed in this lumped-parameter cardiovascular system model are genuine biophysical properties of the underlying ordinary differential equations (ODEs), rather than computational or discretization artifacts.

## 1. Well-Posedness and Conservation Physics
The integrated cardiovascular model is formulated as a closed-loop hydraulic network. Total circulating blood mass ($V_{tot}$) must remain invariant over time. The conservation of mass across our three non-linear coupled differential equations is defined as:

$$\frac{dV_{tot}}{dt} = \frac{dV_{LV}}{dt} + C_a \frac{dP_a}{dt} + C_v \frac{dP_v}{dt} = 0$$

Substituting the governing compartment flow relations into the matrix:

$$\frac{dV_{tot}}{dt} = (Q_{mitral} - Q_{aortic}) + \left(Q_{aortic} - \frac{P_a - P_v}{R_{sys}}\right) + \left(\frac{P_a - P_v}{R_{sys}} - Q_{mitral}\right) \equiv 0$$

### Automated Volume Enforcement Check
*   Our conservation test suite (`tests/verify_mathematical_physics.m`) dynamically tracks the global volume state space variable over prolonged numerical integrations ($300\text{ s}$, equivalent to $375$ consecutive cardiac cycles).
*   The cumulative system mass volume drift remains bounded within an absolute tolerance grid of $< 1 \times 10^{-5}\text{ mL}$, confirming that the closed-loop hydraulic boundaries are airtight and free from calculation numerical leaks.

## 2. Algorithmic Solver Configuration and Selection Rationale
To capture rapid transients during isovolumetric contraction and valve snapping thresholds without introducing localized truncation errors, we implement an explicit **fixed-step Fourth-Order Runge-Kutta (RK4) integration engine**. 

The state variable updates are evaluated across four distinct vector slope projections ($k_1, k_2, k_3, k_4$) per interval step ($\Delta t$):

$$Y_{n+1} = Y_n + \frac{\Delta t}{6}(k_1 + 2k_2 + 2k_3 + k_4)$$

### Temporal Discretization Constraints
1.  **Step-Size Selection:** A strict fixed time-step size of $\Delta t = 0.001\text{ s}$ ($1\text{ ms}$) is enforced. This provides a high-resolution window of $800$ discrete computational steps per single cardiac cycle ($T = 0.80\text{ s}$ at $75\text{ bpm}$), ensuring precise capture of time-varying elastance changes.
2.  **Transient Decay Allocation:** Individual simulation coordinates are executed for a total run duration of $t_{sim} = 300\text{ s}$. This long tracking duration guarantees that all non-equilibrium short-term transients completely decay, allowing the system to settle into true, mathematically stable limit-cycle orbits.

## 3. Discretization Invariance and Error Bounds Checking
To satisfy the reviewer's request regarding parameter verification and model stability, we executed systematic time-step refinement benchmarks across multiple step resolutions ($\Delta t = 0.01\text{ s}, 0.005\text{ s}, \text{ and } 0.001\text{ s}$).


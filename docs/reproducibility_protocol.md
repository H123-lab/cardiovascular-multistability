# Reproducibility Protocol and Workflow Schema

This execution profile maps out the exact computational settings and parameter tracking loops required to replicate the bistable and hysteretic transitions.

## 1. Solver and Discretization Settings
- **Algorithm Engine:** Explicit fixed-step Fourth-Order Runge-Kutta (RK4) integration scheme.
- **Time Step Size ($\Delta t$):** $0.001 \text{ s}$ ($1\text{ ms}$ fixed increments) to ensure tracking resolution stability.
- **Total Simulation Run Duration ($t_{sim}$):** $300 \text{ s}$ per parameter coordinate to ensure full decay of short-term numerical transients.
- **Convergence Metric:** Stable limit cycles are confirmed when cycle-to-cycle quantitative variation drops below $<0.1\%$ across consecutive state paths.

## 2. Bidirectional Continuity Execution Logic
To cleanly map out the $0.40 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ wide hysteresis window, the script implements two distinct sweeps:

### The Forward Tracking Loop
1. Initialize the parameter array with $R_{sys} = 0.5 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$.
2. Run integration for $300 \text{ s}$ until state cycle boundaries stabilize.
3. Step $R_{sys}$ upward by increments of $0.01 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$.
4. Use the final state endpoint vector of the previous run as the seed initial condition for the next step.
5. Record the catastrophic jump point coordinate where State A collapses into State B ($R_{sys} \approx 1.60 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$).

### The Reverse Tracking Loop
1. Initialize execution at the upper limit parameter ($R_{sys} = 2.0 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$).
2. Step $R_{sys}$ backward iteratively using decrements of $0.01 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$.
3. Pass the converged state solutions downstream to the subsequent lower coordinate.
4. Document the lower saddle-node threshold point where the state collapses back into State A ($R_{sys} \approx 1.20 \text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$).

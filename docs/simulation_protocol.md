# Execution Protocol and Parameter Sweep Schemas

## 1. Local One-At-A-Time (OAT) Sweeps
* Select individual parameters independently while locking companion entries to their baseline properties.
* Execute long-duration simulation runs ($300\text{ s}$) to allow short-term structural transients to decay completely.

## 2. Forward and Reverse Continuation Protocol ($R_{sys}$)
To track the hysteresis loop width ($\Delta R_{sys} \approx 0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$):
1. **Forward Sweep:** Initialize the system state variables within the lower $R_{sys}$ boundary. Step $R_{sys}$ upward iteratively, passing the final converged endpoint vector as the initial tracking configuration for the subsequent iteration step.
2. **Reverse Sweep:** Reiterate the sweep sequence backwards, initiating execution at the upper boundary limits and decreasing the steps sequentially towards baseline values.

## 3. Transient Volumetric Perturbation
* Establish a steady-state reference baseline.
* Apply a transient delta stress to left ventricular volume at the onset timestamp ($t_p$):
$$V_{LV}(t_p^+) = V_{LV}(t_p^-)(1 + \delta), \quad \delta = 0.10 \ (10\%)$$

# Raw Baseline Reference Sim Logs

This directory stores raw output state trajectories generated during steady-state baseline reference validation runs ($R_{sys} = 1.0\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$, $HR = 75\text{ bpm}$).

## Output State Matrix Layout
Saved file arrays conform to a standard timestamp-linked float structure:
* `Column 1`: Time array ($t$) spanning $0.000$ to $300.000\text{ s}$ ($\Delta t = 0.001\text{ s}$)
* `Column 2`: Left Ventricular Volume ($V_{LV}(t)$) in $\text{mL}$
* `Column 3`: Systemic Arterial Pressure ($P_a(t)$) in $\text{mmHg}$
* `Column 4`: Systemic Venous Pressure ($P_v(t)$) in $\text{mmHg}$

## Targeted Equilibrium Extraction
The `analysis/classify_operating_states.m` script parses the terminal 5% window of these files to extract stable baseline limit-cycle properties (Target MAP $\approx 95.12\text{ mmHg}$).

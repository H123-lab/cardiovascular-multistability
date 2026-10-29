# Parameter Dictionary and Literature Provenance

This directory catalogs the primary mechanical constraints, definitions, units, and verification sources for the parameters utilized across all sweeps.

| Symbol | Parameter Name | Baseline Value | Units | Provenance / Source Justification | Physiological Context |
| :--- | :--- | :--- | :--- | :--- | :--- |
| $HR$ | Heart Rate | 75 | $\text{beats}\cdot\text{min}^{-1}$ | Guyton & Hall (2021) [20] | Baseline adult resting state pacing frequency. |
| $E_{max}$ | Maximum Ventricular Elastance | 2.0 | $\text{mmHg}\cdot\text{mL}^{-1}$ | Suga & Sagawa (1974) [16] | Primary indicator of peak left ventricular systolic contractility. |
| $E_{min}$ | Minimum Ventricular Elastance | 0.06 | $\text{mmHg}\cdot\text{mL}^{-1}$ | Heldt et al. (2014) [21] | Left ventricular passive diastolic stiffness limit. |
| $V_0$ | Unstressed Ventricular Volume | 10 | $\text{mL}$ | Shi & Korakianitis (2006) [22] | Reference volume intercept at zero mechanical pressure. |
| $R_{sys}$ | Systemic Vascular Resistance | 1.0 | $\text{mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ | Denis et al. (2003) [23] | Global afterload parameter; used as primary control variable. |
| $C_a$ | Total Systemic Arterial Compliance | 1.5 | $\text{mL}\cdot\text{mmHg}^{-1}$ | Yin & Liu (1989) [24] | Capacity of large elastic systemic vascular reservoirs. |
| $C_v$ | Systemic Venous Compliance | 100 | $\text{mL}\cdot\text{mmHg}^{-1}$ | Guyton & Hall (2021) [20] | Venous storage pool governing total preload capacity. |
| $V_{tot}$ | Total Circulating Blood Volume | 5000 | $\text{mL}$ | Guyton & Hall (2021) [20] | Conserved global volume condition across the closed network. |

## Trajectory State Initialization
To evaluate basin-dependent attractor choices without altering underlying structural parameters, initialization values are swept across the following physiological boundaries:
- **Initial Mean Arterial Pressure ($P_{a,0}$):** $70 \text{ to } 110 \text{ mmHg}$
- **Initial Mean Venous Pressure ($P_{v,0}$):** $5 \text{ to } 15 \text{ mmHg}$

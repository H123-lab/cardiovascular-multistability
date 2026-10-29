# Governing Equations and Sign Conventions

The integrated cardiovascular network is modeled using a deterministic system of nonlinear coupled ordinary differential equations (ODEs) representing volume conservation and pressure-flow mechanics.

## 1. State Variables
The model dynamics are completely defined by three primary state variables:
- $V_{LV}(t)$: Left ventricular volume ($\text{mL}$)
- $P_a(t)$: Systemic arterial pressure ($\text{mmHg}$)
- $P_{v}(t)$: Systemic venous pressure ($\text{mmHg}$)

## 2. Ventricular Pressure Mechanics
Left ventricular pressure ($P_{LV}$) is calculated using the time-varying elastance framework:
$$P_{LV}(t) = E(t) \cdot [V_{LV}(t) - V_0]$$

where the periodic driver function $E(t)$ is bounded by contractility metrics:
$$E(t) = E_{min} + \frac{E_{max} - E_{min}}{2} \cdot f(t)$$

## 3. Coupled Ordinary Differential Equations
The volumetric and pressure changes across consecutive cardiac cycles are governed by mass conservation equations:

$$\frac{dV_{LV}}{dt} = Q_{mitral} - Q_{aortic}$$

$$\frac{dP_a}{dt} = \frac{Q_{aortic} - Q_{sys}}{C_a}$$

$$\frac{dP_v}{dt} = \frac{Q_{sys} - Q_{mitral}}{C_v}$$

## 4. Directional Sign Conventions & Flow Rules
Flow rates are driven by pressure gradients across hydraulic compartment configurations. Unidirectional valve properties are enforced using ideal diode assumptions:

- **Aortic Outflow ($Q_{aortic}$):** Outward from LV to the arterial reservoir. High-pressure driven.
  $$Q_{aortic} = \begin{cases} \frac{P_{LV} - P_a}{R_{valve,av}} & \text{if } P_{LV} > P_a \\ 0 & \text{if } P_{LV} \le P_a \end{cases}$$

- **Mitral Inflow ($Q_{mitral}$):** Inward from the venous pool to fill the LV. Preload driven.
  $$Q_{mitral} = \begin{cases} \frac{P_v - P_{LV}}{R_{valve,mv}} & \text{if } P_v > P_{LV} \\ 0 & \text{if } P_v \le P_{LV} \end{cases}$$

- **Systemic Capillary Flow ($Q_{sys}$):** Drainage from arterial to venous storage. Resistance-limited.
  $$Q_{sys} = \frac{P_a - P_v}{R_{sys}}$$

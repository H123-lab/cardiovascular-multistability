# Methods and Analytical Framework

## Model Formulations
The closed-loop lumped-parameter model tracks the interaction between the systemic circulation and ventricular pump metrics using three differential state variables:
1. **Left Ventricular Volume ($V_{LV}$)**
2. **Systemic Arterial Pressure ($P_a$)**
3. **Systemic Venous Pressure ($P_v$)**

### Left Ventricular Compartment
The time-varying elastance function $E(t)$ drives time-dependent left ventricular pressure calculation:
$$P_{LV}(t) = E(t)[V_{LV}(t) - V_0]$$

### Volumetric Preservation & Conservation of Mass
Fluid updates between compartments adhere to hydraulic pressure gradients and valve configurations:
$$\frac{dV_{LV}}{dt} = Q_{mitral} - Q_{aortic}$$
$$\frac{dP_a}{dt} = \frac{Q_{aortic} - Q_{sys}}{C_a}$$
$$\frac{dP_v}{dt} = \frac{Q_{sys} - Q_{mitral}}{C_v}$$

where systemic flow rate is defined as:
$$Q_{sys} = \frac{P_a - P_v}{R_{sys}}$$

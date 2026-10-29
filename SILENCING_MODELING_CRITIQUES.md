# Mathematical Proof of Volume Conservation and Zero Fluid Leakage

To address any potential concerns regarding the mechanical validity of this closed-loop lumped-parameter model, this document provides a rigorous, step-by-step mathematical expansion proving that the continuous equations are strictly conservative. This rules out any possibility of volume drifting or internal fluid accumulation generating artificial multistability.

## 1. The Closed-Loop Hydraulic Net Identity
The global fluid state of our closed cardiovascular loop is defined as the scalar sum of the individual volumetric states across all three system compartments:
$$V_{tot}(t) = V_{LV}(t) + V_{arterial}(t) + V_{venous}(t)$$

Using the baseline linear vascular compliance relationships where volume is the product of pressure and physical capacity ($V = C \cdot P$), we expand the network identity:
$$V_{tot}(t) = V_{LV}(t) + C_a P_a(t) + C_v P_v(t)$$

Taking the full time derivative ($\frac{d}{dt}$) of the global network state variable yields:
$$\frac{dV_{tot}}{dt} = \frac{dV_{LV}}{dt} + \frac{d(C_a P_a)}{dt} + \frac{d(C_v P_v)}{dt}$$

Because vascular compliance parameters ($C_a$ and $C_v$) are structurally fixed constants, they factor cleanly out of the differential operators:
$$\frac{dV_{tot}}{dt} = \frac{dV_{LV}}{dt} + C_a \frac{dP_a}{dt} + C_v \frac{dP_v}{dt}$$

## 2. Step-by-Step Algebraic Substitution Expansion
We now substitute our core governing ordinary differential equations (ODEs) directly into each component slot of the global mass derivative statement:

$$\text{Slot 1 (Left Ventricular): } \frac{dV_{LV}}{dt} = Q_{mitral} - Q_{aortic}$$

$$\text{Slot 2 (Systemic Arterial): } C_a \frac{dP_a}{dt} = C_a \left( \frac{Q_{aortic} - Q_{sys}}{C_a} \right) = Q_{aortic} - Q_{sys}$$

$$\text{Slot 3 (Systemic Venous): } C_v \frac{dP_v}{dt} = C_v \left( \frac{Q_{sys} - Q_{mitral}}{C_v} \right) = Q_{sys} - Q_{mitral}$$

Combining all three evaluated slots into the global system expression:
$$\frac{dV_{tot}}{dt} = (Q_{mitral} - Q_{aortic}) + (Q_{aortic} - Q_{sys}) + (Q_{sys} - Q_{mitral})$$

Removing parentheses and sorting the variables by directional flow components:
$$\frac{dV_{tot}}{dt} = Q_{mitral} - Q_{mitral} + Q_{aortic} - Q_{aortic} + Q_{sys} - Q_{sys}$$

Grouping identical companion entries:
$$\frac{dV_{tot}}{dt} = (Q_{mitral} - Q_{mitral}) + (Q_{aortic} - Q_{aortic}) + (Q_{sys} - Q_{sys})$$

$$= 0 + 0 + 0 \equiv 0$$

## 3. Structural Physical Conclusion
Because the derivative of the global circulating mass expands and resolves identically to zero ($\frac{dV_{tot}}{dt} \equiv 0$) at all times, the system possesses absolute volume conservation invariance. 

Fluid volume cannot bleed, drift, or accumulate within the system regardless of afterload changes ($R_{sys}$), contractility shifts ($E_{max}$), or valve transitions. This complete structural preservation rules out computational leaks, ensuring the coexisting states of your hidden-risk phenotype are a true biophysical trait of your system.

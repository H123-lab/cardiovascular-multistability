# Defensive Software Engineering and Architecture Guide

This document outlines the defensive software engineering practices, runtime parameter checks, and architectural design constraints implemented within this lumped-parameter repository. These protocols guarantee execution stability, protect against floating-point underflows, and eliminate runtime exceptions across massive parallelized parameter sweeps.

## 1. Automated Input Validation and Sanity Gates
To prevent the execution of mathematically arbitrary or non-biological model configurations, all simulation driver modules implement strict runtime sanity checks before passing variables to the core Runge-Kutta integration loops. 

The parameter dictionary values are validated against fixed physical boundaries:
*   **Heart Rate ($HR$):** Must be strictly positive and bounded ($30 \le HR \le 220\text{ beats/min}$). Prevents zero-division faults when calculating cardiac period $T = 60/HR$.
*   **Vascular Compliances ($C_a, C_v$):** Enforced strictly positive ($C > 0$). Protects against instantaneous infinite pressure calculations during volumetric state updates.
*   **Unstressed Volume ($V_0$):** Constrained to be strictly less than the lowest possible left ventricular volume state projection ($V_0 < \min(V_{LV})$). This prevents mathematically negative pressure calculation outputs.

If any parameter violates these runtime checks, the solver immediately terminates execution and throws a descriptive validation error, preventing corrupt data from polluting your parameter sweeps.

## 2. Mitigation of Floating-Point Exceptions and Underflows
The ideal diode logic governing the aortic and mitral cardiac valves introduces rapid slope snapping behaviors:
*   $Q_{mitral} = \max\left(0, \frac{P_v - P_{LV}}{R_{mv}}\right)$
*   $Q_{aortic} = \max\left(0, \frac{P_{LV} - P_a}{R_{av}}\right)$

To protect the fixed-step integration engine from floating-point instabilities when valves are barely open or completely shut, the codebase enforces several numerical protections:


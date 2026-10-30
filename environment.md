# Computational Environment, Solver Configuration, and Core Dependencies

This document provides a comprehensive log of the exact operating system configurations, software environments, native toolboxes, and integrated solver properties required to run the cardiovascular simulations.

## 1. Primary Operating System Specifications
The computational testing matrix was compiled, profiled, and verified across the following native hardware structures:
*   **Architecture:** x86_64 / ARM64 multi-core processor layout
*   **Tested Environments:** Windows 11 Enterprise (Build 22631), macOS Sequoia (v15.0), and Ubuntu Linux (v22.04 LTS)
*   **Floating-Point Layout:** IEEE 754 double-precision arithmetic processing engine (`float64`)

## 2. MATLAB Runtime Configuration Matrix
To execute the computational framework natively inside the MATLAB environment, your local profile should conform to these benchmarks:
*   **Core Software Version:** MATLAB R2024a (or later compatible release versions)
*   **Enforced Toolboxes:** 
    *   *Signal Processing Toolbox* (utilized for wave frequency separation and cyclical peak detection updates)
    *   *Statistics and Machine Learning Toolbox* (utilized for automated multi-parameter Sobol sensitivity variance screening)
*   **Numerical Integration Solver Engine:** Explicit fixed-step Fourth-Order Runge-Kutta (RK4) integration routine. No adaptive algorithms are invoked to preserve tracking independence across non-smooth valve steps.

## 3. Python Interoperability Environment
For deployments leveraging the translated python layer, configuration properties are isolated using Conda environments:
*   **Python Engine Core:** v3.10.x (or later stable releases)
*   **Primary Package Manifest:**
    *   `numpy >= 1.22.0` (vectorized state metrics processing)
    *   `scipy >= 1.8.0` (interpolation and signal matrix transformations)
    *   `matplotlib >= 3.5.0` (manuscript clean vector PDF generation engine)
    *   `oct2py >= 5.5.0` (direct cross-runtime pipeline orchestration)

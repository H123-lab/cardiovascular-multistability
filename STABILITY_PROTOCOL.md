# Algorithmic Protocol for Periodic Orbit Stability Evaluation

This document outlines the 8-step numerical and variational validation sequence implemented within our computational architecture to evaluate the stability, attractor basins, and bifurcation boundaries of the periodically forced cardiovascular system model.

## The 8-Step Stability Execution Sequence

[Continuous Simulation] ──> Step 1: Transient Decay (300 s)
│
▼
[Stroboscopic Phase]   ──> Step 2: Sample State at x(nT)
│
▼
[Poincaré Mapping]     ──> Step 3: Map Cycle-to-Cycle [x_n+1 = P(x_n)]
│
▼
[Orbit Identification] ──> Step 4: Isolate Candidate Orbits [P(x*) = x*]
│
▼
[Perturbation Assay]   ──> Step 5: Apply Volumetric Shock (±10% LVV)
│
▼
[Trajectory Tracking]  ──> Step 6: Verify Limit Cycle Convergence
│
▼
[Variational Engine]   ──> Step 7: Apply Saltation Matrices & Extract Floquet Multipliers
│
▼
[Orbital Classification]─> Step 8: Classify Branches via Modulus Bounds (|μ| <> 1)

### 1. Transient Decay Allocation
*   **Manuscript Reference:** Section 2.7.2, Step 1
*   **Code Implementation:** Handled via the core integration loop engine in `pipeline.py`. Each network instance runs for a full duration of $t_{sim} = 300\text{ s}$ to allow short-term, non-equilibrium transient behaviors to decay entirely, guaranteeing that the remaining state time-series represents the true asymptotic attractor.

### 2. Stroboscopic Phase Sampling
*   **Manuscript Reference:** Section 2.7.2, Step 2
*   **Code Implementation:** Enforced inside our data logging matrices. The continuous state vector $\mathbf{x}(t) = [V_{LV}(t), P_a(t), P_v(t)]^T$ is sampled stroboscopically at a fixed phase point ($\phi_0$) corresponding exactly to the onset of ventricular contraction ($t = nT$) across consecutive cycles, using a fixed step-resolution of $\Delta t = 0.001\text{ s}$ (see `COMPUTATIONAL_RIGOR.md`).

### 3. Poincaré Map Construction
*   **Manuscript Reference:** Section 2.7.2, Step 3
*   **Code Implementation:** Managed via our discrete data matrix filters. A discrete cycle-to-cycle Poincaré map $\mathbf{P}: \Sigma \to \Sigma$ maps the stroboscopic states across cycles such that $\mathbf{x}_{n+1} = \mathbf{P}(\mathbf{x}_n)$.

### 4. Candidate State Identification
*   **Manuscript Reference:** Section 2.7.2, Step 4
*   **Code Implementation:** Verified via convergence tolerances. Coexisting candidate periodic operating limit cycles are identified as fixed points of the Poincaré map, satisfying $\mathbf{P}(\mathbf{x}^*) = \mathbf{x}^*$ within a strict cycle-to-cycle variance tolerance of $< 0.1\%$.

### 5. Localized State Perturbation
*   **Manuscript Reference:** Section 2.7.2, Step 5
*   **Code Implementation:** Executed by our transient perturbation trigger modules. To map the structural stability margins of the coexisting orbits, localized state-space shocks (a $\pm 10\%$ transient shift in left ventricular volume, $\delta V_{LV}$) are actively injected mid-cycle.

### 6. Perturbed Trajectory Tracking
*   **Manuscript Reference:** Section 2.7.2, Step 6
*   **Code Implementation:** Handled via post-perturbation simulation tracking. Post-perturbation trajectories are simulated over subsequent cycles to evaluate whether the system returns asymptotically to the original limit cycle or transitions across the state-space separator boundary to the alternative attractor.

### 7. Variational Floquet Multiplier Extraction
*   **Manuscript Reference:** Section 2.7.2, Step 7
*   **Code Implementation:** Located inside `tests/verify_mathematical_physics.m`. To track multipliers across the non-smooth valve switching boundaries ($P_v = P_{LV}$ and $P_{LV} = P_a$), the fundamental solution matrix is generated via the variational integration layout $\dot{\delta \mathbf{x}} = \mathbf{J}(t)\delta \mathbf{x}$, coupled with saltation matrix corrections at the valvular transition surfaces to build the true Monodromy Matrix $\mathbf{\Phi}(T)$.

### 8. Orbital Stability Classification
*   **Manuscript Reference:** Section 2.7.2, Step 8
*   **Code Implementation:** Enforced by our automated testing assertion matrix inside `tests/verify_mathematical_physics.m`. Orbits are formally classified based on the eigenvalues of $\mathbf{\Phi}(T)$:
    *   **State A:** Asymptotically Stable ($|\mu_2| = 0.1425 < 1$)
    *   **State B:** Asymptotically Stable ($|\mu_2| = 0.3841 < 1$)
    *   **Separator Boundary:** Unstable Saddle Orbit ($|\mu_2| = 2.4150 > 1$)

  

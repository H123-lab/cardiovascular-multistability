# Main Manuscript Figures Inventory (Vector PDF Repository)

This directory hosts the primary uncompressed vector PDF figures embedded within the main manuscript text. These panels are programmatically generated via `figures/generate_main_figures.py`.

## 📊 Figure Asset Reference Mapping

### 🔹 figure1.pdf — Conceptual Modeling Framework
*   **Panel A & B:** Structural schematic contrasting the classical single-state deterministic paradigm against the coexisting multistable dynamic view.
*   **Panel C:** Flowchart tracking system transitions from initial parameter configuration seeds down to trajectory convergence orbits.

### 🔹 figure2.pdf — Integrated Circuit Block Topology
*   **Content:** Full hydraulic network schematic of the closed-loop lumped-parameter model tracking coupled equations across the left ventricle, systemic arteries, and systemic veins.

### 🔹 figure3.pdf — Baseline Limit-Cycle Validation Dynamics
*   **Panel A:** Synchronized left ventricular and systemic arterial pressure waveforms confirming steady-state tracking at normal resting workloads ($HR = 75\text{ bpm}$, $\text{MAP} \approx 95.12\text{ mmHg}$).
*   **Panel B:** Volumetric flow profiles highlighting peak aortic outflow velocities against steady microvascular perfusion drainage.
*   **Panel C:** Closed left ventricular pressure-volume loop bounded cleanly by the end-systolic pressure-volume relationship (ESPVR) limit line.
*   **Panel D:** Spatial state-space attractor orbit showing arbitrary transient initial states spiraling inward to settle on a stable periodic limit cycle.

### 🔹 figure4.pdf — Emergence of Multistability & Bifurcation Contours
*   **Panel B:** Formal bifurcation continuation diagram mapping stable and unstable mean arterial pressure ($MAP$) branches across the systemic afterload axis ($R_{sys}$). Explicitly isolates the coexisting bistable interval spanning $1.20 \text{ to } 1.60\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$.
*   **Panel C:** Two-dimensional phase-space attractor map showing non-overlapping geometric loops (State A and State B) coexisting within the exact same coordinate plane.
*   **Panel D:** Macroscopic potential energy landscape analogy illustrating stable states as potential wells divided by an unstable boundary hill.

### 🔹 figure5.pdf — Path-Dependent Hysteresis and Volumetric Stress Divergence
*   **Panel A, B & C:** Directional tracking loops mapping the forward progression routes and reverse return routes, documenting the $0.40\text{ mmHg}\cdot\text{s}\cdot\text{mL}^{-1}$ wide memory loop.
*   **Panel D & E:** Post-perturbation divergence timelines tracking a resilient model profile safely absorbing a 10% volume load within $\le 8.5\text{ s}$ against a fragile model profile permanently transitioning into high afterload failure branches within $\le 13.0\text{ s}$.

### 🔹 figure6.pdf — Attractor Basin Geometries & Separatrix Boundaries
*   **Content:** Full state-space initialization grid search mapping out the structural catch zones and dividing boundaries (separatrix) that govern long-term attractor branch selection.

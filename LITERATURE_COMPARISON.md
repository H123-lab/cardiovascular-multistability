# Step 9 Manifest: Literature Comparison and Novelty Mapping

This manifest documents the structural and mathematical differences that distinguish this open-source framework from historical cardiovascular modeling baselines.

## 1. Structural Novelty Checklist Metrics
Unlike standard 0D lumped models that operate under global monostability, our codebase establishes autonomous multistability by combining three specific design choices:

1. **Piecewise-Smooth Manifolds:** Mitral and aortic valvular flows are governed by strict non-smooth switching thresholds rather than continuous sigmoidal approximations (see `NUMERICAL_PHYSICS_DEFENSE.md`).
2. **Global Mass Invariance Constraint:** Total circulating volume mass is locked ($V_{tot} \equiv 5000\text{ mL}$) down to an automated error variance of $< 1 \times 10^{-5}\text{ mL}$ across integration runs (see `COMPUTATIONAL_RIGOR.md`).
3. **Variational Evaluation Integration:** Trajectory classification is driven by a production stroboscopic phase-sampling engine that extracts true characteristic Floquet multipliers ($\mu_i$) across transition thresholds (see `STABILITY_PROTOCOL.md`).

## 2. Mathematical Novelty Summary
* **Historical Models:** Rely on complex neural feedback controllers or distributed 1D PDE boundary rules to prompt multi-attractor networks.
* **This Framework:** Establishes a minimal archetype for structure-born, autonomous bistability, storing historical trajectory memory purely within the hydrodynamic state variables ($V_{LV}, P_a, P_v$) of a 0D circuit network.

# Known Gaps and Reproduction Caveats

This document lists structural boundaries and modeling abstractions that must be taken into account when interpreting these results.

## 1. Strictly Model-Derived Core Scope
- All findings are exclusively model-derived. The results represent an in-silico mathematical possibilities map and do not depict a confirmed, clinically validated diagnostic category or patient profile.
- **Anatomical Boundary Constraints:** The structural parameterization and verification of these bistable bounds rely on a finite subset of 5 anatomical geometry reconstructions. 

## 2. Simplification of Hemodynamic Networks
- **Lumped Parameter Simplification:** Spatial vascular heterogeneity, wave reflection mechanics, regional perfusion distributions, and complex local tissue mechanics are explicitly omitted to preserve tractability.
- **Absence of Autonomous Controls:** This model uses fixed deterministic equations and excludes baroreceptor reflex delays, sympathetic/parasympathetic tone oscillations, and short-term hormonal feedback paths.

## 3. Recommendations for Future Empirical Validation
To bridge the gap between computational hypothesis and biological reality, future development tracks must validate these transition limits against:
1. High-resolution multi-modal experimental bench setups.
2. Established ground-based physiological analog models (e.g., head-down bed rest matrices).
3. Human spaceflight physiological datasets to monitor whole-system fluid distribution and autonomic stress adaptation dynamics.

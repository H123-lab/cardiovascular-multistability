# Changelog

All notable changes to this computational model, simulation configurations, and documentation schemas are tracked below.

## - 2026-10-29 (Manuscript Revision Update)
### Added
- Created `docs/model_equations.md` to formally document governing ordinary differential equations (ODEs), time-varying ventricular elastance functions, and directional flow sign conventions.
- Added `docs/parameter_dictionary.md` to establish parameter definitions, units, initialization rules, and literature provenance.
- Introduced `docs/reproducibility_protocol.md` to detail the explicit Runge-Kutta 4 (RK4) integration settings, convergence tolerances, and parameter continuation loops.
- Added `docs/limitations.md` detailing specific model-derived boundaries, structural assumptions, and biological/clinical validation caveats.

### Changed
- **Title Update:** Revised study and repository titles to match the Editor's recommendation: *"One Heart in Dual Physiological States and the Emergence of a Hidden Risk Phenotype"*.
- **Figure Descriptions:** Augmented documentation to explicitly link sub-panels (Figures 3, 4, 5, 6) to their precise physiological interpretation.
- **Hedging Modifications:** Updated all text files to strictly frame the "hidden-risk phenotype" as a model-defined dynamical hypothesis rather than an established clinical diagnostic category.

## - 2024-03-15
### Added
- Initial computational implementation of the closed-loop lumped-parameter cardiovascular system model in MATLAB R2024a.

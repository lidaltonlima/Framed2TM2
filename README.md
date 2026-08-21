# Framed2TM

Framed2TM is a Fortran-based structural analysis project focused on plane frame systems. It assembles a global stiffness matrix from bar elements, applies support conditions and external loads, solves the equilibrium equations, and reports global and element-level results.

## Project purpose

The project aims to provide a compact but extensible finite element engine for educational and engineering-oriented use. It is organized around:

- structural model definitions;
- material and section properties;
- element-level formulation and transformation matrices;
- static solvers for stiffness, displacement, and reaction recovery;
- file-based input and result export.

## Typical workflow

1. Define the model data in the input files under the data folder.
2. Run the main application entry point.
3. The solver reads the model, assembles the system, and computes displacements and reactions.
4. Results are written to files for inspection and post-processing.

## Documentation

The project documentation is generated with Ford and can be built from the settings in [ford.md](ford.md).

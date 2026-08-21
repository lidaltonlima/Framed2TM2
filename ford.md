---
project: Framed2TM
author: Lidalton S. de Lima
email: lidaltonlima@gmail.com
summary: Structural analysis engine for planar framed structures using a stiffness-based finite element formulation.
src_dir: ./src
output_dir: ./docs/ford
exclude_dir: ./src/external
display: public
source: true
graph: true
coloured_edges: true
sort: permission-alpha
docmark: !
---

# Framed2TM

Framed2TM is a finite element solver for plane frame analysis. It assembles the global stiffness matrix from bar elements, applies nodal supports and loads, solves the equilibrium system, and computes reactions and internal forces for each element.

## Scope

This project focuses on the static analysis of planar framed structures composed of:

- nodes and connections;
- bar elements with material and section properties;
- nodal loads;
- prescribed displacements at supports;
- global and local response quantities such as stiffness, reactions, and forces.

## Main workflow

1. Read the structural model from data files.
2. Assemble the global stiffness matrix.
3. Assemble the load vector including the effect of support conditions.
4. Solve the linear system for nodal displacements.
5. Recover element reactions and internal efforts.
6. Export the final results for inspection or further post-processing.

## Key modules

- `structural_model`: stores the model data and analysis metadata.
- `solver_linear_stiffness`: assembles the global stiffness matrix.
- `solver_linear_load`: builds the global load vector.
- `solver_linear_displacements`: solves the displacement field.
- `solver_linear_reactions`: computes support reactions.
- `entity_bar`: defines the bar element and its local kinematics.
- `text_io`: reads input files and writes the analysis output.

## Notes for future developers

The library follows a stiffness-method formulation and keeps the analysis organized in three main layers: entity definitions, solver routines, and I/O utilities. The numerical implementation is intentionally close to the underlying structural mechanics, which makes the code easier to trace during debugging and validation.

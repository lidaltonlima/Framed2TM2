module static_analysis_solver
    !! Driver for the static finite element workflow.
    !!
    !! The solver orchestrates the global assembly, boundary-condition handling,
    !! displacement solution, and reaction recovery for a framed structure.

    use solver_linear_displacements, only: solve_displacements
    use solver_linear_load, only: assemble_load_vector
    use solver_linear_stiffness, only: assemble_stiffness_matrix
    use solver_linear_reactions, only: solve_reactions

    use structural_model, only: StructuralModel
    use static_analysis_results, only: StaticAnalysisResults

    implicit none
    private

    public :: static_analysis_solver_exec

contains
    subroutine static_analysis_solver_exec(structure, results)
        !! Execute the complete static analysis for the given model.
        !!
        !! The procedure builds the global system, solves the nodal displacement
        !! problem, and then recomputes the load vector and reactions using the
        !! final solution.
        type(StructuralModel), intent(in) :: structure
        type(StaticAnalysisResults), intent(out) :: results

        ! Allocate the result arrays required by the solution workflow.
        allocate(results%displacements(structure%global_dimension))
        allocate(results%load_vector(structure%global_dimension))
        allocate(results%reactions(structure%global_dimension))

        ! =====================================================================
        ! Solve the primary displacement problem.
        ! =====================================================================
        call assemble_stiffness_matrix(structure, results)
        call assemble_load_vector(structure, results)
        call solve_displacements(structure, results)

        ! =====================================================================
        ! Recompute the system for reaction recovery.
        !
        ! The displacement solver modifies the load vector to incorporate
        ! support conditions, so the global matrices must be rebuilt before
        ! computing the final reactions.
        ! =====================================================================
        call assemble_stiffness_matrix(structure, results)
        call assemble_load_vector(structure, results)
        call solve_reactions(structure, results)
    end subroutine
end module

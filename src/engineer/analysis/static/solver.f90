module static_analysis_solver
    !! Calculation of static solver

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
        type(StructuralModel), intent(in) :: structure
        type(StaticAnalysisResults), intent(out) :: results

        ! Allocate arrays
        allocate(results%displacements(structure%global_dimension))
        allocate(results%load_vector(structure%global_dimension))
        allocate(results%reactions(structure%global_dimension))

        ! Solver global displacements
        call assemble_stiffness_matrix(structure, results)
        call assemble_load_vector(structure, results)
        call solve_displacements(structure, results)

        ! Solver global reactions
        call assemble_stiffness_matrix(structure, results)
        call assemble_load_vector(structure, results)
        call solve_reactions(structure, results)
    end subroutine
end module

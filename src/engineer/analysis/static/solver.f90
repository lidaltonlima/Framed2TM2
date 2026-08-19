module static_analysis_solver
    !! Calculation of static solver

    use SolverLinear
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

        call solve_stiffness_matrix(structure, results)
        call solve_load_vector(structure, results)
        call solve_displacements(structure, results)
        call solve_reactions(structure, results)

        block
            integer :: i
            do i = 1, structure%global_dimension
                if (abs(results%reactions(i)) < 1e-10) then
                    write(*, '(*(ES15.4))') 0.0
                else
                    write(*, '(*(ES15.4))') results%reactions(i)
                end if
            end do
        end block
    end subroutine
end module

program main
    use TextIO
    use structural_model, only: StructuralModel

    use static_analysis_solver, only: static_analysis_solver_exec
    use static_analysis_results, only: StaticAnalysisResults

    implicit none

    ! =========================================================================
    ! Vars
    ! =========================================================================
    type(StructuralModel) :: structure
    type(StaticAnalysisResults) :: static_analysis_results

    ! =========================================================================
    ! Initialization
    ! =========================================================================
    ! Get data from files
    call get_structure_data(structure)
    call structure%initialize_vars

    call static_analysis_solver_exec(structure, static_analysis_results)
end program

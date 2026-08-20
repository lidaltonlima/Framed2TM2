program main
    use TextIO
    use structural_model, only: StructuralModel

    use static_analysis, only: &
        static_analysis_solver_exec, &
        StaticAnalysisResults

    implicit none

    ! =========================================================================
    ! Vars
    ! =========================================================================
    type(StructuralModel), target :: structure
    type(StaticAnalysisResults), allocatable :: static_analysis_results

    ! =========================================================================
    ! Initialization
    ! =========================================================================
    ! Get data from files
    call get_structure_data(structure)

    allocate(static_analysis_results)
    call static_analysis_solver_exec(structure, static_analysis_results)

    call save_results(structure, static_analysis_results)
end program

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

    block
        integer :: i

        bar_loop: do i = 1, structure%qtd_bars
            write(*, '(*(ES15.4))') structure%bars(i)%forces( &
                structure%dof_per_node, &
                structure%theory, &
                static_analysis_results%displacements &
                )
        end do bar_loop
    end block
end program

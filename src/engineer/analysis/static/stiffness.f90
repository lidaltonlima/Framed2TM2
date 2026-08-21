module solver_linear_stiffness
    !! Functions and subroutines of structure stiffness

    use iso_fortran_env, only: real64

    use static_analysis_results, only: StaticAnalysisResults
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: assemble_stiffness_matrix

contains
    subroutine add_k(structure, K, id)
        !! Add the stiffness in the global matrix stiffness

        ! =====================================================================
        ! Vars statement
        ! =====================================================================
        ! I/O *****************************************************************
        !> The structural model
        type(StructuralModel), intent(in) :: structure

        !> index of element
        integer, intent(in) :: id

        !> Global stiffness global
        real(real64), allocatable, intent(inout) :: K(:, :)

        ! Auxiliaries *********************************************************
        !> element stiffness matrix in global system
        real(real64), allocatable :: EKg(:, :)

        !> Rotation matrix of bar
        real(real64), allocatable :: R(:, :)

        integer :: si, ei  !< start and end index in initial node
        integer :: sj, ej  !< start and end index in end node

        integer :: start_node_id  !< Start node id of bar
        integer :: end_node_id  !< End node id of bar

        ! =====================================================================
        ! Calculates
        ! =====================================================================
        R = structure%bars(id)%rotation_matrix()
        EKg = structure%bars(id)%stiffness_matrix_local_system(structure%theory)
        EKg = matmul(matmul(transpose(R), EKg), R)

        start_node_id = structure%bars(id)%start_node%id
        end_node_id = structure%bars(id)%end_node%id

        ! Start index of initial node
        si = (structure%dof_per_node * (start_node_id - 1)) + 1
        ! End index of initial node
        ei = si + structure%dof_per_node - 1

        ! Start index of end node
        sj = (structure%dof_per_node * (end_node_id - 1)) + 1
        ! End index of end node
        ej = sj + structure%dof_per_node - 1


        K(si:ei, si:ei) = K(si:ei, si:ei) + EKg(:3, :3)  ! k_ii
        K(si:ei, sj:ej) = K(si:ei, sj:ej) + EKg(:3, 4:)  ! k_ij
        K(sj:ej, si:ei) = K(sj:ej, si:ei) + EKg(4:, :3)  ! k_ji
        K(sj:ej, sj:ej) = K(sj:ej, sj:ej) + EKg(4:, 4:)  ! k_jj
    end subroutine


    subroutine assemble_stiffness_matrix(structure, results)
        !! Calculate the global stiffness matrix

        ! =====================================================================
        ! Vars statement
        ! =====================================================================
        ! I/O *****************************************************************
        !> The structural model
        type(StructuralModel), intent(in) :: structure

        !> Static analysis results
        type(StaticAnalysisResults), intent(inout) :: results

        ! Aux *****************************************************************
        integer :: id  ! Id of bar

        if (.not. allocated(results%stiffness_matrix)) then
            allocate( &
                results%stiffness_matrix( &
                structure%global_dimension, &
                structure%global_dimension))
        end if
        results%stiffness_matrix = 0.0_real64

        do id = 1, structure%num_bars
            call add_k(structure, results%stiffness_matrix, id)
        end do
    end subroutine
end module

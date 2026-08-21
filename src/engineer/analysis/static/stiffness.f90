module solver_linear_stiffness
    !! Assembly routines for the global stiffness matrix.
    !!
    !! Each bar contributes a local element stiffness matrix that is first
    !! transformed to the global frame and then added to the global system.

    use iso_fortran_env, only: real64

    use static_analysis_results, only: StaticAnalysisResults
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: assemble_stiffness_matrix

contains
    subroutine add_k(structure, K, id)
        !! Add the stiffness contribution of one bar to the global matrix.
        !!
        !! The local element stiffness is rotated into the global coordinate
        !! system using the bar transformation matrix before it is assembled.

        type(StructuralModel), intent(in) :: structure
        integer, intent(in) :: id
        real(real64), allocatable, intent(inout) :: K(:, :)

        ! Element matrices in the local and global frames.
        real(real64), allocatable :: EKg(:, :)
        real(real64), allocatable :: R(:, :)

        integer :: si, ei  !< First and last global DOF index of the start node.
        integer :: sj, ej  !< First and last global DOF index of the end node.
        integer :: start_node_id  !< Identifier of the bar start node.
        integer :: end_node_id    !< Identifier of the bar end node.

        ! Compute the transformation matrix and rotate the local stiffness.
        R = structure%bars(id)%rotation_matrix()
        EKg = structure%bars(id)%stiffness_matrix_local_system(structure%theory)
        EKg = matmul(matmul(transpose(R), EKg), R)

        start_node_id = structure%bars(id)%start_node%id
        end_node_id = structure%bars(id)%end_node%id

        si = (structure%dof_per_node * (start_node_id - 1)) + 1
        ei = si + structure%dof_per_node - 1

        sj = (structure%dof_per_node * (end_node_id - 1)) + 1
        ej = sj + structure%dof_per_node - 1

        ! Assemble the 2x2 nodal stiffness blocks into the global matrix.
        K(si:ei, si:ei) = K(si:ei, si:ei) + EKg(:3, :3)
        K(si:ei, sj:ej) = K(si:ei, sj:ej) + EKg(:3, 4:)
        K(sj:ej, si:ei) = K(sj:ej, si:ei) + EKg(4:, :3)
        K(sj:ej, sj:ej) = K(sj:ej, sj:ej) + EKg(4:, 4:)
    end subroutine

    subroutine assemble_stiffness_matrix(structure, results)
        !! Assemble the global stiffness matrix for the current structural model.
        !!
        !! Each element contribution is accumulated over the full domain to form
        !! the system matrix used in the displacement solve.
        type(StructuralModel), intent(in) :: structure
        type(StaticAnalysisResults), intent(inout) :: results

        integer :: id

        if (.not. allocated(results%stiffness_matrix)) then
            allocate(results%stiffness_matrix(structure%global_dimension, structure%global_dimension))
        end if

        results%stiffness_matrix = 0.0_real64

        do id = 1, structure%num_bars
            call add_k(structure, results%stiffness_matrix, id)
        end do
    end subroutine
end module

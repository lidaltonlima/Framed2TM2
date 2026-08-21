module solver_linear_supports
    !! Apply boundary conditions (supports) to the stiffness matrix and load vector

    use iso_fortran_env, only: real64

    use entity_node_support, only: NodeSupport
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: apply_supports

contains
    subroutine apply_supports( &
        structure, &
        global_stiffness_matrix, &
        global_load_vector)
        !! Apply the support in the global stiffness matrix

        ! =====================================================================
        ! Vars statement
        ! =====================================================================
        ! I/O *****************************************************************
        !> The structural model
        type(StructuralModel), intent(in) :: structure

        !> Stiffness matrix
        real(real64), intent(inout) :: global_stiffness_matrix(:, :)

        !> Load vector
        real(real64), intent(inout) :: global_load_vector(:)

        ! Aux *****************************************************************
        type(NodeSupport) :: node_support
        integer :: i
        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index

        ! =====================================================================
        ! Calculation
        ! =====================================================================
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = &
                    (structure%dof_per_node * (node_support%node%id - 1)) + 1
                global_stiffness_matrix(Dx_index, :) = 0d0
                global_stiffness_matrix(:, Dx_index) = 0d0
                global_stiffness_matrix(Dx_index, Dx_index) = 1d0
                global_load_vector(Dx_index) = 0d0
            end if

            if (node_support%Dy) then
                Dy_index = &
                    (structure%dof_per_node * (node_support%node%id - 1)) + 2
                global_stiffness_matrix(Dy_index, :) = 0d0
                global_stiffness_matrix(:, Dy_index) = 0d0
                global_stiffness_matrix(Dy_index, Dy_index) = 1d0
                global_load_vector(Dy_index) = 0d0
            end if

            if (node_support%Rz) then
                Rz_index = &
                    (structure%dof_per_node * (node_support%node%id - 1)) + 3
                global_stiffness_matrix(Rz_index, :) = 0d0
                global_stiffness_matrix(:, Rz_index) = 0d0
                global_stiffness_matrix(Rz_index, Rz_index) = 1d0
                global_load_vector(Rz_index) = 0d0
            end if
        end do
    end subroutine
end module

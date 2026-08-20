module solver_linear_supports
    !! Apply boundary conditions (supports) to the stiffness matrix and load vector

    use iso_fortran_env, only: real64

    use entity_node_support, only: NodeSupport
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: apply_supports

contains
    subroutine apply_supports(structure, K, F)
        type(StructuralModel), intent(in) :: structure  !< The structural model
        real(real64), intent(inout) :: K(:, :)  !< Stiffness matrix
        real(real64), intent(inout) :: F(:)  !< Load vector

        type(NodeSupport) :: node_support
        integer :: i
        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index

        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%dof_per_node * (node_support%node%id - 1)) + 1
                K(Dx_index, :) = 0d0
                K(:, Dx_index) = 0d0
                K(Dx_index, Dx_index) = 1d0
                F(Dx_index) = 0d0
            end if

            if (node_support%Dy) then
                Dy_index = (structure%dof_per_node * (node_support%node%id - 1)) + 2
                K(Dy_index, :) = 0d0
                K(:, Dy_index) = 0d0
                K(Dy_index, Dy_index) = 1d0
                F(Dy_index) = 0d0
            end if

            if (node_support%Rz) then
                Rz_index = (structure%dof_per_node * (node_support%node%id - 1)) + 3
                K(Rz_index, :) = 0d0
                K(:, Rz_index) = 0d0
                K(Rz_index, Rz_index) = 1d0
                F(Rz_index) = 0d0
            end if
        end do
    end subroutine
end module

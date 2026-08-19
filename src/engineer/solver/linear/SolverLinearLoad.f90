module SolverLinearLoad
    !! Functions and subroutine for structure load
    use iso_fortran_env, only: real64

    use EntityNodeLoad, only: NodeLoad
    use EntityNodeSupport, only: NodeSupport

    use structural_model, only: StructuralModel

    implicit none
    private

    public :: calc_Fg

contains
    subroutine calc_Fg(structure)
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(inout) :: structure  !< The structural model

        ! Aux *************************************************************************************
        integer :: i ! indices

        integer :: Fx_index
        integer :: Fy_index
        integer :: Mz_index

        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index
        type(NodeLoad) :: node_load
        type(NodeSupport) :: node_support
        real(real64), allocatable :: Dp(:)  ! Vector of loads


        ! =========================================================================================
        ! Initialization
        ! =========================================================================================
        ! Allocation
        allocate(Dp(structure%global_dimension))

        structure%Fg = 0d0
        do i = 1, structure%qtd_node_loads
            node_load = structure%node_loads(i)

            Fx_index = (structure%qtd_dof_node * (node_load%node - 1)) + 1
            Fy_index = (structure%qtd_dof_node * (node_load%node - 1)) + 2
            Mz_index = (structure%qtd_dof_node * (node_load%node - 1)) + 3

            structure%Fg(Fx_index) = structure%Fg(Fx_index) + node_load%Fx
            structure%Fg(Fy_index) = structure%Fg(Fy_index) + node_load%Fy
            structure%Fg(Mz_index) = structure%Fg(Mz_index) + node_load%Mz
        end do

        Dp = 0d0
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%qtd_dof_node * (node_support%node - 1)) + 1
                Dp(Dx_index) = node_support%Dx_value
            end if

            if (node_support%Dy) then
                Dy_index = (structure%qtd_dof_node * (node_support%node - 1)) + 2
                Dp(Dy_index) = node_support%Dy_value
            end if

            if (node_support%Rz) then
                Rz_index = (structure%qtd_dof_node * (node_support%node - 1)) + 3
                Dp(Rz_index) = node_support%Rz_value
            end if
        end do

        structure%Fg = structure%Fg - matmul(structure%Kg, Dp)
    end subroutine calc_Fg
end module

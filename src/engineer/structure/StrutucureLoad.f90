module StructureLoad
    !! Functions and subroutine for structure load
    use iso_fortran_env, only: real64

    use EntityNodeLoad, only: NodeLoad
    use EntityNodeSupport, only: NodeSupport

    use StructureNodeLoads, only: node_loads
    use StructureNodeSupports, only: node_supports

    use StructureControls, only: &
        global_dimension, qtd_node_loads, qtd_dof_node, qtd_node_supports
    use StructureCalculated, only: Fg

    implicit none
    private

    public :: calc_Fg
contains
    subroutine calc_Fg
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
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
        allocate(Dp(global_dimension))

        Fg = 0d0
        do i = 1, qtd_node_loads
            node_load = node_loads(i)

            Fx_index = (qtd_dof_node * (node_load%node - 1)) + 1
            Fy_index = (qtd_dof_node * (node_load%node - 1)) + 2
            Mz_index = (qtd_dof_node * (node_load%node - 1)) + 3

            Fg(Fx_index) = Fg(Fx_index) + node_load%Fx
            Fg(Fy_index) = Fg(Fy_index) + node_load%Fy
            Fg(Mz_index) = Fg(Mz_index) + node_load%Mz
        end do

        Dp = 0d0
        do i = 1, qtd_node_supports
            node_support = node_supports(i)

            if (node_support%Dx) then
                Dx_index = (qtd_dof_node * (node_support%node - 1)) + 1
                Dp(Dx_index) = node_support%Dx_value
            end if

            if (node_support%Dy) then
                Dy_index = (qtd_dof_node * (node_support%node - 1)) + 2
                Dp(Dy_index) = node_support%Dy_value
            end if

            if (node_support%Rz) then
                Rz_index = (qtd_dof_node * (node_support%node - 1)) + 3
                Dp(Rz_index) = node_support%Rz_value
            end if
        end do

        ! Fg = Fg - matmul(Kg, Dp)
    end subroutine calc_Fg
end module

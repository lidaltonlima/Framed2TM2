module SolverLinearDisplacement
    !! Subroutines to get displacements

    use iso_fortran_env, only: real64

    use EntityNodeSupport, only: NodeSupport
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: calc_Dg
contains
    subroutine calc_Dg(structure)
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(inout) :: structure  !< The structural model

        ! Aux *************************************************************************************
        type(NodeSupport) :: node_support

        integer :: i  ! indices

        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index

        real(real64), allocatable :: K_aux(:, :)
        real(real64), allocatable :: F_aux(:)

        ! External ********************************************************************************
        external :: dposv  ! solve symmetric positive defined matrix system (Lapack)

        integer :: info  ! status of operation (dposv - Lapack)

        ! =========================================================================================
        ! Initialization
        ! =========================================================================================
        ! Allocation
        allocate(K_aux(structure%global_dimension, structure%global_dimension))
        allocate(F_aux(structure%global_dimension))

        ! Start values
        K_aux = structure%Kg
        F_aux = structure%Fg

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        ! Add boundary ****************************************************************************
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%qtd_dof_node * (node_support%node - 1)) + 1
                K_aux(Dx_index, :) = 0d0
                K_aux(:, Dx_index) = 0d0
                K_aux(Dx_index, Dx_index) = 1d0
                F_aux(Dx_index) = 0d0
            end if

            if (node_support%Dy) then
                Dy_index = (structure%qtd_dof_node * (node_support%node - 1)) + 2
                K_aux(Dy_index, :) = 0d0
                K_aux(:, Dy_index) = 0d0
                K_aux(Dy_index, Dy_index) = 1d0
                F_aux(Dy_index) = 0d0
            end if

            if (node_support%Rz) then
                Rz_index = (structure%qtd_dof_node * (node_support%node - 1)) + 3
                K_aux(Rz_index, :) = 0d0
                K_aux(:, Rz_index) = 0d0
                K_aux(Rz_index, Rz_index) = 1d0
                F_aux(Rz_index) = 0d0
            end if
        end do

        ! Solution the system *********************************************************************
        structure%Dg = F_aux
        call dposv( &
            'U', structure%global_dimension, 1, K_Aux, structure%global_dimension, structure%Dg, &
            structure%global_dimension, info)

        if (info /= 0) error stop 'DPOSV - calc_Dg - Displacements: solution system.'

        ! Sum the prescribed displacement *********************************************************
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%qtd_dof_node * (node_support%node - 1)) + 1
                structure%Dg(Dx_index) = node_support%Dx_value
            end if

            if (node_support%Dy) then
                Dy_index = (structure%qtd_dof_node * (node_support%node - 1)) + 2
                structure%Dg(Dy_index) = node_support%Dy_value
            end if

            if (node_support%Rz) then
                Rz_index = (structure%qtd_dof_node * (node_support%node - 1)) + 3
                structure%Dg(Rz_index) = node_support%Rz_value
            end if
        end do
    end subroutine calc_Dg
end module

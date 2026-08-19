module SolverLinearDisplacement
    !! Subroutines to get displacements

    use iso_fortran_env, only: real64

    use EntityNodeSupport, only: NodeSupport
    use static_analysis_results, only: StaticAnalysisResults
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: solve_displacements
contains
    subroutine solve_displacements(structure, results)
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(in) :: structure  !< The structural model
        type(StaticAnalysisResults), intent(inout) :: results  !< Static analysis results

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
        K_aux = results%stiffness_matrix
        F_aux = results%load_vector

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
        results%displacements = F_aux
        call dposv( &
            'U', structure%global_dimension, 1, K_Aux, structure%global_dimension, results%displacements, &
            structure%global_dimension, info)

        if (info /= 0) error stop 'DPOSV - calc_Dg - Displacements: solution system.'

        ! Sum the prescribed displacement *********************************************************
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%qtd_dof_node * (node_support%node - 1)) + 1
                results%displacements(Dx_index) = node_support%Dx_value
            end if

            if (node_support%Dy) then
                Dy_index = (structure%qtd_dof_node * (node_support%node - 1)) + 2
                results%displacements(Dy_index) = node_support%Dy_value
            end if

            if (node_support%Rz) then
                Rz_index = (structure%qtd_dof_node * (node_support%node - 1)) + 3
                results%displacements(Rz_index) = node_support%Rz_value
            end if
        end do
    end subroutine solve_displacements
end module

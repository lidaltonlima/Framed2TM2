module solver_linear_displacements
    !! Subroutines to get displacements

    use iso_fortran_env, only: real64

    use EntityNodeSupport, only: NodeSupport
    use solver_linear_supports, only: apply_supports
    use systems, only: solve_symmetric_positive_definite_system
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

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        ! Add boundary ****************************************************************************
        call apply_supports(structure, results%stiffness_matrix, results%load_vector)

        ! Solution the system *********************************************************************
        call solve_symmetric_positive_definite_system( &
            results%stiffness_matrix, results%load_vector, results%displacements)

        ! Sum the prescribed displacement *********************************************************
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%dof_per_node * (node_support%node - 1)) + 1
                results%displacements(Dx_index) = node_support%Dx_value
            end if

            if (node_support%Dy) then
                Dy_index = (structure%dof_per_node * (node_support%node - 1)) + 2
                results%displacements(Dy_index) = node_support%Dy_value
            end if

            if (node_support%Rz) then
                Rz_index = (structure%dof_per_node * (node_support%node - 1)) + 3
                results%displacements(Rz_index) = node_support%Rz_value
            end if
        end do
    end subroutine solve_displacements
end module

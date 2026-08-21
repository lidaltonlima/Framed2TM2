module solver_linear_reactions
    !! Calculate the reactions

    use iso_fortran_env, only: real64

    use entity_node_support, only: NodeSupport

    use static_analysis_results, only: StaticAnalysisResults
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: solve_reactions

contains
    subroutine solve_reactions(structure, results)
        ! =========================================================================================
        ! Vars Statements
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(in) :: structure  !< The structural model
        type(StaticAnalysisResults), intent(inout) :: results  !< Static analysis results

        ! Control *********************************************************************************
        type(NodeSupport) :: node_support

        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index

        integer :: i, j ! indexes
        real(real64) :: D_aux(structure%global_dimension)

        ! =====================================================================
        ! Initialization
        ! =====================================================================
        results%reactions = 0.0_real64

        ! =====================================================================
        ! Calculation
        ! =====================================================================
        D_aux = results%displacements
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%dof_per_node * (node_support%node%id - 1)) + 1
                D_aux(Dx_index) = D_aux(Dx_index) - (node_support%Dx_value)
            end if

            if (node_support%Dy) then
                Dy_index = (structure%dof_per_node * (node_support%node%id - 1)) + 2
                D_aux(Dy_index) = D_aux(Dy_index) - (node_support%Dy_value)
            end if

            if (node_support%Rz) then
                Rz_index = (structure%dof_per_node * (node_support%node%id - 1)) + 3
                D_aux(Rz_index) = D_aux(Rz_index) - (node_support%Rz_value)
            end if
        end do

        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%dof_per_node * (node_support%node%id - 1)) + 1

                results%reactions(Dx_index) = results%reactions(Dx_index) - results%load_vector(Dx_index)

                do j = 1, structure%global_dimension
                    results%reactions(Dx_index) = results%reactions(Dx_index) + results%stiffness_matrix(Dx_index, j) * D_aux(j)
                end do
            end if

            if (node_support%Dy) then
                Dy_index = (structure%dof_per_node * (node_support%node%id - 1)) + 2

                results%reactions(Dy_index) = results%reactions(Dy_index) - results%load_vector(Dy_index)

                do j = 1, structure%global_dimension
                    results%reactions(Dy_index) = results%reactions(Dy_index) + results%stiffness_matrix(Dy_index, j) * D_aux(j)
                end do
            end if

            if (node_support%Rz) then
                Rz_index = (structure%dof_per_node * (node_support%node%id - 1)) + 3

                results%reactions(Rz_index) = results%reactions(Rz_index) - results%load_vector(Rz_index)

                do j = 1, structure%global_dimension
                    results%reactions(Rz_index) = results%reactions(Rz_index) + results%stiffness_matrix(Rz_index, j) * D_aux(j)
                end do
            end if
        end do
    end subroutine solve_reactions
end module

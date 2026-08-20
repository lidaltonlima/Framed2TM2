module solver_linear_load
    !! Functions and subroutine for structure load
    use iso_fortran_env, only: real64

    use EntityNodeLoad, only: NodeLoad
    use EntityNodeSupport, only: NodeSupport

    use static_analysis_results, only: StaticAnalysisResults
    use structural_model, only: StructuralModel

    implicit none
    private

    public :: assemble_load_vector

contains
    subroutine assemble_load_vector(structure, results)
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(in) :: structure  !< The structural model
        type(StaticAnalysisResults), intent(inout) :: results  !< Static analysis results

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

        if (.not. allocated(results%load_vector)) then
            allocate(results%load_vector(structure%global_dimension))
        end if

        results%load_vector = 0d0
        do i = 1, structure%qtd_node_loads
            node_load = structure%node_loads(i)

            Fx_index = (structure%dof_per_node * (node_load%node%id - 1)) + 1
            Fy_index = (structure%dof_per_node * (node_load%node%id - 1)) + 2
            Mz_index = (structure%dof_per_node * (node_load%node%id - 1)) + 3

            results%load_vector(Fx_index) = results%load_vector(Fx_index) + node_load%Fx
            results%load_vector(Fy_index) = results%load_vector(Fy_index) + node_load%Fy
            results%load_vector(Mz_index) = results%load_vector(Mz_index) + node_load%Mz
        end do

        Dp = 0d0
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%dof_per_node * (node_support%node%id - 1)) + 1
                Dp(Dx_index) = node_support%Dx_value
            end if

            if (node_support%Dy) then
                Dy_index = (structure%dof_per_node * (node_support%node%id - 1)) + 2
                Dp(Dy_index) = node_support%Dy_value
            end if

            if (node_support%Rz) then
                Rz_index = (structure%dof_per_node * (node_support%node%id - 1)) + 3
                Dp(Rz_index) = node_support%Rz_value
            end if
        end do

        results%load_vector = results%load_vector - matmul(results%stiffness_matrix, Dp)
    end subroutine assemble_load_vector
end module

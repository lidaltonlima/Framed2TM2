module SolverLinearStiffness
    !! Functions and subroutines of structure stiffness

    use iso_fortran_env, only: real64

    use structural_model, only: StructuralModel

    implicit none
    private

    public :: calc_Kg

contains
    subroutine add_k(structure, K, id)
        !! Add the stiffness in the global matrix stiffness

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(in) :: structure  !< The structural model
        integer, intent(in) :: id  !< index of element
        real(real64), allocatable, intent(inout) :: K(:, :)  !< Global stiffness global

        ! Auxiliaries *****************************************************************************
        real(real64), allocatable :: EKg(:, :)  !< element stiffness matrix in global system
        real(real64) :: R(structure%element_dimension, structure%element_dimension)  !< Rotation matrix of bar
        integer :: si, ei  !< start and end index in initial node
        integer :: sj, ej  !< start and end index in end node

        integer :: start_node_id  !< Start node id of bar
        integer :: end_node_id  !< End node id of bar

        ! =========================================================================================
        ! Calculates
        ! =========================================================================================
        R = structure%bars(id)%R(structure%nodes, structure%element_dimension)
        EKg = structure%bars(id)%kl( &
            structure%nodes, structure%materials, structure%sections, &
            structure%element_dimension, structure%theory)
        EKg = matmul(matmul(transpose(R), EKg), R)

        start_node_id = structure%bars(id)%start_node
        end_node_id = structure%bars(id)%end_node

        si = (structure%qtd_dof_node * (start_node_id - 1)) + 1  ! Start index of initial node
        ei = si + structure%qtd_dof_node - 1  ! End index of initial node

        sj = (structure%qtd_dof_node * (end_node_id - 1)) + 1  ! Start index of end node
        ej = sj + structure%qtd_dof_node - 1  ! End index of end node


        K(si:ei, si:ei) = K(si:ei, si:ei) + EKg(:3, :3)  ! k_ii
        K(si:ei, sj:ej) = K(si:ei, sj:ej) + EKg(:3, 4:)  ! k_ij
        K(sj:ej, si:ei) = K(sj:ej, si:ei) + EKg(4:, :3)  ! k_ji
        K(sj:ej, sj:ej) = K(sj:ej, sj:ej) + EKg(4:, 4:)  ! k_jj
    end subroutine add_k


    subroutine calc_Kg(structure)
        !! Calculate the global stiffness matrix

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(inout) :: structure  !< The structural model

        ! Aux *************************************************************************************
        integer :: id  ! Id of bar

        allocate(structure%Kg(structure%global_dimension, structure%global_dimension))

        structure%Kg = 0d0

        do id = 1, structure%qtd_bars
            call add_k(structure, structure%Kg, id)
        end do
    end subroutine
end module

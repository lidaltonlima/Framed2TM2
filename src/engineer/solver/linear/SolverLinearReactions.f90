module SolverLinearReactions
    !! Calculate the reactions

    use iso_fortran_env, only: real64

    use EntityNodeSupport, only: NodeSupport

    use structural_model, only: StructuralModel

    implicit none
    private

    public :: calc_Rg

contains
    subroutine calc_Rg(structure)
        ! =========================================================================================
        ! Vars Statements
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(inout) :: structure  !< The structural model

        ! Control *********************************************************************************
        type(NodeSupport) :: node_support

        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index

        integer :: i, j ! indexes
        real(real64) :: D_aux(structure%global_dimension)

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        D_aux = structure%Dg
        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%qtd_dof_node * (node_support%node - 1)) + 1
                D_aux(Dx_index) = D_aux(Dx_index) - (node_support%Dx_value)
            end if

            if (node_support%Dy) then
                Dy_index = (structure%qtd_dof_node * (node_support%node - 1)) + 2
                D_aux(Dy_index) = D_aux(Dy_index) - (node_support%Dy_value)
            end if

            if (node_support%Rz) then
                Rz_index = (structure%qtd_dof_node * (node_support%node - 1)) + 3
                D_aux(Rz_index) = D_aux(Rz_index) - (node_support%Rz_value)
            end if
        end do

        do i = 1, structure%qtd_nodes_support
            node_support = structure%node_supports(i)

            if (node_support%Dx) then
                Dx_index = (structure%qtd_dof_node * (node_support%node - 1)) + 1

                structure%Rg(Dx_index) = structure%Rg(Dx_index) - structure%Fg(Dx_index)

                do j = 1, structure%global_dimension
                    structure%Rg(Dx_index) = structure%Rg(Dx_index) + structure%Kg(Dx_index, j) * D_aux(j)
                end do
            end if

            if (node_support%Dy) then
                Dy_index = (structure%qtd_dof_node * (node_support%node - 1)) + 2

                structure%Rg(Dy_index) = structure%Rg(Dy_index) - structure%Fg(Dy_index)

                do j = 1, structure%global_dimension
                    structure%Rg(Dy_index) = structure%Rg(Dy_index) + structure%Kg(Dy_index, j) * D_aux(j)
                end do
            end if

            if (node_support%Rz) then
                Rz_index = (structure%qtd_dof_node * (node_support%node - 1)) + 3

                structure%Rg(Rz_index) = structure%Rg(Rz_index) - structure%Fg(Rz_index)

                do j = 1, structure%global_dimension
                    structure%Rg(Rz_index) = structure%Rg(Rz_index) + structure%Kg(Rz_index, j) * D_aux(j)
                end do
            end if
        end do
    end subroutine calc_Rg

    ! subroutine calc_ERl
    !     ! =========================================================================================
    !     ! Vars Statements
    !     ! =========================================================================================on of matrices and vectors

    !     ! Aux
    !     integer :: i
    !     integer :: si, ei  ! start and end index in initial node
    !     integer :: sf, ef  ! start and end index in end node
    !     real(real64) :: EDg(E_dim)  ! element displacement in global system
    !     real(real64) :: EDl(E_dim)  ! element displacement in local system


    !     do i = 1, nel
    !         si = (ndofn * (bars(i, 3) - 1)) + 1
    !         ei = si + ndofn - 1

    !         sf = (ndofn * (bars(i, 4) - 1)) + 1
    !         ef = sf + ndofn - 1

    !         EDg(:ndofn) = Dg(si:ei)
    !         EDg(ndofn+1:) = Dg(sf:ef)

    !         EDl = matmul(R(i), EDg)
    !         ERl(i, :) = matmul(EKl(i), EDl)
    !     end do
    ! end subroutine calc_ERl
end module

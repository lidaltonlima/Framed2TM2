module SolverLinearReactions
    !! Calculate the reactions

    use iso_fortran_env, only: real64

    use EntityNodeSupport, only: NodeSupport

    use Structure, only: &
        node_supports, &
        Dg, Rg, Fg, Kg, &
        global_dimension, &
        qtd_dof_node, qtd_nodes_support

    implicit none
    private

    public :: calc_Rg

contains
    subroutine calc_Rg
        ! =========================================================================================
        ! Vars Statements
        ! =========================================================================================
        ! Control *********************************************************************************
        type(NodeSupport) :: node_support

        integer :: Dx_index
        integer :: Dy_index
        integer :: Rz_index

        integer :: i, j ! indexes
        real(real64) :: D_aux(global_dimension)

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        D_aux = Dg
        do i = 1, qtd_nodes_support
            node_support = node_supports(i)

            if (node_support%Dx) then
                Dx_index = (qtd_dof_node * (node_support%node - 1)) + 1
                D_aux(Dx_index) = D_aux(Dx_index) - (node_support%Dx_value)
            end if

            if (node_support%Dy) then
                Dy_index = (qtd_dof_node * (node_support%node - 1)) + 2
                D_aux(Dy_index) = D_aux(Dy_index) - (node_support%Dy_value)
            end if

            if (node_support%Rz) then
                Rz_index = (qtd_dof_node * (node_support%node - 1)) + 3
                D_aux(Rz_index) = D_aux(Rz_index) - (node_support%Rz_value)
            end if
        end do

        do i = 1, qtd_nodes_support
            node_support = node_supports(i)

            if (node_support%Dx) then
                Dx_index = (qtd_dof_node * (node_support%node - 1)) + 1

                Rg(Dx_index) = Rg(Dx_index) - Fg(Dx_index)

                do j = 1, global_dimension
                    Rg(Dx_index) = Rg(Dx_index) + Kg(Dx_index, j) * D_aux(j)
                end do
            end if

            if (node_support%Dy) then
                Dy_index = (qtd_dof_node * (node_support%node - 1)) + 2

                Rg(Dy_index) = Rg(Dy_index) - Fg(Dy_index)

                do j = 1, global_dimension
                    Rg(Dy_index) = Rg(Dy_index) + Kg(Dy_index, j) * D_aux(j)
                end do
            end if

            if (node_support%Rz) then
                Rz_index = (qtd_dof_node * (node_support%node - 1)) + 3

                Rg(Rz_index) = Rg(Rz_index) - Fg(Rz_index)

                do j = 1, global_dimension
                    Rg(Rz_index) = Rg(Rz_index) + Kg(Rz_index, j) * D_aux(j)
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

program main
    use TextIO
    use Structure
    use SolverLinear
    implicit none

    ! =============================================================================================
    ! Initialization
    ! =============================================================================================
    ! Get data from files
    call get_structure_data

    ! Calculate the dimension of arrays
    global_dimension = qtd_nodes * qtd_dof_node
    element_dimension = 2 * qtd_dof_node

    ! Allocate arrays
    allocate(Dg(global_dimension))
    allocate(Fg(global_dimension))
    allocate(Rg(global_dimension))

    call calc_Kg
    call calc_Fg
    call calc_Dg
    call calc_Rg


    block
        integer :: i
        do i = 1, global_dimension
            if (abs(Rg(i)) < 1e-10) then
                write(*, '(*(ES15.4))') 0.0
            else
                write(*, '(*(ES15.4))') Rg(i)
            end if
        end do
    end block

end program

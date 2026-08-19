program main
    use TextIO
    use Structure
    use LinearSolver
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


    block
        integer :: i
        do i = 1, global_dimension
            write(*, '(*(ES15.4))') Dg(i)
        end do
    end block

end program

program main
    use TextIO
    use Structure
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
end program

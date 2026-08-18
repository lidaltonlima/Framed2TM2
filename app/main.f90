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


    block
        integer :: i
        real(8) :: kl(element_dimension, element_dimension)

        kl = bars(1)%kl()
        do i = 1, element_dimension
            write(*, '(*(ES15.4))') kl(i, :)
        end do
    end block

end program

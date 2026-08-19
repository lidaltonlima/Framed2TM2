program main
    use TextIO
    use SolverLinear
    use structural_model, only: StructuralModel

    implicit none

    ! =========================================================================
    ! Vars
    ! =========================================================================
    type(StructuralModel) :: structure

    ! =========================================================================
    ! Initialization
    ! =========================================================================
    ! Get data from files
    call get_structure_data(structure)

    ! Calculate the dimension of arrays
    structure%global_dimension = structure%qtd_nodes * structure%qtd_dof_node
    structure%element_dimension = 2 * structure%qtd_dof_node

    ! Allocate arrays
    allocate(structure%Dg(structure%global_dimension))
    allocate(structure%Fg(structure%global_dimension))
    allocate(structure%Rg(structure%global_dimension))

    call calc_Kg(structure)
    call calc_Fg(structure)
    call calc_Dg(structure)
    call calc_Rg(structure)

    block
        integer :: i
        do i = 1, structure%global_dimension
            if (abs(structure%Rg(i)) < 1e-10) then
                write(*, '(*(ES15.4))') 0.0
            else
                write(*, '(*(ES15.4))') structure%Rg(i)
            end if
        end do
    end block

end program

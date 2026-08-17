program main
    use TextIO
    use Structure
    implicit none

    call get_structure_data

    print *, node_loads(1)%Mz
    print *, 'Fortran is working...'
end program

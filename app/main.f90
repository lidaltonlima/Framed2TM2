program main
    use TextIO
    use Structure
    implicit none

    call get_structure_data

    print *, sections(1)%A
    print *, 'Fortran is working...'
end program

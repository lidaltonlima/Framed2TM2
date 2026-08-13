program main
    use Example, only: Vetor2D
    implicit none

    type(Vetor2D) :: v1 !< Primeiro vetor

    v1 = Vetor2D(1d0, 2d0)

    print *, v1
end program main

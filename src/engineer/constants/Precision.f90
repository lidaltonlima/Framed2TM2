module precision
    !! Constantes to precision e residual values

    use iso_fortran_env, only: real64
    implicit none
    save

    !> Tolerance to zero numbers in numbers to displacements
    real(real64), parameter :: disp_tolerance = 1.0d-15

    !> Tolerance to zero numbers in numbers to forces
    real(real64), parameter :: force_tolerance = 1.0d-5

    !> Tolerance to residual number
    real(real64), parameter :: residual_tolerance = 1.0d-12
end module

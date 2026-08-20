module precision
    use iso_fortran_env, only: real64
    implicit none
    save

    !> tolerance to zero numbers in numbers to displacements
    real(real64), parameter :: disp_tolerance = 1.0d-15

    !> tolerance to zero numbers in numbers to forces
    real(real64), parameter :: force_tolerance = 1.0d-5
end module

module EntitySection
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: Section
        !! The entity Section

        integer :: samples = 1  !< Samples for properties
        real(real64), allocatable :: A(:)  !< Samples array of area
        real(real64), allocatable :: Asy(:)  !< Samples array of shear area in "y" direction
        real(real64), allocatable :: Iz(:) !< Samples array of inertia around z axis
    end type
end module

module EntitySection
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: Section
        !! The entity Section

        integer :: sample = 1  !< Samples for properties
        real(real64) :: area  !< Area
        real(real64) :: shear_area_y  !< Shear area in "y" direction
    end type
end module

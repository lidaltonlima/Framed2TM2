module EntityNodeLoad
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: NodeLoad
        !! Load applied in node

        integer :: node
        real(real64) :: Fx  !< Force in **x** axis
        real(real64) :: Fy  !< Force in **y** axis
        real(real64) :: Mz  !< Moment around **z** axis
    end type
end module

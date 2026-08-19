module EntityNodeSupport
    use iso_fortran_env, only: real64

    implicit none
    private

    type, public :: NodeSupport
        integer :: node
        logical :: Dx
        logical :: Dy
        logical :: Rz
        real(real64) :: Dx_value
        real(real64) :: Dy_value
        real(real64) :: Rz_value
    end type
end module

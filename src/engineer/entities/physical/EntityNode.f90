module EntityNode
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: Node
        real(real64) :: x
        real(real64) :: y
    end type
end module

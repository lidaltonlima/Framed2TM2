module EntityNode
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: Node
        real(real64) :: x
        real(real64) :: y
        logical :: labeled = .false.
    contains
        procedure :: distance_to
    end type

contains
    function distance_to(this, other) result(distance)
        class(Node), intent(in) :: this
        class(Node), intent(in) :: other
        real(real64) :: distance

        distance = sqrt((other%x - this%x)**2 + (other%y - this%y)**2)
    end function
end module

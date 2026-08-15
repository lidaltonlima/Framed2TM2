module EntityNode
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: Node
        real(real64) :: x  !< Coordinate x
        real(real64) :: y  !< Coordinate y
        logical :: isLabeled = .false. !< If the node is labeled
    contains
        procedure :: initialize
    end type

contains
    subroutine initialize(this, x, y, isLabeled)
        !! Constructor

        class(Node) :: this
        real(real64), intent(in) :: x !< Coordinate x
        real(real64), intent(in) :: y !< Coordinate y
        logical, intent(in), optional :: isLabeled !< If the node is labeled

        this%x = x
        this%y = y
        if (present(isLabeled)) this%isLabeled = isLabeled
    end subroutine
end module

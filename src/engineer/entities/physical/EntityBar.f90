module EntityBar
    use iso_fortran_env, only: real64

    use StructureData, only: nodes

    implicit none
    private

    type, public :: Bar
        !! The entity Bar

        integer :: material  !< Position of Material
        integer :: section  !< Position of Section
        integer :: start_node  !< Position of start node
        integer :: end_node  !< Position of end node

    contains
        procedure :: initialize
        procedure :: length
    end type

contains
    subroutine initialize(this, star_node, end_node)
        !! Constructor

        class(Bar) :: this
        integer, intent(in) :: star_node !< Position of start node
        integer, intent(in) :: end_node  !< Position of snd node

        this%start_node = star_node
        this%end_node = end_node
    end subroutine

    function length(this)
        !! Calculate length of Bar

        class(Bar), intent(in) :: this
        real(real64) :: length !< The length of Bar
        real(real64) :: dx !< Delta x
        real(real64) :: dy !< Delta x

        dx = nodes(this%end_node)%x - nodes(this%start_node)%x
        dy = nodes(this%end_node)%y - nodes(this%start_node)%y

        length = sqrt(dx**2 + dy**2)
    end function
end module

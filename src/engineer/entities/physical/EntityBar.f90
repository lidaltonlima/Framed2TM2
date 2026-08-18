module EntityBar
    use iso_fortran_env, only: real64

    use StructureNodes, only: nodes

    implicit none
    private

    type, public :: Bar
        !! The entity Bar

        integer :: material  !< Position of Material
        integer :: section  !< Position of Section
        integer :: start_node  !< Position of start node
        integer :: end_node  !< Position of end node

    contains
        procedure :: length
        procedure :: kl
    end type

contains
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

    function kl(this)
        class(Bar) :: this
        real(real64), allocatable :: kl(:, :)

        this%end_node = this%end_node
        allocate(kl(3, 3))
    end function
end module

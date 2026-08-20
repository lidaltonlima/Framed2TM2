module entity_bar
    use iso_fortran_env, only: real64

    use entity_node, only: Node
    use entity_material, only: Material
    use entity_section, only: Section
    use entity_entity, only: Entity

    use linear_algebra, only: cross

    implicit none
    private

    type, public, extends(Entity) :: Bar
        !! The entity Bar

        type(Material), pointer :: material => null()  !< Material of bar
        type(Section), pointer :: section => null()  !< Section of bar
        type(Node), pointer :: start_node => null()  !< Start node of bar
        type(Node), pointer :: end_node => null()  !< End node of bar

    contains
        procedure :: length
        procedure :: stiffness_matrix_local_system
        procedure :: rotation_matrix
        procedure :: reactions
        procedure :: forces
    end type

    interface
        module function stiffness_matrix_local_system(this, theory) result(kl)
            !! The stiffness matrix in local coordinate system

            class(Bar) :: this

            !> EB to Euler-Bernoulli and TM ot Timoshenko
            character(2), intent(in) :: theory

            !> The matrix of stiffness
            real(real64), allocatable :: kl(:, :)
        end function stiffness_matrix_local_system
    end interface

    integer, parameter :: dimension = 6

contains
    function length(this)
        !! Calculate length of Bar

        class(Bar), intent(in) :: this
        real(real64) :: length !< The length of Bar
        real(real64) :: dx !< Delta x
        real(real64) :: dy !< Delta x

        dx = this%end_node%x - this%start_node%x
        dy = this%end_node%y - this%start_node%y

        length = sqrt(dx**2 + dy**2)
    end function


    function rotation_matrix(this) result(R)
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        class(Bar) :: this
        real(real64), allocatable :: R(:, :)

        ! Aux *************************************************************************************
        real(real64) :: e_vec(3)
        real(real64) :: n_vec(3)
        real(real64) :: x_vec(3)
        real(real64) :: y_vec(3)
        real(real64) :: z_vec(3)

        ! =========================================================================================
        ! Initialization
        ! =========================================================================================
        allocate(R(dimension, dimension))
        R = 0d0

        e_vec = [ &
            this%end_node%x - this%start_node%x, &
            this%end_node%y - this%start_node%y, &
            0d0]

        if (e_vec(1) > 0) then
            n_vec = [e_vec(1), e_vec(2) + 1, 0d0]
        else if (e_vec(1) < 0) then
            n_vec = [e_vec(1), e_vec(2) - 1, 0d0]
        else
            if (e_vec(2) > 0) then
                n_vec = [e_vec(1) - 1, e_vec(2), 0d0]
            else
                n_vec = [e_vec(1) + 1, e_vec(2), 0d0]
            end if
        end if

        x_vec = e_vec / norm2(e_vec)

        z_vec = cross(x_vec, n_vec)
        z_vec = z_vec / norm2(z_vec)

        y_vec = cross(z_vec, x_vec)

        R(1, :3) = x_vec
        R(2, :3) = y_vec
        R(3, :3) = z_vec

        R(4:, 4:) = R(:3, :3)

    end function


    function reactions(this, dof_per_node, theory, global_displacements) result(ERl)
        !! Calculate the reactions of the bar in its local system from the global displacements

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        class(Bar) :: this
        integer, intent(in) :: dof_per_node  !< Degrees of freedom per node
        character(2), intent(in) :: theory  !< Theory used (Euler-Bernoulli or Timoshenko)
        real(real64), intent(in) :: global_displacements(:)  !< Displacements in global system
        real(real64), allocatable :: ERl(:)  !> The reactions of bar in local system

        ! Aux *************************************************************************************
        real(real64), allocatable :: R(:, :)  ! Rotation matrix of bar
        real(real64), allocatable :: kl(:, :)  ! Stiffness matrix of bar in local system
        real(real64) :: EDg(dimension)  ! Element displacement in global system
        real(real64) :: EDl(dimension)  ! Element displacement in local system
        integer :: si, ei  ! start and end index in start node
        integer :: sf, ef  ! start and end index in end node

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        si = (dof_per_node * (this%start_node%id - 1)) + 1
        ei = si + dof_per_node - 1

        sf = (dof_per_node * (this%end_node%id - 1)) + 1
        ef = sf + dof_per_node - 1

        EDg(:dof_per_node) = global_displacements(si:ei)
        EDg(dof_per_node+1:) = global_displacements(sf:ef)

        R = this%rotation_matrix()
        kl = this%stiffness_matrix_local_system(theory)

        EDl = matmul(R, EDg)

        allocate(ERl(dimension))
        ERl = matmul(kl, EDl)
    end function


    function forces(this, dof_per_node, theory, global_displacements) result(EEl)
        !! Calculate the efforts of the bar from its reactions in local system

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        class(Bar) :: this
        integer, intent(in) :: dof_per_node  !< Degrees of freedom per node
        character(2), intent(in) :: theory  !< Theory used (Euler-Bernoulli or Timoshenko)
        real(real64), intent(in) :: global_displacements(:)  !< Displacements in global system
        real(real64), allocatable :: EEl(:)  !> The efforts of bar

        ! Aux *************************************************************************************
        real(real64), allocatable :: ERl(:)  ! Reactions of bar in local system
        real(real64) :: bar_length  ! Length of bar

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        ERl = this%reactions(dof_per_node, theory, global_displacements)
        bar_length = this%length()

        allocate(EEl(dimension))
        ! N and V are constant along the bar; M varies linearly without interior loads
        EEl(1) = -ERl(1)
        EEl(2) = -ERl(2)
        EEl(3) = -ERl(3)
        EEl(4) = -ERl(1)
        EEl(5) = -ERl(2)
        EEl(6) = -ERl(3) + ERl(2) * bar_length
    end function
end module

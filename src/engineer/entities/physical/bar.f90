module EntityBar
    use iso_fortran_env, only: real64

    use EntityNode, only: Node
    use EntityMaterial, only: Material
    use EntitySection, only: Section
    use EntityEntity, only: Entity

    use GQint, only: intGQ
    use LinearAlgebra, only: inv_special, LagPol, cross

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

    ! =============================================================================================
    ! Global vars
    ! =============================================================================================
    real(real64) :: E  ! elasticity module
    real(real64) :: G  ! shear elasticity module
    real(real64), allocatable :: A(:)  ! area
    real(real64), allocatable :: As(:)  ! shear area
    real(real64) :: L  ! length of element
    real(real64), allocatable :: Iz(:)  ! inertia
    character(2) :: theory_g  ! theory used

    real(real64), allocatable :: el_px(:)  ! Points of sample sections

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


    function stiffness_matrix_local_system(this, theory) result(kl)
        !! Calculate the stiffness matrix of bar in local coordinates

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        class(Bar) :: this
        character(2), intent(in) :: theory  !< Theory used (Euler-Bernoulli or Timoshenko)
        real(real64), allocatable :: kl(:, :)  !> The stiffness matrix in local coordinates

        ! Aux *************************************************************************************
        real(real64) :: fIi(3, 3)
        real(real64) :: fIf(3, 3)
        real(real64) :: fFi(3, 3)
        real(real64) :: fFf(3, 3)
        real(real64) :: AII(3, 3)
        real(real64) :: AFF(3, 3)
        real(real64) :: EII(3, 3)


        real(real64) :: dx, dy  ! Delta x and delta y
        real(real64) :: step  ! Step to get sections samples
        integer :: index

        integer :: samples  ! Quantity of section samples
        real(real64) :: nu  ! Coefficient of Poison

        ! =========================================================================================
        ! Initialization
        ! =========================================================================================
        allocate(kl(dimension, dimension))

        samples = this%section%samples
        if (.not. allocated(el_px)) allocate(el_px(samples))
        if (.not. allocated(A)) allocate(A(samples))
        if (.not. allocated(As)) allocate(As(samples))
        if (.not. allocated(Iz)) allocate(Iz(samples))

        ! =========================================================================================
        ! Calculation
        ! =========================================================================================
        theory_g = theory

        kl = 0d0
        AII = 0d0
        AFF = 0d0
        E = this%material%E

        G = this%material%G
        if (G == 0d0) then
            nu = this%material%nu
            G = E / (2 * (1 + nu))
        end if

        A = this%section%A
        As = this%section%As
        Iz = this%section%Iz

        dx = this%end_node%x - this%start_node%x
        dy = this%end_node%y - this%start_node%y
        L = sqrt(dx**2 + dy**2)

        ! Get points of sample sections
        step = L / (samples - 1)
        do index = 1, samples
            el_px(index) = step * (index - 1)
        end do

        EII = 0d0
        EII(1, 1) = 1
        EII(2, 2) = 1
        EII(3, 3) = 1
        EII(3, 2) = -L

        AII(1, 1) = intGQ(0d0, L, a11, 4)
        AII(2, 2) = intGQ(0d0, L, a22, 4)
        AII(2, 3) = intGQ(0d0, L, a23, 4)
        AII(3, 2) = intGQ(0d0, L, a32, 4)
        AII(3, 3) = intGQ(0d0, L, a33, 4)

        AFF(1, 1) = intGQ(0d0, L, a44, 4)
        AFF(2, 2) = intGQ(0d0, L, a55, 4)
        AFF(2, 3) = intGQ(0d0, L, a56, 4)
        AFF(3, 2) = intGQ(0d0, L, a65, 4)
        AFF(3, 3) = intGQ(0d0, L, a66, 4)

        fIi = inv_special(AII)
        fFf = inv_special(AFF)
        fIf = matmul(-inv_special(EII), fFf)
        fFi = matmul(-EII, fIi)

        kl(:3, :3) = fIi
        kl(:3, 4:) = fIf
        kl(4:, 4:) = fFf
        kl(4:, :3) = fFi
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


    pure function ka(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = E * LagPol(el_px, A, x)
    end function ka


    pure function kb(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = E * LagPol(el_px, Iz, x)
    end function kb


    pure function ks(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = G * LagPol(el_px, As, x)
    end function ks


    pure function a11(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = 1 / ka(x)
    end function a11


    pure function a22(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = x**2 / kb(x) + merge(1 / ks(x), 0d0, theory_g == 'TM')
    end function a22


    pure function a23(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = -x / kb(x)
    end function a23


    pure function a32(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = -x / kb(x)
    end function a32


    pure function a33(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = 1 / kb(x)
    end function a33


    pure function a44(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = 1 / ka(x)
    end function a44


    pure function a55(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = (L - x)**2 / kb(x) + merge(1 / ks(x), 0d0, theory_g == 'TM')
    end function a55


    pure function a56(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = (L - x) / kb(x)
    end function a56


    pure function a65(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = (L - x) / kb(x)
    end function a65


    pure function a66(x) result(y)
        real(real64), intent(in) :: x
        real(real64) :: y

        y = 1 / kb(x)
    end function a66
end module

module EntityBar
    use iso_fortran_env, only: real64

    use EntityNode, only: Node

    use StructureNodes, only: nodes
    use StructureSections, only: sections
    use StructureMaterials, only: materials
    use StructureControls, only: element_dimension, theory

    use GQint, only: intGQ
    use LinearAlgebra, only: inv_special, LagPol, cross

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
        procedure :: R
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
        !! Calculate the stiffness matrix of bar in local coordinates

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        class(Bar) :: this
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
        type(Node) :: start_node  !< Start node of bar
        type(Node) :: end_node  !< End node of bar

        ! =========================================================================================
        ! Initialization
        ! =========================================================================================
        allocate(kl(element_dimension, element_dimension))

        samples = sections(this%section)%samples
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
        E = materials(this%material)%E

        G = materials(this%material)%G
        if (G == 0d0) then
            nu = materials(this%material)%nu
            G = E / (2 * (1 + nu))
        end if

        A = sections(this%section)%A
        As = sections(this%section)%As
        Iz = sections(this%section)%Iz

        start_node = nodes(this%start_node)
        end_node = nodes(this%end_node)
        dx = end_node%x - start_node%x
        dy = end_node%y - start_node%y
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

    function R(this)
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

        type(Node) :: start_node  !< Start node of bar
        type(Node) :: end_node  !< End node of bar

        ! =========================================================================================
        ! Initialization
        ! =========================================================================================
        allocate(R(element_dimension, element_dimension))
        R = 0d0

        start_node = nodes(this%start_node)
        end_node = nodes(this%end_node)
        e_vec = [ &
            end_node%x - start_node%x, &
            end_node%y - start_node%y, &
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

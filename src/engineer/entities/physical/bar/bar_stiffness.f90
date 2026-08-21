submodule (entity_bar) bar_stiffness
    use iso_fortran_env, only: real64

    use gq_int, only: intGQ
    use linear_algebra, only: inv_special, LagPol

contains
    module procedure stiffness_matrix_local_system
        real(real64) :: fIi(3, 3), fIf(3, 3), fFi(3, 3), fFf(3, 3)
        real(real64) :: AII(3, 3), AFF(3, 3), EII(3, 3)
        real(real64) :: dx, dy, step, nu, E, G, L
        integer :: index, samples
        real(real64), allocatable :: A(:), As(:), Iz(:), el_px(:)
        character(2) :: theory_g

        allocate(kl(6, 6))
        samples = this%section%samples
        allocate(el_px(samples), A(samples), As(samples), Iz(samples))

        theory_g = theory
        kl = 0.0_real64
        AII = 0.0_real64
        AFF = 0.0_real64
        E = this%material%long_elasticity

        G = this%material%trans_elasticity
        if (G == 0.0_real64) then
            nu = this%material%poison_ratio
            G = E / (2 * (1 + nu))
        end if

        A = this%section%area
        As = this%section%shear_area_y
        Iz = this%section%inertia_z

        dx = this%end_node%x - this%start_node%x
        dy = this%end_node%y - this%start_node%y
        L = sqrt(dx**2 + dy**2)

        step = L / (samples - 1)
        do index = 1, samples
            el_px(index) = step * (index - 1)
        end do

        EII = 0.0_real64
        EII(1, 1) = 1
        EII(2, 2) = 1
        EII(3, 3) = 1
        EII(3, 2) = -L

        AII(1, 1) = intGQ(0.0_real64, L, a11, 4)
        AII(2, 2) = intGQ(0.0_real64, L, a22, 4)
        AII(2, 3) = intGQ(0.0_real64, L, a23, 4)
        AII(3, 2) = intGQ(0.0_real64, L, a32, 4)
        AII(3, 3) = intGQ(0.0_real64, L, a33, 4)

        AFF(1, 1) = intGQ(0.0_real64, L, a44, 4)
        AFF(2, 2) = intGQ(0.0_real64, L, a55, 4)
        AFF(2, 3) = intGQ(0.0_real64, L, a56, 4)
        AFF(3, 2) = intGQ(0.0_real64, L, a65, 4)
        AFF(3, 3) = intGQ(0.0_real64, L, a66, 4)

        fIi = inv_special(AII)
        fFf = inv_special(AFF)
        fIf = matmul(-inv_special(EII), fFf)
        fFi = matmul(-EII, fIi)

        kl(:3, :3) = fIi
        kl(:3, 4:) = fIf
        kl(4:, 4:) = fFf
        kl(4:, :3) = fFi

    contains
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
            y = x**2 / kb(x) + merge(1 / ks(x), 0.0_real64, theory_g == 'TM')
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
            y = (L - x)**2 / kb(x) + merge(1 / ks(x), 0.0_real64, theory_g == 'TM')
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
    end procedure
end submodule

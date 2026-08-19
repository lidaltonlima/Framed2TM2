module EntityMaterial
    use iso_fortran_env, only: real64
    implicit none
    private

    type, public :: Material
        !! The entity Material

        real(real64) :: E  !< Module of longitudinal elasticity
        real(real64) :: G  !< Module of transversal elasticity
        real(real64) :: nu !< Coefficient of Poison
        real(real64) :: rho !< Density
    end type
end module

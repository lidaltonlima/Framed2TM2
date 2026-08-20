module EntitySection
    use iso_fortran_env, only: real64
    use EntityEntity, only: Entity
    implicit none
    private

    type, public, extends(Entity) :: Section
        !! The entity Section

        integer :: samples = 1  !< Samples for properties
        real(real64), allocatable :: A(:)  !< Samples array of area
        real(real64), allocatable :: As(:)  !< Samples array of shear area
        real(real64), allocatable :: Iz(:) !< Samples array of inertia around z axis
    end type
end module

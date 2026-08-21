module entity_section
    use iso_fortran_env, only: real64
    use entity_entity, only: Entity
    implicit none
    private

    type, public, extends(Entity) :: Section
        !! The entity Section

        !> Samples for properties
        integer :: samples = 1

        !> Samples array of area
        real(real64), allocatable :: area(:)

        !> Samples array of shear area in **y** direction
        real(real64), allocatable :: shear_area_y(:)

        !> Samples array of inertia around **z** axis
        real(real64), allocatable :: inertia_z(:)
    end type
end module

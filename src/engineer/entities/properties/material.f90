module entity_material
    use iso_fortran_env, only: real64
    use entity_entity, only: Entity
    implicit none
    private

    type, public, extends(Entity) :: Material
        !! The entity Material

        real(real64) :: long_elasticity  !< Module of longitudinal elasticity
        real(real64) :: trans_elasticity  !< Module of transversal elasticity
        real(real64) :: poison_ratio !< Coefficient of Poison
        real(real64) :: density !< Density
    end type
end module

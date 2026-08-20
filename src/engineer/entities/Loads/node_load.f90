module entity_node_load
    use iso_fortran_env, only: real64
    use entity_node, only: Node
    use entity_entity, only: Entity
    implicit none
    private

    type, public, extends(Entity) :: NodeLoad
        !! Load applied in node

        type(Node), pointer :: node => null()  !< Node where the load is applied
        real(real64) :: Fx  !< Force in **x** axis
        real(real64) :: Fy  !< Force in **y** axis
        real(real64) :: Mz  !< Moment around **z** axis
    end type
end module

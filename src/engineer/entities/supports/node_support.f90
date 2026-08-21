module entity_node_support
    use iso_fortran_env, only: real64
    use entity_node, only: Node
    use entity_entity, only: Entity

    implicit none
    private

    type, public, extends(Entity) :: NodeSupport
        !! Support applied in node

        !< Node with the prescribed support
        type(Node), pointer :: node => null()

        logical :: Dx  !< If there is support to displacement **x** direction
        logical :: Dy  !< If there is support to displacement **y** direction
        logical :: Rz  !< If there is support to rotation **z** direction


        !> Value for prescribed displacement in **x** direction
        real(real64) :: Dx_value

        !> Value for prescribed displacement in **y** direction
        real(real64) :: Dy_value

        !> Value for prescribed rotation around **z** axis
        real(real64) :: Rz_value
    end type
end module

module entity_node_support
    use iso_fortran_env, only: real64
    use entity_node, only: Node
    use entity_entity, only: Entity

    implicit none
    private

    type, public, extends(Entity) :: NodeSupport
        type(Node), pointer :: node => null()  !< Node with the prescribed support
        logical :: Dx
        logical :: Dy
        logical :: Rz
        real(real64) :: Dx_value
        real(real64) :: Dy_value
        real(real64) :: Rz_value
    end type
end module

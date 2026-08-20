module EntityNodeSupport
    use iso_fortran_env, only: real64
    use EntityNode, only: Node
    use EntityEntity, only: Entity

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

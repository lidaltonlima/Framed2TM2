module StructureNodeSupports
    !! Module to avoid circular dependency

    use EntityNodeSupport, only: NodeSupport

    implicit none

    type(NodeSupport), allocatable :: node_supports(:) !< Array of node supports
end module

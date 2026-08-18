module StructureNodeLoads
    !! Module to avoid circular dependency

    use EntityNodeLoad, only: NodeLoad

    implicit none

    type(NodeLoad), allocatable :: node_loads(:)  !< Array of node loads
end module

module Structure_1
    !! Module to avoid circular dependency

    use EntityNode, only: Node

    implicit none

    type(Node), allocatable :: nodes(:)  !< Array of nodes
end module

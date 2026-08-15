module Structure
    !! Join of all entities and elements

    use EntityNode, only: Node

    implicit none

    type(Node) :: nodes(2)  !< Array of nodes
end module

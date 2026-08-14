program main
    use EntityNode, only: Node
    implicit none
    type(Node) :: n1, n2

    n1 = Node(1d0, 2d0)
    n2 = Node(4d0, 6d0, .true.)

    print *, n1%distance_to(n2)
end program

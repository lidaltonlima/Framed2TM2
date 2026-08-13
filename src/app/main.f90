program main
    use StructureNode
    implicit none
    type(Node) :: n1

    n1 = Node(5., 3.)

    print *, n1
end program main

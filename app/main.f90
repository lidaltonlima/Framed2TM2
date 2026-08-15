program main
    use Structure
    use EntityNode, only: Node
    use EntityBar, only: Bar
    implicit none
    type(Node) :: n1, n2
    type(Bar) :: b1

    call n1%initialize(0d0, 0d0)
    call n2%initialize(3d0, 4d0)

    nodes = [n1, n2]

    call b1%initialize(1, 2)


    print *, b1%length()
end program

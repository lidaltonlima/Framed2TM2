module test
    implicit none
    private

    public :: say_hello
contains
    subroutine say_hello
        print *, "Hello, fortran-doc!"
    end subroutine say_hello
end module test

module StructureBars
    !! Module to avoid circular dependency

    use EntityBar, only: Bar

    implicit none

    type(Bar), allocatable :: bars(:)  !< Array of bars
end module

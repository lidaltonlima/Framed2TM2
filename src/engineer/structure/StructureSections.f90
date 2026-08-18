module StructureSections
    !! Module to avoid circular dependency

    use EntitySection, only: Section

    implicit none

    type(Section), allocatable :: sections(:)  !< Array of sections
end module

module entity_entity
    !! Superclass to entities
    implicit none
    private

    type, public :: Entity
        !! Class for objects used in the solver of the structure.
        !!(e.g. displacements, forces and reactions)

        integer :: id  !< The position of entity in the array
    end type
end module

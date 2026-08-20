module EntityEntity
    !! Superclass to entities
    implicit none
    private

    type, public :: Entity
        integer :: id  !< The position of entity in the array
    end type
end module

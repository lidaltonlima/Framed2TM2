module StructureMaterials
    !! Module to avoid circular dependency

    use EntityMaterial, only: Material

    implicit none

    type(Material), allocatable :: materials(:)  !< Array of materiais
end module

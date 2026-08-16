module Structure
    !! Join of all entities, elements and controls vars in the structure

    use EntityBar, only: Bar
    use EntityMaterial, only: Material
    use EntitySection, only: Section
    use StructureData, only: nodes

    implicit none


    ! Control vars
    integer :: qtd_nodes  !< Quantity of nodes
    integer :: qtd_nodes_with_pre_disp !< Quantity of nodes with prescribed amount of displacement
    integer :: qtd_nodes_with_loads  !< Quantity of nodes
    integer :: qtd_bars  !< Quantity of elements
    integer :: ndofn  !< Quantity of degrees of freedom per node
    integer :: qtd_materials  !< Quantity of materials
    integer :: qtd_sections  !< Quantity of sections
    integer :: qtd_nodes_loaded  !< Quantity of nodes with point load
    character(2) :: theory !< Theory used (Euler-Bernoulli or Timoshenko)

    ! Structure entities
    type(Bar), allocatable :: bars(:)  !< Array of bars
    type(Material), allocatable :: materials(:)  !< Array of materiais
    type(Section), allocatable :: sections(:)  !< Array of sections

end module

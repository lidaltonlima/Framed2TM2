module structural_model
    !! Module to StructuralModel

    use iso_fortran_env, only: real64

    use entity_bar, only: Bar
    use entity_material, only: Material
    use entity_node_load, only: NodeLoad
    use entity_node, only: Node
    use entity_node_support, only: NodeSupport
    use entity_section, only: Section

    implicit none
    private

    type, public :: StructuralModel
        !! All data of structure

        type(Bar), allocatable :: bars(:)  !< Array of bars
        type(Material), allocatable :: materials(:)  !< Array of materiais
        type(NodeLoad), allocatable :: node_loads(:)  !< Array of node loads
        type(Node), allocatable :: nodes(:)  !< Array of nodes
        type(NodeSupport), allocatable :: node_supports(:) !< Array of node supports
        type(Section), allocatable :: sections(:)  !< Array of sections

        integer :: global_dimension  !< Dimension of problem to global arrays
        integer :: qtd_nodes  !< Quantity of nodes
        integer :: qtd_nodes_support!< Quantity of nodes with prescribed amount of displacement
        integer :: qtd_nodes_with_loads  !< Quantity of nodes
        integer :: qtd_bars  !< Quantity of elements
        integer :: dof_per_node  !< Degrees of freedom per node
        integer :: qtd_materials  !< Quantity of materials
        integer :: qtd_sections  !< Quantity of sections
        integer :: qtd_node_loads  !< Quantity of nodes with point load
        character(2) :: theory !< Theory used (Euler-Bernoulli or Timoshenko
    end type
end module

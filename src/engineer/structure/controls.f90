module StructureControls
    !! Controls vars

    implicit none

    integer :: global_dimension  !< Dimension of problem to global arrays
    integer :: element_dimension  ! Element dimension to local arrays
    integer :: qtd_nodes  !< Quantity of nodes
    integer :: qtd_nodes_support!< Quantity of nodes with prescribed amount of displacement
    integer :: qtd_nodes_with_loads  !< Quantity of nodes
    integer :: qtd_bars  !< Quantity of elements
    integer :: qtd_dof_node  !< Quantity of degrees of freedom per node
    integer :: qtd_materials  !< Quantity of materials
    integer :: qtd_sections  !< Quantity of sections
    integer :: qtd_node_loads  !< Quantity of nodes with point load
    character(2) :: theory !< Theory used (Euler-Bernoulli or Timoshenko)
end module

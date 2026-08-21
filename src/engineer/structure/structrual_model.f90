module structural_model
    !! Data structure representing the discrete model of a framed system.
    !!
    !! The model aggregates all geometric, material, loading, and boundary
    !! data needed by the finite element solver.

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
        !! In-memory representation of a plane-frame structural model.
        !!
        !! The arrays below are populated by the input reader and then consumed
        !! by the assembly and solver routines.

        ! Arrays **************************************************************
        !> Collection of structural members that connect the nodes.
        type(Bar), allocatable :: bars(:)

        !> Material properties associated with the bars.
        type(Material), allocatable :: materials(:)

        !> Nodal loads applied to the structure.
        type(NodeLoad), allocatable :: node_loads(:)

        !> Nodal coordinates and identifiers.
        type(Node), allocatable :: nodes(:)

        !> Support conditions and prescribed displacement boundary values.
        type(NodeSupport), allocatable :: node_supports(:)

        !> Section properties used by the element formulation.
        type(Section), allocatable :: sections(:)

        ! Control vars ********************************************************
        integer :: global_dimension  !< Total number of degrees of freedom in the assembled system.

        !> Number of nodes in the model.
        integer :: qtd_nodes

        !> Number of supports with constrained or prescribed nodal displacements.
        integer :: qtd_nodes_support

        integer :: num_nodes_with_loads  !< Number of nodes with applied loads.
        integer :: num_bars              !< Number of frame elements.
        integer :: dof_per_node          !< Degrees of freedom per node (for this project, typically 3).
        integer :: num_materials         !< Number of material definitions.
        integer :: num_sections          !< Number of section definitions.
        integer :: num_node_loads        !< Number of nodal load entries.

        !> Element theory used in the formulation: EB for Euler-Bernoulli or TM for Timoshenko.
        character(2) :: theory
    end type
end module

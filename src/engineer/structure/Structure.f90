module Structure
    !! Join of all entities, elements and controls vars in the structure

    use iso_fortran_env, only: real64

    ! Structure entities
    use StructureNodes, only: nodes
    use StructureMaterials, only: materials
    use StructureSections, only: sections
    use StructureNodeSupports, only: node_supports
    use StructureNodeLoads, only: node_loads
    use StructureBars, only: bars

    use StructureControls
    use StructureCalculated

    implicit none
end module

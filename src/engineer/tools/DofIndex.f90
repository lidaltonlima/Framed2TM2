module dof_index_utils
    implicit none

contains
    pure integer function dof_index(node_id, local_dof, dof_per_node)
        integer, intent(in) :: node_id
        integer, intent(in) :: local_dof
        integer, intent(in) :: dof_per_node

        dof_index = (dof_per_node * (node_id - 1)) + local_dof
    end function dof_index
end module dof_index_utils
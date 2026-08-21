module static_analysis_results
    !! Container for the global results produced by a static analysis.
    !!
    !! This type stores the assembled stiffness matrix, the full load vector,
    !! the nodal displacement solution, and the support reaction vector.

    use iso_fortran_env, only: real64

    implicit none
    private

    type, public :: StaticAnalysisResults
        !! Container that keeps the main output fields of the structural solver.
        !!
        !! The values stored here are later used by the post-processing routines
        !! that export the final model response to files.

        real(real64), allocatable :: stiffness_matrix(:, :)  !< Global stiffness matrix of the structural system.
        real(real64), allocatable :: displacements(:)        !< Nodal displacement vector in the global coordinate system.
        real(real64), allocatable :: load_vector(:)           !< Global force vector including applied loads and support effects.
        real(real64), allocatable :: reactions(:)             !< Reaction force vector at constrained degrees of freedom.
    end type
end module

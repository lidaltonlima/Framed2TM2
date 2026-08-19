module static_analysis_results
    !! Result form static analysis

    use iso_fortran_env, only: real64

    implicit none
    private

    type, public :: StaticAnalysisResults
        !! Class that have all global results
        real(real64), allocatable :: stiffness_matrix(:, :)  !< Stiffness matrix
        real(real64), allocatable :: displacements(:)  !< Displacements vector
        real(real64), allocatable :: load_vector(:)  !< Loads vector
        real(real64), allocatable :: reactions(:)  !< Reactions vector
    end type
end module

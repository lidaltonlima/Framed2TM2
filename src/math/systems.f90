module systems
    !! Solvers for systems

    use iso_fortran_env, only: real64

    implicit none

contains
    subroutine solve_symmetric_positive_definite_system(K, F, X)
        !! Solve a symmetric positive definite linear system K * X = F (Lapack dposv)
        real(real64), intent(inout) :: K(:, :)  !< Symmetric positive definite matrix
        real(real64), intent(in) :: F(:)  !< Right-hand side vector
        real(real64), intent(out) :: X(:)  !< Solution vector

        external :: dposv  ! solve symmetric positive defined matrix system (Lapack)

        integer :: n
        integer :: info  ! status of operation (dposv - Lapack)

        n = size(F)
        X = F
        call dposv('U', n, 1, K, n, X, n, info)

        if (info /= 0) error stop 'DPOSV - solve_symmetric_positive_definite_system: solution system.'
    end subroutine solve_symmetric_positive_definite_system
end module

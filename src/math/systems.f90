module systems
    !! Solvers for systems

    use iso_fortran_env, only: error_unit, real64

    implicit none

    interface
        subroutine dposv(uplo, n, nrhs, a, lda, b, ldb, info)
            import :: real64

            character(1), intent(in) :: uplo
            integer, intent(in) :: n
            integer, intent(in) :: nrhs
            integer, intent(in) :: lda
            integer, intent(in) :: ldb
            real(real64), intent(inout) :: a(lda, *)
            real(real64), intent(inout) :: b(ldb, *)
            integer, intent(out) :: info
        end subroutine dposv
    end interface

contains
    subroutine solve_symmetric_positive_definite_system(K, F, X)
        !! Solve a symmetric positive definite linear system K * X = F (Lapack dposv)

        real(real64), intent(inout) :: K(:, :)  !< Symmetric positive definite matrix
        real(real64), intent(in) :: F(:)  !< Right-hand side vector
        real(real64), intent(out) :: X(:)  !< Solution vector

        integer :: n
        integer :: info  ! status of operation (dposv - Lapack)

        n = size(F)
        X = F
        call dposv('U', n, 1, K, n, X, n, info)

        if (info < 0) then
            write(error_unit, '(A, I0)') &
                'DPOSV: invalid argument at position ', -info
            error stop 'DPOSV failed due to an invalid argument.'
        else if (info > 0) then
            write(error_unit, '(A, I0, A)') &
                'DPOSV: leading minor ', info, &
                ' is not positive definite; the structure may be unstable.'
            error stop 'DPOSV could not factor the stiffness matrix.'
        end if
    end subroutine
end module

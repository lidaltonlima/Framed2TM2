module StructureCalculated
    !! Structure calculated data

    use iso_fortran_env, only: real64

    implicit none

    real(real64), allocatable :: Kg(:, :)
    real(real64), allocatable :: Dg(:)
    real(real64), allocatable :: Fg(:)
    real(real64), allocatable :: Rg(:)
end module

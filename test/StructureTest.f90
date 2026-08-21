program StructureTest
    use iso_fortran_env, only: error_unit

    use text_io, only: count_file_lines

    implicit none

    ! =========================================================================
    ! Var statements
    ! =========================================================================
    ! Control parameters ******************************************************
    logical, parameter :: detail = .false.

    ! General *****************************************************************
    integer :: file_unit_t, file_unit_r  ! number of unit file
    character(300) :: line_t, line_r  ! value of line readd

    ! Aux *********************************************************************
    integer :: line_number  ! number of current line
    integer :: qtd_lines  ! quantity of lines in the right document
    integer :: i  ! index for loops
    logical :: test_failed

    ! =========================================================================
    ! Process
    ! =========================================================================
    ! Header ******************************************************************
    do i = 1, 79
        write(*, '(1A)', advance='no') '='
    end do
    write(*, *)
    write(*, '(1A33)') 'Structure Test - To Compare files'
    do i = 1, 79
        write(*, '(1A)', advance='no') '='
    end do
    write(*, *)

    ! Get number of lines *****************************************************
    test_failed = .false.
    qtd_lines = count_file_lines('./test/data/results.dat')

    ! Open ********************************************************************
    open(newUnit=file_unit_t, &
        file='./data/res/results.dat', &
        status='old', &
        action='read')
    open(newUnit=file_unit_r, &
        file='./test/data/results.dat', &
        status='old', &
        action='read')

    ! Compare *****************************************************************
    do line_number = 1, qtd_lines
        read(file_unit_t, '(1A300)') line_t
        read(file_unit_r, '(1A300)') line_r

        call show_test_value
    end do

    ! Close *******************************************************************
    close(file_unit_t)
    close(file_unit_r)

    if (test_failed) error stop 'Generated results differ from the reference file.'

    ! Footer ******************************************************************
    write(*, *)
    do i = 1, 79
        write(*, '(1A)', advance='no') '='
    end do
    write(*, *)
    write(*, '(1A33)') 'Tests Finished - To Compare files'
    do i = 1, 79
        write(*, '(1A)', advance='no') '='
    end do

    write(*, *)

contains
    subroutine show_details
        if (line_t /= line_r) then
            write(error_unit, '(1A17, 1I4)') 'Wrong values in: ', line_number
            write(error_unit, *)
            write(error_unit, *) 'Expected:'
            write(error_unit, *) line_r
            write(error_unit, *)
            write(error_unit, *) 'Obtained:'
            write(error_unit, *) line_t
        end if
    end subroutine

    subroutine show_test_value
        if (line_t /= line_r) test_failed = .true.

        if (detail) then
            call show_details
        else
            if (line_t == line_r) then
                write(*, '(1A1)', advance='no') '.'
            else
                write(*, '(1A1)', advance='no') 'F'
            end if
        end if
    end subroutine
end program StructureTest

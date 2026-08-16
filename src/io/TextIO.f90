module TextIO
    use Structure
    implicit none
    private

    public get_structure_data
    public count_file_lines
contains
    subroutine open_data_file(file_name,  file_unit)
        ! Open the file to get data

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O
        character(*), intent(in) :: file_name  ! File name
        integer, intent(out) :: file_unit  ! Unit to file

        ! Parameters
        character(7), parameter :: data_folder = './data/'  ! Data file location
        character(4), parameter :: file_extension = '.dat'  ! Data file extension

        ! aux
        integer :: file_stat  ! State of file
        character(:), allocatable :: file_error  ! Message to file error
        character(:), allocatable :: file_path  ! Complete path to file

        ! =========================================================================================
        ! Process
        ! =========================================================================================
        ! Open ************************************************************************************
        file_path = data_folder // trim(file_name) // file_extension
        open(newUnit=file_unit, &
            file=file_path, &
            status='old', &
            action='read', &
            ioStat=file_stat, &
            ioMsg=file_error)


        ! Error ***********************************************************************************
        if ( file_stat /= 0) then
            print *, 'State: ', file_stat
            print *, 'MSG: ', file_error
            error stop 'File open'
        end if
    end subroutine open_data_file


    function count_file_lines(file_name) result(line_count)
        !! Count how many non-blank (written) lines a data file has

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O
        character(*), intent(in) :: file_name  !< File name
        integer :: line_count  !< Amount of written lines

        ! aux
        integer :: file_unit  !< Unit to file
        integer :: read_stat  !< State of current read
        character :: line  ! Current read line

        ! =========================================================================================
        ! Process
        ! =========================================================================================
        ! Open ************************************************************************************
        call open_data_file(file_name, file_unit)

        ! Read ************************************************************************************
        line_count = 0
        do
            read(file_unit, '(A)', ioStat=read_stat) line

            if (read_stat /= 0) exit

            if (len_trim(line) > 0) line_count = line_count + 1
        end do

        ! Close ***********************************************************************************
        close(file_unit)
    end function count_file_lines


    subroutine get_structure_data
        ! Get the data structure

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! Controls ********************************************************************************
        integer :: file_unit  ! Unit to file
        integer :: read_stat  ! State of current read
        integer :: id  ! Object ID
        character(20) :: line_label

        ! Temp ************************************************************************************
        integer :: temp_int

        ! =========================================================================================
        ! CONTROLS
        ! =========================================================================================
        ! Open ************************************************************************************
        call open_data_file('controls', file_unit)

        ! Read ************************************************************************************
        CONTROLS: do
            read(file_unit, *, ioStat=read_stat) line_label, temp_int

            if (read_stat == 0) then
                select case (line_label)
                    case ('ndofn')
                        ndofn = temp_int
                    case ('theory')
                        if (temp_int == 0) then
                            theory = 'OB'
                        else
                            theory = 'TM'
                        end if
                end select
            else if (read_stat == -1) then
                exit CONTROLS
            else
                write(*, *) 'Read stat:', read_stat
                error stop 'Error in CONTROLS read'
            end if
        end do CONTROLS

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! MATERIALS
        ! =========================================================================================
        qtd_materials = count_file_lines('materials') - 1

        ! Allocation ******************************************************************************
        allocate(materials(qtd_materials))

        ! Open ************************************************************************************
        call open_data_file('materials', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, qtd_materials
            read(file_unit, *) &
                materials(id)%E, &
                materials(id)%G, &
                materials(id)%nu, &
                materials(id)%rho
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! SECTIONS
        ! =========================================================================================
        qtd_sections = count_file_lines('sections') - 1

        ! Allocation ******************************************************************************
        allocate(sections(qtd_sections))

        ! Open ************************************************************************************
        call open_data_file('sections', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, qtd_sections
            ! Internal allocation
            read(file_unit, *) sections(id)%samples
            allocate(sections(id)%A(sections(id)%samples))
            allocate(sections(id)%Asy(sections(id)%samples))
            allocate(sections(id)%Iz(sections(id)%samples))
            backspace file_unit

            ! Read data
            read(file_unit, *) &
                sections(id)%samples, &
                sections(id)%A(:), &
                sections(id)%Asy(:), &
                sections(id)%Iz(:)
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! ! =========================================================================================
        ! ! NODES
        ! ! =========================================================================================
        ! ! Allocation ******************************************************************************
        ! allocate(nodes(nno, 2))

        ! ! Open ************************************************************************************
        ! call open_data_file('nodes', file_unit)

        ! ! Read ************************************************************************************
        ! read(file_unit, *) ! titles line
        ! do id = 1, nno
        !     read(file_unit, *) nodes(id, 1), nodes(id, 2)
        ! end do

        ! ! Close ***********************************************************************************
        ! close(file_unit)

        ! ! =========================================================================================
        ! ! BARS
        ! ! =========================================================================================
        ! ! Allocation ******************************************************************************
        ! allocate(bars(nel, 4))

        ! ! Open ************************************************************************************
        ! call open_data_file('bars', file_unit)

        ! ! Read ************************************************************************************
        ! read(file_unit, *) ! titles line
        ! do id = 1, nel
        !     read(file_unit, *) bars(id, 1), bars(id, 2), bars(id, 3), bars(id, 4)
        ! end do

        ! ! Close ***********************************************************************************
        ! close(file_unit)

        ! ! =========================================================================================
        ! ! Bound
        ! ! =========================================================================================
        ! ! Allocation ******************************************************************************
        ! allocate(nnr(nccdesl))
        ! allocate(itydisp(nccdesl, ndofn))
        ! allocate(disp(nccdesl, ndofn))

        ! ! Open ************************************************************************************
        ! call open_data_file('boundaries', file_unit)

        ! ! Read ************************************************************************************
        ! read(file_unit, *) ! titles line
        ! do id = 1, nccdesl
        !     read(file_unit, *) nnr(id), itydisp(id, :), disp(id, :)
        ! end do

        ! ! Close ***********************************************************************************
        ! close(file_unit)

        ! ! =========================================================================================
        ! ! Loads
        ! ! =========================================================================================
        ! ! Allocation ******************************************************************************
        ! allocate(nnoc(nnc))
        ! allocate(ccno(nnc, ndofn))

        ! ! Open ************************************************************************************
        ! call open_data_file('node_loads', file_unit)

        ! ! Read ************************************************************************************
        ! read(file_unit, *) ! titles line
        ! do id = 1, nnc
        !     read(file_unit, *) nnoc(id), ccno(id, :)
        ! end do

        ! ! Close ***********************************************************************************
        ! close(file_unit)
    end subroutine get_structure_data
end module

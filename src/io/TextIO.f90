module TextIO
    use structural_model, only: StructuralModel
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


    subroutine get_structure_data(structure)
        ! Get the data structure

        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! IO ******************************************************************
        type(StructuralModel), intent(out), target :: structure

        ! Controls ********************************************************************************
        integer :: file_unit  ! Unit to file
        integer :: read_stat  ! State of current read
        integer :: id  ! Object ID
        character(20) :: line_label

        ! Temp ************************************************************************************
        integer :: temp_int
        integer :: material_index  ! Index of material of current bar
        integer :: section_index  ! Index of section of current bar
        integer :: start_node_index  ! Index of start node of current bar
        integer :: end_node_index  ! Index of end node of current bar
        integer :: node_index  ! Index of node of current support/load

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
                        structure%dof_per_node = temp_int
                    case ('theory')
                        if (temp_int == 0) then
                            structure%theory = 'OB'
                        else
                            structure%theory = 'TM'
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
        structure%qtd_materials = count_file_lines('materials') - 1

        ! Allocation ******************************************************************************
        allocate(structure%materials(structure%qtd_materials))

        ! Open ************************************************************************************
        call open_data_file('materials', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, structure%qtd_materials
            read(file_unit, *) &
                structure%materials(id)%E, &
                structure%materials(id)%G, &
                structure%materials(id)%nu, &
                structure%materials(id)%rho
            structure%materials(id)%id = id
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! SECTIONS
        ! =========================================================================================
        structure%qtd_sections = count_file_lines('sections') - 1

        ! Allocation ******************************************************************************
        allocate(structure%sections(structure%qtd_sections))

        ! Open ************************************************************************************
        call open_data_file('sections', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, structure%qtd_sections
            ! Internal allocation
            read(file_unit, *) structure%sections(id)%samples
            allocate(structure%sections(id)%A(structure%sections(id)%samples))
            allocate(structure%sections(id)%As(structure%sections(id)%samples))
            allocate(structure%sections(id)%Iz(structure%sections(id)%samples))
            backspace file_unit

            ! Read data
            read(file_unit, *) &
                structure%sections(id)%samples, &
                structure%sections(id)%A(:), &
                structure%sections(id)%As(:), &
                structure%sections(id)%Iz(:)
            structure%sections(id)%id = id
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! NODES
        ! =========================================================================================
        structure%qtd_nodes = count_file_lines('nodes') - 1

        ! Allocation ******************************************************************************
        allocate(structure%nodes(structure%qtd_nodes))

        ! Open ************************************************************************************
        call open_data_file('nodes', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, structure%qtd_nodes
            read(file_unit, *) &
                structure%nodes(id)%x, &
                structure%nodes(id)%y
            structure%nodes(id)%id = id
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! BARS
        ! =========================================================================================
        structure%qtd_bars = count_file_lines('bars') - 1

        ! Allocation ******************************************************************************
        allocate(structure%bars(structure%qtd_bars))

        ! Open ************************************************************************************
        call open_data_file('bars', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, structure%qtd_bars
            read(file_unit, *) &
                material_index, &
                section_index, &
                start_node_index, &
                end_node_index

            structure%bars(id)%material => structure%materials(material_index)
            structure%bars(id)%section => structure%sections(section_index)
            structure%bars(id)%start_node => structure%nodes(start_node_index)
            structure%bars(id)%end_node => structure%nodes(end_node_index)
            structure%bars(id)%id = id
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! Bound
        ! =========================================================================================
        structure%qtd_nodes_support = count_file_lines('nodes_supports') - 1

        ! Allocation ******************************************************************************
        allocate(structure%node_supports(structure%qtd_nodes_support))

        ! Open ************************************************************************************
        call open_data_file('nodes_supports', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, structure%qtd_nodes_support
            read(file_unit, *) &
                node_index, &
                structure%node_supports(id)%Dx, &
                structure%node_supports(id)%Dy, &
                structure%node_supports(id)%Rz, &
                structure%node_supports(id)%Dx_value, &
                structure%node_supports(id)%Dy_value, &
                structure%node_supports(id)%Rz_value

            structure%node_supports(id)%node => structure%nodes(node_index)
            structure%node_supports(id)%id = id
        end do

        ! Close ***********************************************************************************
        close(file_unit)

        ! =========================================================================================
        ! Loads
        ! =========================================================================================
        structure%qtd_node_loads = count_file_lines('node_loads') - 1

        ! Allocation ******************************************************************************
        allocate(structure%node_loads(structure%qtd_node_loads))

        ! Open ************************************************************************************
        call open_data_file('node_loads', file_unit)

        ! Read ************************************************************************************
        read(file_unit, *) ! titles line
        do id = 1, structure%qtd_node_loads
            read(file_unit, *) &
                node_index, &
                structure%node_loads(id)%Fx, &
                structure%node_loads(id)%Fy, &
                structure%node_loads(id)%Mz

            structure%node_loads(id)%node => structure%nodes(node_index)
            structure%node_loads(id)%id = id
        end do

        ! Close ***********************************************************************************
        close(file_unit)
    end subroutine get_structure_data
end module

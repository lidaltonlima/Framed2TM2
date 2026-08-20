module text_io
    use iso_fortran_env, only: real64
    use structural_model, only: StructuralModel
    use static_analysis_results, only: StaticAnalysisResults
    use precision, only: disp_tolerance, force_tolerance
    implicit none
    private

    public get_structure_data
    public count_file_lines
    public save_results
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

        structure%global_dimension = structure%qtd_nodes * structure%dof_per_node
    end subroutine get_structure_data

    subroutine save_results(structure, results)
        ! =========================================================================================
        ! Vars statement
        ! =========================================================================================
        ! I/O *************************************************************************************
        type(StructuralModel), intent(in) :: structure
        type(StaticAnalysisResults), intent(in) :: results

        ! File ************************************************************************************
        integer :: file_unit  ! Unit to file
        integer :: file_stat  ! State of file
        character(:), allocatable :: file_error  ! Message to file error

        ! Aux *************************************************************************************
        character(10) :: int2str1
        character(10) :: int2str2
        integer :: i ! index
        integer :: dir  ! direction degree
        integer :: i_dir  ! index of direction degree
        integer :: samples  ! Number of section samples
        real(real64), allocatable :: element_reactions(:)
        real(real64), allocatable :: element_efforts(:)

        if (structure%qtd_sections > 0) then
            samples = structure%sections(1)%samples
        else
            samples = 0
        end if

        open(newunit=file_unit, &
            file='./data/res/results.dat', &
            status='replace', &
            action='write', &
            iostat=file_stat, &
            iomsg=file_error)

        if (file_stat /= 0) then
            write(*, *) 'State: ', file_stat
            write(*, *) 'MSG: ', file_error
            error stop 'File open'
        end if

        ! =========================================================================================
        ! Processes
        ! =========================================================================================
        ! Title *******************************************************************************
        100 format(1A6, ':', 1I10)
        do i = 1, 100
            write(file_unit, '(A)', advance='no') '='
        end do

        write(file_unit, '(/, A)') 'Debug'

        do i = 1, 100
            write(file_unit, '(A)', advance='no') '='
        end do
        write(file_unit, *)

        ! Controls ********************************************************************************
        write(file_unit, '(A9)', advance='no') 'Controls '
        do i = 1, 91
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, 100) 'nno', structure%qtd_nodes
        write(file_unit, 100) 'nel', structure%qtd_bars
        write(file_unit, 100) 'ndofn', structure%dof_per_node
        write(file_unit, 100) 'nmat', structure%qtd_materials
        write(file_unit, 100) 'nsec', structure%qtd_sections
        write(file_unit, 100) 'nccdesl', structure%qtd_nodes_support
        write(file_unit, 100) 'nnc', structure%qtd_node_loads
        write(file_unit, 100) 'nsa', samples
        write(file_unit, '(1A6, ":", 1A10)') 'theory', structure%theory
        write(file_unit, *)
        write(file_unit, *)

        ! Materials *******************************************************************************
        write(file_unit, '(A10)', advance='no') 'Materials '
        do i = 1, 90
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, 3A15)') 'Id', 'E', 'nu', 'rho'
        do i = 1, structure%qtd_materials
            write(file_unit, '(1I4, 1ES15.4, 2F15.4)') structure%materials(i)%id, &
                structure%materials(i)%E, structure%materials(i)%nu, structure%materials(i)%rho
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Sections ********************************************************************************
        write(file_unit, '(A9)', advance='no') 'SECTIONS '
        do i = 1, 91
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(int2str1, '(I0)') samples*10 + 7
        write(int2str2, '(I0)') samples*10*2 + 4
        write(file_unit, '(1A4, T7, 1A4, T' // int2str1 // ', 1A10, T' // int2str2 // ', 1A10)') &
            'Id','Area', 'Shear Area', 'Inertia'
        write(int2str1, '(I0)') samples*3
        do i = 1, structure%qtd_sections

            write(file_unit, '(1I4,' // int2str1 // 'ES10.2)') structure%sections(i)%id, &
                structure%sections(i)%A, structure%sections(i)%As, structure%sections(i)%Iz
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Nodes ***********************************************************************************
        write(file_unit, '(A6)', advance='no') 'NODES '
        do i = 1, 94
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, T5, 1A5, T10, 1A10)') 'Id', 'X', 'Y'
        do i = 1, structure%qtd_nodes
            write(file_unit, '(1I4, 2F10.4)') structure%nodes(i)%id, &
                structure%nodes(i)%x, structure%nodes(i)%y
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Bars ************************************************************************************
        write(file_unit, '(A5)', advance='no') 'BARS '
        do i = 1, 95
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, 4A15)') 'id', 'Material', 'Section', 'Start Node', 'End Node'
        do i = 1, structure%qtd_bars
            write(file_unit, '(1I4, 4I15)') structure%bars(i)%id, &
                structure%bars(i)%material%id, structure%bars(i)%section%id, &
                structure%bars(i)%start_node%id, structure%bars(i)%end_node%id
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Boundaries ******************************************************************************
        write(file_unit, '(A7)', advance='no') 'Bounds '
        do i = 1, 93
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, *(A10))') 'Id', 'node', 'Dx', 'Dy', 'Rz', 'Dx', 'Dy', 'Rz'
        do i = 1, structure%qtd_nodes_support
            write(file_unit, '(1I4, 1I10, *(L10))', advance='no') structure%node_supports(i)%id, &
                structure%node_supports(i)%node%id, structure%node_supports(i)%Dx, &
                structure%node_supports(i)%Dy, structure%node_supports(i)%Rz
            write(file_unit, '(*(F10.4))', advance='no') structure%node_supports(i)%Dx_value, &
                structure%node_supports(i)%Dy_value, structure%node_supports(i)%Rz_value
            write(file_unit, *)
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Nodal Loads *****************************************************************************
        write(file_unit, '(A6)', advance='no') 'Loads '
        do i = 1, 94
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, 1A7, *(A13))') 'Id', 'node', 'Fx', 'Fy', 'Mz'
        do i = 1, structure%qtd_node_loads
            write(file_unit, '(1I4, 1I7, 3ES13.4)') structure%node_loads(i)%id, &
                structure%node_loads(i)%node%id, structure%node_loads(i)%Fx, &
                structure%node_loads(i)%Fy, structure%node_loads(i)%Mz
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Element Reactions ***********************************************************************
        write(file_unit, '(A18)', advance='no') 'Element Reactions '
        do i = 1, 82
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A7, *(A15))') 'Element', 'RNxi', 'RNyi', 'RMzi', 'RNxj', 'RNyj', 'RMzj'
        do i = 1, structure%qtd_bars
            element_reactions = structure%bars(i)%reactions( &
                structure%dof_per_node, structure%theory, results%displacements)
            write(file_unit, '(1I7)', advance='no') structure%bars(i)%id
            do dir = 1, size(element_reactions)
                if (abs(element_reactions(dir)) < force_tolerance) then
                    write(file_unit, '(*(ES15.4))', advance='no') 0.0d0
                else
                    write(file_unit, '(*(ES15.4))', advance='no') element_reactions(dir)
                end if
            end do
            write(file_unit, *)
        end do
        write(file_unit, *)
        write(file_unit, *)

        ! Element Efforts *************************************************************************
        write(file_unit, '(A16)', advance='no') 'Element Efforts '
        do i = 1, 84
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A7, *(A15))') 'Element', 'Ni', 'Vi', 'Mi', 'Nf', 'Vf', 'Mf'
        do i = 1, structure%qtd_bars
            element_efforts = structure%bars(i)%forces( &
                structure%dof_per_node, structure%theory, results%displacements)
            write(file_unit, '(1I7)', advance='no') structure%bars(i)%id
            do dir = 1, size(element_efforts)
                if (abs(element_efforts(dir)) < force_tolerance) then
                    write(file_unit, '(*(ES15.4))', advance='no') 0.0d0
                else
                    write(file_unit, '(*(ES15.4))', advance='no') element_efforts(dir)
                end if
            end do
            write(file_unit, *)
        end do
        write(file_unit, *)
        write(file_unit, *)


        ! Displacements ***************************************************************************
        write(file_unit, '(A14)', advance='no') 'Displacements '
        do i = 1, 86
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, *(A13))') 'Node', 'Dx', 'Dy', 'Rz'
        do i = 1, structure%qtd_nodes
            write(file_unit, '(1I4)', advance='no') i

            do dir = 1, structure%dof_per_node
                i_dir = (structure%dof_per_node * (i - 1)) + dir
                if (abs(results%displacements(i_dir)) < disp_tolerance) then
                    write(file_unit, '(ES13.4)', advance='no') 0.0d0
                else
                    write(file_unit, '(ES13.4)', advance='no') results%displacements(i_dir)
                end if
            end do
            write(file_unit, *)
        end do
        write(file_unit, *)

        ! Reactions *******************************************************************************
        write(file_unit, '(A10)', advance='no') 'Reactions '
        do i = 1, 90
            write(file_unit, '(A1)', advance='no') '/'
        end do
        write(file_unit, *)

        write(file_unit, '(1A4, *(A13))') 'Node', 'RNx', 'RNy', 'RMz'
        do i = 1, structure%qtd_nodes_support
            write(file_unit, '(1I4)', advance='no') structure%node_supports(i)%node%id

            do dir = 1, structure%dof_per_node
                i_dir = (structure%dof_per_node * (structure%node_supports(i)%node%id - 1)) + dir

                if (abs(results%reactions(i_dir)) < force_tolerance) then
                    write(file_unit, '(ES13.4)', advance='no') 0.0d0
                else
                    write(file_unit, '(ES13.4)', advance='no') results%reactions(i_dir)
                end if
            end do
            write(file_unit, *)
        end do

        write(file_unit, *)
        write(file_unit, *)
        close(file_unit)
    end subroutine save_results
end module

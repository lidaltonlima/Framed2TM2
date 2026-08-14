program main
    use json_module
    implicit none

    type(json_file) :: writer, reader
    integer :: age
    character(len=:), allocatable :: name
    logical :: active, found

    call writer%initialize()
    call writer%add('person.name', 'My name')
    call writer%add('person.age', 36)
    call writer%add('person.active', .true.)
    call writer%print(filename='person.json')

    if (writer%failed()) then
        call writer%print_error_message()
        error stop 'Could not write person.json'
    end if
    call writer%destroy()

    call reader%initialize()
    call reader%load(filename='person.json')
    if (reader%failed()) then
        call reader%print_error_message()
        error stop 'Could not read person.json'
    end if

    call reader%get('person.name', name, found)
    if (.not. found) error stop 'person.name was not found'
    call reader%get('person.age', age, found)
    if (.not. found) error stop 'person.age was not found'
    call reader%get('person.active', active, found)
    if (.not. found) error stop 'person.active was not found'

    print '(a, a)', 'Name: ', name
    print '(a, i0)', 'Age: ', age
    print '(a, l1)', 'Active: ', active

    call reader%destroy()
end program main

require "BinderDSLEngine"
require "Utils"

function main()
    if #arg ~= 2 and #arg ~= 3 then
        print('Usage: lua_wrapper.lua <input> <output> [-D]')
        print('       -D\tEnable debug')
        return 1
    end

    debug = false
    if #arg == 3 and arg[3] == '-D' then
        debug = true
    end

    input = arg[1]
    output = arg[2]
    fun_tbl = {}
    content = {}
    load_file(input)

    if debug then
        print_tbl(fun_tbl)
    end

    file = io.open(output, 'w')
    write_tbl2file(file, content)
    file:flush()
    io.close(file)
end

main()

-----------------------------------------------------------------------------
-- BinderDSLEngine
-- Author: Cliff Dong
--
-----------------------------------------------------------------------------

function print_tbl(t, ind)
    if not ind then
        ind = ''
    end
    for k, v in pairs(t) do
        if type(v) == 'table' then
            print(ind..k..'=table')
            print_tbl(v, ind..'  ')
        else
            print(ind..k..'='..tostring(v), type(v))
        end
    end
end

function FUNCTION_DEF(t)
    print('DUMP: table content:')
    for k, v in pairs(t) do
        print(k ,"=", v)
    end
    if not t.declare then
        print("Error: no declare definition")
        return
    end

    return_type, fun_name, arg_str = string.match(t.declare, '([%w_]+)%s+([%w_]+)%s*%((.*)%)')

    not_void = string.match(arg_str, '([%w_]+)')
    args = {}
    if not_void then
        for arg_type, arg_name in string.gmatch(arg_str, '([%w_%*]+)%s+([%w_%*]+)%s*[,]-') do
            is_pointer = false
            if string.find(arg_type, '%*') then
                arg_type = string.gsub(arg_type, '%*', '')
                is_pointer = true
            end
            if string.find(arg_name, '%*') then
                arg_name = string.gsub(arg_name, '%*', '')
                is_pointer = true
            end

            table.insert(args, {['type'] = arg_type, ['name'] = arg_name, ['is_pointer'] = is_pointer, ['output'] = false})
        end
    end
    
    if t.output_args then
        for _, v in pairs(t.output_args) do
            if type(args[v]) == 'table' then
                args[v].output = true
            end
        end
    end
    
    if t.arg_len then
        for k, v in pairs(t.arg_len) do
            if type(args[k]) == 'table' then
                if type(v) == 'string' then
                    args[k].len = string.match(v, 'arg(%d+)')
                elseif type(v) == 'number' then
                    args[k].len = v
                else
                    print("Error: invalid type of value in arg_len")
                    return
                end
            end
        end
    end
    
    fun_def = {['return_type'] = return_type, ['name'] = fun_name, ['args'] = args}
    table.insert(fun_tbl, fun_def)
end

function INCLUDE_SYS(f)
    include_str = string.format("#include <%s>", f)
    table.insert(include_tbl, include_str)
end

function INCLUDE(f)
    include_str = string.format("#include \"%s\"", f)
    table.insert(include_tbl, include_str)
end

FILE_HEADER_TEMP = [[
/*
 *---------------------------------------------------------------------------
 *
 * #C_FILE_NAME#
 *
 * Description:
 * This file is generated from #DEF_FILE_NAME#
 * #FILE_DESCRIPTION#
 *
 * #COPYRIGHT#
 *
 *---------------------------------------------------------------------------
 */
]]

INCLUDE_TEMP = [[

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
]]

function join_table(t, sep)
    if not sep then
        sep = ' '
    end
    local content = ''
    for _, v in pairs(t) do
        content = content .. v .. sep
    end
    return content
end

function write2file(f, str)
    f:write(str)
end

function write_tbl2file(f, t)
    write2file(f, join_table(t, '\n'))
end

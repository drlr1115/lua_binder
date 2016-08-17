-----------------------------------------------------------------------------
-- BinderDSLEngine
-- Author: Cliff Dong
--
-----------------------------------------------------------------------------

require "Utils"

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


local INDENT = '    '

local function pushfront_line(ind_n, fmt, ...)
    line = string.format(fmt, ...)
    table.insert(content, 1, string.rep(INDENT, ind_n)..line)
end

local function pushback_line(ind_n, fmt, ...)
    line = string.format(fmt, ...)
    table.insert(content, string.rep(INDENT, ind_n)..line)
end
local function STRUCT_START(name)
    pushback_line(0, '')
    pushback_line(0, 'static const luaL_reg %s[] =', module.name)
    pushback_line(0, '{')
end

local function STRUCT_END()
    pushback_line(0, '};')
    pushback_line(0, '')
end

local function FUNC_START(name)
    pushback_line(0, '')
    pushback_line(0, name)
    pushback_line(0, '{')
end

local function FUNC_END()
    pushback_line(0, '}')
    pushback_line(0, '')
end

local function generate_c_fun(fun)
    name = string.format("static int %s_wrapper(lua_State *L)", fun.name)
    FUNC_START(name)

    pushback_line(1, "int n = lua_gettop(L);")
    pushback_line(1, "if (n != %d) {", #fun.args)
    pushback_line(2, "printf(\"ERROR: input argument number %%d\\n, expected %d\", n);", #fun.args)
    pushback_line(2, "return -1;")
    pushback_line(1, '}')

    for i, arg in pairs(fun.args) do
        lua_fun = ''
        if arg.type == 'int' then
            lua_fun = 'lua_tointeger'
        elseif arg.type == 'double' or arg.type == 'float' then
            lua_fun = 'lua_tonumber'
        elseif arg.type == 'bool' then
            lua_fun = 'lua_toboolean'
        elseif arg.type == 'char' and arg.is_pointer == true then
            lua_fun = nil
        else
            print(string.format('ERROR: function %s arg %d type %s not supported\n',
                                fun.name, i, arg.type))
            return -1
        end

        if lua_fun then
            pushback_line(1, '%s %s = %s(L, %d);', arg.type, arg.name, lua_fun, i)
        end
    end

    pushback_line(0, '')
    -- declear non char arg first, since char* may use other arg as len value
    for i, arg in pairs(fun.args) do
        if arg.type == 'char' and arg.is_pointer == true then
            len = ''
            if type(arg.len) == 'string' then
                len = fun.args[tonumber(arg.len)].name
            else
                len = tostring(arg.len)
            end
            pushback_line(1, 'char* %s = malloc(%s);', arg.name, len)
            pushback_line(1, 'memset(%s, 0, %s);', arg.name, len)
            pushback_line(1, 'strncpy(%s, lua_tostring(L, %d), %s - 1);', arg.name, i, len)

        end
    end

    pushback_line(0, '')
    arg_name_tbl = {}
    for _, arg in pairs(fun.args) do
        table.insert(arg_name_tbl, arg.name)
    end
    arg_str = join_table(arg_name_tbl, ', ')
    pushback_line(1, '%s ret = %s(%s);', fun.return_type, fun.name, arg_str)
    pushback_line(0, '')

    lua_fun = ''
    if fun.return_type == 'int' then
        lua_fun = 'lua_pushinteger'
    elseif fun.return_type == 'double' or fun.return_type == 'float' then
        lua_fun = 'lua_pushnumber'
    elseif fun.return_type == 'bool' then
        lua_fun = 'lua_pushboolean'
    elseif fun.return_type == 'char' then
        lua_fun = nil
    else
        print(string.format('ERROR: return type %s not supported\n',
        fun.return_type))
        return -1
    end

    if lua_fun then
        pushback_line(1, '%s(L, %s);', lua_fun, 'ret')
    end

    for _, arg in pairs(fun.args) do
        if arg.output then
            arg_len = ''
            if type(arg.len) == 'string' then
                arg_len = fun.args[tonumber(arg.len)].name
            else
                arg_len = tostring(arg.len)
            end
            lua_fun = ''
            if arg.type == 'int' then
                lua_fun = 'lua_pushinteger'
            elseif arg.type == 'double' or fun.return_type == 'float' then
                lua_fun = 'lua_pushnumber'
            elseif arg.type == 'bool' then
                lua_fun = 'lua_pushboolean'
            elseif arg.type == 'char' then
                lua_fun = 'lua_pushlstring'
            else
                print(string.format('ERROR: output arg type %s not supported\n',
                arg.type))
                return -1
            end
            pushback_line(1, '%s(L, %s, %s);', lua_fun, arg.name, arg_len)
        end
    end

    pushback_line(0, '')
    for _, arg in pairs(fun.args) do
        if arg.type == 'char' and arg.is_pointer == true then
            pushback_line(1, 'free(%s);', arg.name)
        end
    end

    output_count = 1
    for _, arg in pairs(fun.args) do
        if arg.output then
            output_count = output_count + 1
        end
    end
    pushback_line(1, 'return %d;', output_count)

    FUNC_END()
end

local function generate_fun_list(t)
    name = string.format('static const luaL_reg %s[] =', module.name)
    STRUCT_START(name)

    for _, fun in pairs(t) do
        pushback_line(1, '{"%s", %s_wrapper},', fun.name, fun.name)
    end

    pushback_line(1, '{NULL, NULL},')

    STRUCT_END()
end

local function generate_init_fun()
    name = string.format('int init_%s(lua_State* L)', module.name)
    FUNC_START(name)

    pushback_line(1, 'luaL_register(L, "%s", %s);', module.name, module.name)
    pushback_line(1, 'return 1;')

    FUNC_END()
end

local function populate_from_temp(template, t)
    return string.gsub(template, "#([%w_]+)#", t)
end

local function populate_file_header(input, output)
    module['C_FILE_NAME'] = output
    module['DEF_FILE_NAME'] = input
    return populate_from_temp(FILE_HEADER_TEMP, module)
end

module = {}

function MODULE(name)
    module.name = name
end

function DESCRIPTION(str)
    module['FILE_DESCRIPTION'] = str
end

function COPYRIGHT(str)
    module['COPYRIGHT'] = str
end

function INCLUDE_SYS(f)
    pushback_line(0, "#include <%s>", f)
end

function INCLUDE(f)
    pushback_line(0, "#include \"%s\"", f)
end

function EMBEDDED_TEXT(text)
    table.insert(content, text)
end

function FUNCTION_DEF(t)
    --[[
    print('DUMP: table content:')
    for k, v in pairs(t) do
        print(k ,"=", v)
    end
    ]]
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

    generate_c_fun(fun_def)
end



function load_file(input, output)
    pushback_line(0, INCLUDE_TEMP)

    dofile(input)

    FILE_HEADER_TEMP = populate_file_header(input, output)
    pushfront_line(0, FILE_HEADER_TEMP)
    generate_fun_list(fun_tbl)
    generate_init_fun()
    remove_empty_tail_lines(content)
end

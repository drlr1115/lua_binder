function join_table(t, sep)
    if not sep then
        sep = ' ' 
    end 
    local content = ''
    first = true
    for _, v in pairs(t) do
        if first then
            content = content .. v
            first = false
        else
            content = content .. sep .. v
        end 
    end 
    return content
end

function remove_empty_tail_lines(t)
    while( true ) do
        if t[#t] == '' then
            table.remove(t, #t)
        else
            break
        end
    end
end

function write_tbl2file(f, t)
    f:write(join_table(t, '\n'))
    f:write('\n')
end

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

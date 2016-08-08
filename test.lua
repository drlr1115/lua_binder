require "BinderDSLEngine"

fun_tbl = {}
content = {}
insert_line(0, FILE_HEADER_TEMP)
insert_line(0, INCLUDE_TEMP)
dofile('drv_wrapper.def')

print_tbl(fun_tbl)

print(#fun_tbl[1].args)

generate_fun_list(fun_tbl)
generate_init_fun()

remove_empty_tail_lines()

file = io.open("drv_wrapper.c", 'w')

write_tbl2file(file, content)

file:flush()

io.close(file)

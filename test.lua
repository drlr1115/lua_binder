require "BinderDSLEngine"

include_tbl = {}
fun_tbl = {}
embedded_text_tbl = {}
dofile('drv_wrapper.def')

print_tbl(fun_tbl)

print(#fun_tbl[1].args)




file = io.open("drv_wrapper.c", 'w')

write2file(file, FILE_HEADER_TEMP)
write_tbl2file(file, include_tbl)
write2file(file, INCLUDE_TEMP)
write2file(file, '\n')
write_tbl2file(file, embedded_text_tbl)
write2file(file, '\n')
for _, fun in pairs(fun_tbl) do
    write_tbl2file(file, generate_c_fun(fun))
end
write2file(file, '\n')
write_tbl2file(file, generate_fun_list(fun_tbl))
write2file(file, '\n')
write_tbl2file(file, generate_init_fun())

file:flush()

io.close(file)

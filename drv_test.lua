local libpath = "./libdrv_wrapper.so"
local init = package.loadlib(libpath, "init_drv")

lib = init()

ret1, ret2 = lib.reg_read(0,1,2,'intput_str',16)
print(ret1, ret2, #ret2)

CC := gcc

HDRS := -I/usr/local/include/luajit-2.1

CFLAGS := -fPIC

LDFLAGS := -shared

LDDRS := -L/usr/local/lib

LDLIBS := -lluajit-5.1

all: libdrv_wrapper.so

libdrv_wrapper.so: drv_wrapper.o
	$(CC) $(LDFLAGS) $(LDDRS) $(LDLIBS) $< -o $@

drv_wrapper.o: drv_wrapper.c
	$(CC) -c $(HDRS) $(CFLAGS) $< -o $@

clean:
	-rm -f libdrv_wrapper.so drv_wrapper.o

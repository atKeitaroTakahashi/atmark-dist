
EXEC = telnetd
OBJS = telnetd.o state.o termstat.o slc.o sys_term.o \
	utility.o global.o authenc.o logwtmp.o logout.o

CFLAGS += -DPARANOID_TTYS -DUSE_TERMIO -DKLUDGELINEMODE -D_GNU_SOURCE -Wall

LDLIBS := -lutil $(LDLIBS)

all: $(EXEC)

$(EXEC): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBUTIL) $(LDLIBS$(LDLIBS_$@))

romfs:
	$(ROMFSINST) /bin/$(EXEC)
	$(ROMFSINST) -e CONFIG_USER_TELNETD_TELNETD \
		-a "telnet  stream tcp nowait root /bin/telnetd" /etc/inetd.conf

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o

$(OBJS): defs.h ext.h pathnames.h telnetd.h logwtmp.h logout.h


AS=vasmm68k_mot
ASFLAGS=-Fhunkexe -kick1hunks -m68000 -no-fpu
#ASFLAGS=-Fhunkexe -m68000 -no-fpu
ASFLAGS+=-nosym

hello:	hello.s

%:	%.s
	$(AS) $(ASFLAGS) -o $@ $<

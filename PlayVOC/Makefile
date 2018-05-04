AS=vasmm68k_mot
ASFLAGS=-Fhunkexe -kick1hunks -m68000 -no-fpu
#ASFLAGS=-Fhunkexe -m68000 -no-fpu
ASFLAGS+=-nosym

all:	playvoc playbeep

%:	%.asm
	$(AS) $(ASFLAGS) -o $@ $<

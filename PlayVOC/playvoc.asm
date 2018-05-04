; vim: set tabstop=8 shiftwidth=8 noexpandab
; Amiga plays a Creative Voice (.VOC) file  with audio.device
; for vasmm68k_mot

; calls scratches D0/D1 A0/A1 and preserves other registers

; exec.library
_LVOAllocMem	EQU -198
_LVOAllocAbs	EQU	-204
_LVOFreeMem		EQU -210
_LVOWait 	EQU -318
_LVOAddPort	EQU	-354
_LVORemPort EQU -360
_LVOPutMsg	EQU	-366
_LVOGetMsg	EQU	-372
_LVOReplyMsg EQU -378
;_LVOOpenLibrary	equ -552
_LVOOpenLibrary	equ -408
_LVOCloseLibrary	equ -414
_LVOOpenDevice	EQU	-444
_LVOCloseDevice EQU -450
; only available with V36
_LVOCreateMsgPort	EQU	-666
_LVODeleteMsgPort EQU -672

MEMF_ANY	equ 0	; Any type of memory will do
MEMF_PUBLIC	equ 1
MEMF_CHIP	equ 2
MEMF_FAST	equ 4
MEMF_LOCAL	equ 256	; Memory that does not go away at RESET
MEMF_24BITDMA	equ 512	; DMAable memory within 24 bits of address
MEMF_KICK	equ 1024	; Memory that can be used for KickTags
MEMF_CLEAR	equ 65536	; AllocMem: NULL out area before return
MEMF_LARGEST	equ 131072	; AvailMem: return the largest chunk size
MEMF_REVERSE	equ 262144	; AllocMem: allocate from the top down
MEMF_TOTAL	equ   524288	; AvailMem: return total size of memory
MEMF_NO_EXPUNGE	equ $80000000	; AllocMem: Do not cause expunge on failure

; dos.library
_LVOOpen	EQU	-30
_LVOClose	EQU	-36
_LVORead	EQU -42
_LVOWrite	EQU -48
_LVOInput	EQU -54
_LVOOutput	EQU -60
_LVOSeek	EQU	-66
_LVODeleteFile	EQU	-72
_LVORename	EQU	-78
_LVOLock	EQU	-84
_LVOUnLock	EQU	-90
_LVODupLock	EQU	-96
_LVOExamine	EQU	-102
_LVOExNext	EQU	-108
_LVOInfo	EQU -114

; intuition.library
_LVODisplayBeep EQU -96

; IO / IOAudio structure :
LN_SUCC	EQU	0
LN_PRED	EQU	4
LN_TYPE	EQU	8
LN_PRI	EQU 9
LN_NAME	EQU	10
LN_SIZE	EQU 14

MN_REPLYPORT	EQU LN_SIZE+0
MN_LENGTH	EQU LN_SIZE+4
MN_SIZE		EQU LN_SIZE+6

IO_DEVICE	EQU MN_SIZE+0
IO_UNIT		EQU MN_SIZE+4
IO_COMMAND	EQU MN_SIZE+8
IO_FLAGS	EQU MN_SIZE+10
IO_ERROR	EQU MN_SIZE+11
IO_SIZE	EQU MN_SIZE+12

ioa_AllocKey	EQU IO_SIZE+0
ioa_Data	EQU IO_SIZE+2
ioa_Length	EQU	IO_SIZE+6
ioa_Period	EQU IO_SIZE+10
ioa_Volume	EQU IO_SIZE+12
ioa_Cycles	EQU IO_SIZE+14
ioa_SIZEOF	EQU IO_SIZE+16+MN_SIZE

DEV_BEGINIO	EQU -30
DEV_ABORTIO	EQU -36

; IOAudio commands
CMD_INVALID	EQU 0
CMD_RESET	EQU 1
CMD_READ	EQU 2
CMD_WRITE	EQU 3
CMD_UPDATE	EQU 4
CMD_CLEAR	EQU 5
CMD_STOP	EQU 6
CMD_START	EQU 7
CMD_FLUSH	EQU 8
CMD_NONSTD	EQU 9
ADCMD_FREE			EQU	CMD_NONSTD+0
ADCMD_SETPREC		EQU	CMD_NONSTD+1
ADCMD_FINISH		EQU	CMD_NONSTD+2
ADCMD_PERVOL		EQU	CMD_NONSTD+3
ADCMD_LOCK			EQU	CMD_NONSTD+4
ADCMD_WAITCYCLE		EQU	CMD_NONSTD+5
ADCMD_ALLOCATE		EQU	32

ADIOB_PERVOL		EQU	4
ADIOF_PERVOL		EQU	1<<4
ADIOB_SYNCCYCLE		EQU	5
ADIOF_SYNCCYCLE		EQU	1<<5
ADIOB_NOWAIT		EQU	6
ADIOF_NOWAIT		EQU	1<<6
ADIOB_WRITEMESSAGE	EQU	7
ADIOF_WRITEMESSAGE	EQU 1<<7

; Message port structure :
MP_FLAGS	EQU	LN_SIZE+0
MP_SIGBIT	EQU	LN_SIZE+1
MP_SIGTASK	EQU	LN_SIZE+2
MP_MSGLIST	EQU	LN_SIZE+6

; variables
AIOptr	equ 0
msgport	equ 4
msg		equ 8
wave	equ 12
dosbase	equ	16
stdout	equ	20
buffer	equ	24
fd		equ	28
wavelen	equ	32
freq	equ	36	; UWORD
tmp		equ	38	; UWORD
varsize	equ 40

buffersize	equ	512

clockntsc	equ 3579545
clockpal	equ 3546895

	code
start
	move.l	a0,-(sp)	; push command line pointer
	move.l	d0,-(sp)	; push command line length
	lea	-varsize(sp),sp
	clr.l	AIOptr(sp)
	clr.l	msgport(sp)
	clr.l	buffer(sp)
	clr.l	wave(sp)
	clr.l	fd(sp)

	lea	dosname(pc),a1
	moveq	#0,d0
	movea.l	4,a6	; exec.library
	jsr     _LVOOpenLibrary(a6)
	move.l	d0,dosbase(sp)
	beq		error

	movea.l	d0,a6
	jsr     _LVOOutput(a6)
	move.l	d0,stdout(sp)

	move.l	#msg1,d2
	move.l	#msg2-msg1,d3
	bsr	puts

	move.l	#buffersize,d0
	move.l	#MEMF_CLEAR,d1
	movea.l	4,a6	; exec.library
	jsr		_LVOAllocMem(a6)
	move.l	d0,buffer(sp)
	beq		error

	bsr	printhex

	move.l	#msg7,d2
	move.l	#msg8-msg7,d3
	bsr puts

	; Copy filename from comand line argument
	move.l	varsize+4(sp),a0
	move.l	buffer(sp),a1
	move.l	varsize(sp),d1
.argcpyloop
	move.b	(a0)+,d0
	cmpi.b	#32,d0
	bcs	.argcopystop
	move.b	d0,(a1)+
	dbra	d1,.argcpyloop
.argcopystop
	move.l	buffer(sp),d2
	move.l	a1,d3
	sub.l	d2,d3
	bsr	puts

	move.l	buffer(sp),d1
	move.l	#1005,d2	; MODE_OLDFILE
	movea.l	dosbase(sp),a6
	jsr	_LVOOpen(a6)
	move.l	d0,fd(sp)
	beq		error

	bsr	printhex

	move.l	fd(sp),d1
	move.l	buffer(sp),d2
	move.l	#buffersize,d3
	jsr	_LVORead(a6)

	; parse Creative Voice File
	move.l	buffer(sp),a0
	; skip header
	moveq	#0,d0
	move.b	21(a0),d0
	asl.w	#8,d0
	move.b	20(a0),d0
	add.l	d0,a0
	; block type
	move.b	(a0)+,d0	; Block type : 1 => sound data
	; block size
	moveq	#0,d0
	move.b	(a0)+,d0
	ror.l	#8,d0
	move.b	(a0)+,d0
	ror.l	#8,d0
	move.b	(a0)+,d0
	swap	d0 ; d0 = block size
	moveq.l	#0,d1
	move.b	(a0)+,d1	; frequency divisor
	move.b	(a0)+,d2	; VOC codec (0 = 8bit unsigned PCM)
	subq.l	#2,d0
	move.l	d0,wavelen(sp)
	; compute frequency
	move.w	#256,d0
	sub.w	d1,d0
	move.l	#1000000,d1
	divu.w	d0,d1
	move.w	d1,freq(sp)
	move.l	a0,a5	; save

	move.l	buffer(sp),d2
	move.l	#20,d3
	bsr puts

	move.l	#msg1,d2
	move.l	#msg2-msg1,d3
	bsr	puts

	move.l	wavelen(sp),d0
	move.l	#MEMF_CHIP+MEMF_PUBLIC,d1
	movea.l	4,a6	; exec.library
	jsr		_LVOAllocMem(a6)
	move.l	d0,wave(sp)
	beq		error

	bsr	printhex

	move.l	wave(sp),a4
	move.l	buffer(sp),a0
	adda	#buffersize,a0
.samplecopyloop1
	move.b	(a5)+,d0
	subi.b	#128,d0		; Unsigned to signed Sample conversion
	move.b	d0,(a4)+
	cmp.l	a5,a0
	bne	.samplecopyloop1

.readloop
	move.l	fd(sp),d1
	move.l	buffer(sp),d2
	move.l	#buffersize,d3
	jsr	_LVORead(a6)
	cmp.l	#0,d0
	ble	.readfinished
	subq	#1,d0
	move.l	buffer(sp),a5
.samplecopyloop2
	move.b	(a5)+,d1
	subi.b	#128,d1		; Unsigned to signed Sample conversion
	move.b	d1,(a4)+
	dbra	d0,.samplecopyloop2
	bra	.readloop

.readfinished

	move.l	#msg1,d2
	move.l	#msg2-msg1,d3
	bsr	puts

	move.l	#ioa_SIZEOF,d0
	move.l	#MEMF_PUBLIC+MEMF_CLEAR,d1
	movea.l	4,a6	; exec.library
	jsr		_LVOAllocMem(a6)
	move.l	d0,AIOptr(sp)
	beq		error

	bsr	printhex

	move.l	#msg2,d2
	move.l	#msg3-msg2,d3
	bsr puts

	movea.l	4,a6	; exec.library
	jsr		_LVOCreateMsgPort(a6)
	move.l	d0,msgport(sp)
	beq		error

	; CreatePort() :
	; AllocSignal
	; FindTask(NULL)
	; NEWLIST ?
	;movea.l	d0,a1
	;clr.b	LN_PRI(a1)	; ln_Pri
	;clr.l	LN_NAME(a1)	; ln_Name
	;jsr		_LVOAddPort(a6)

	bsr	printhex

	move.l	#msg3,d2
	move.l	#msg4-msg3,d3
	bsr puts

	move.l	msgport(sp),a0
	moveq	#0,d0
	move.b	MP_SIGBIT(a0),d0
	bsr	printhex

	move.l	#msg4,d2
	move.l	#msg5-msg4,d3
	bsr puts

	move.l	msgport(sp),a0
	move.l	MP_SIGTASK(a0),d0
	bsr	printhex

	move.l	AIOptr(sp),a1
	move.l	msgport(sp),MN_REPLYPORT(a1)
	clr.b	LN_PRI(a1)
	move.w	#ADCMD_ALLOCATE,IO_COMMAND(a1)
	move.b	#ADIOF_NOWAIT,IO_FLAGS(a1)
	clr.w	ioa_AllocKey(a1)
	move.l	#whichannel,ioa_Data(a1)
	move.l	#4,ioa_Length(a1)
	; error = OpenDevice(name, unit, ioRequest, flags)
    ; D0                 A0    D0    A1         D1
	moveq	#0,d0
	moveq	#0,d1
	lea		audiodev(pc),a0
	movea.l	4,a6	; exec.library
	jsr		_LVOOpenDevice(a6)
	tst.l	d0	; 0 if OK
	bne		error

	move.l	#msg5,d2
	move.l	#msg6-msg5,d3
	bsr puts
	move.l	AIOptr(sp),a1
	moveq	#0,d0
	move.w	ioa_AllocKey(a1),d0
	bsr printhex

	move.l	#msg6,d2
	move.l	#msg7-msg6,d3
	bsr puts

	move.l	AIOptr(sp),a1
	move.l	msgport(sp),MN_REPLYPORT(a1)
	move.w	#CMD_WRITE,IO_COMMAND(a1)
	move.b	#ADIOF_PERVOL,IO_FLAGS(a1)
	move.l	wave(sp),ioa_Data(a1)
	move.l	wavelen(sp),ioa_Length(a1)
	move.l	#clockpal,d0
	divu.w	freq(sp),d0
	move.w	d0,ioa_Period(a1)
	move.w	#64,ioa_Volume(a1)
	move.w	#1,ioa_Cycles(a1)

	; BeginIO(ioRequest),deviceNode -- start up an I/O process
	;          A1        A6
	move.l	IO_DEVICE(a1),a6
	jsr	DEV_BEGINIO(a6)

	move.l	msgport(sp),a0
	move.b	MP_SIGBIT(a0),d1
	moveq	#1,d0
	asl.l	d1,d0
	movea.l	4,a6	; exec.library
	jsr	_LVOWait(a6)

	move.l	msgport(sp),a0
	jsr	_LVOGetMsg(a6)
	move.l	d0,msg(sp)


success
	tst.l	fd(sp)
	beq	.nofd
	movea.l dosbase(sp),a6
	move.l	fd(sp),d1
	jsr	_LVOClose(a6)
.nofd

	movea.l	4,a6	; exec.library

	tst.l	buffer(sp)
	beq	.nobuffer
	move.l	buffer(sp),a1
	move.l	#buffersize,d0
	jsr	_LVOFreeMem(a6)
.nobuffer

	tst.l	wave(sp)
	beq	.nowave
	move.l	wave(sp),a1
	move.l	#2,d0
	jsr	_LVOFreeMem(a6)
.nowave

	; Deleteport
	tst.l	msgport(sp)
	beq	.nomsgport
	move.l	msgport(sp),a0
	jsr _LVODeleteMsgPort(a6)
.nomsgport

	tst.l	AIOptr(sp)
	beq	.noaioptr
	; CloseDevice
	move.l	AIOptr(sp),a1
	jsr	_LVOCloseDevice(a6)

	move.l	AIOptr(sp),a1
	move.l	#ioa_SIZEOF,d0
	jsr _LVOFreeMem(a6)
.noaioptr

	movea.l	dosbase(sp),a1
	movea.l	4,a6	; exec.library
	jsr	_LVOCloseLibrary(a6)

	moveq	#0,d0
	lea	8+varsize(sp),sp
	rts
error
	move.l	#errmsg,d2
	move.l	#errmsgend-errmsg,d3
	bsr puts
	bra	success
	;moveq	#1,d0
	;lea	8+varsize(sp),sp
	;rts

	; PC relative data :
audiodev	dc.b 'audio.device',0
dosname	dc.b 'dos.library',0
intuiname	dc.b 'intuition.library',0
hexdigits	dc.b '0123456789abcdef'

	align 2
puts	; d2 = string address, d3= string length
	movea.l	dosbase+4(sp),a6
	move.l	stdout+4(sp),d1
	jmp	_LVOWrite(a6)

printhex
	movea.l	#hexbuffer+8,a0
	lea hexdigits(pc),a1
	move.w	#7,d2
.printhexloop
	move.l	d0,d1
	lsr.l	#4,d0
	andi.l	#$f,d1
	move.b	(a1,d1),-(a0)
	dbra	d2,.printhexloop
	move.l	a0,d2
	moveq	#8,d3
	bra	puts

	data
hexbuffer	dc.b '01234567'
msg1	dc.b 10,'Mem allocated : '
msg2	dc.b 10,'MsgPort : '
msg3	dc.b 10,' SigBit : '
msg4	dc.b 10,' SigTask : '
msg5	dc.b 10,'Open Audio device. AllocKey='
msg6	dc.b 10,'Start Playing',10
msg7	dc.b 10,'Open File : '
msg8
errmsg	dc.b 10,'Error',10
errmsgend
whichannel	dc.b	1,2,4,8

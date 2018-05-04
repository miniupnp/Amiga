; Amiga hello world
; for vasmm68k_mot

; exec.library
;_LVOOpenLibrary	equ -552
_LVOOpenLibrary	equ -408
_LVOCloseLibrary	equ -414

; dos.library
_LVOWrite	EQU -48
_LVOOutput	EQU -60

; intuition.library
_LVODisplayBeep EQU -96

	code
start
	move.l	a0,-(sp)	; push command line pointer
	move.l	d0,-(sp)	; push command line length
	lea	dosname(pc),a1
	moveq	#0,d0
	movea.l	4,a6	; exec.library
	jsr     _LVOOpenLibrary(a6)
	movea.l	d0,a6
	tst.l	d0		; movea doesn't affect flags
	beq.s	error
	jsr     _LVOOutput(a6)
	move.l	d0,d1
	move.l	4(sp),d2
	move.l	(sp),d3
	move.l	d0,(sp)	; backup "Output"
	jsr	_LVOWrite(a6)
	move.l	(sp),d1
	move.l	#message,d2
	move.l	#messageend-message,d3
	jsr	_LVOWrite(a6)
	move.l	a6,a1
	movea.l	4,a6	; exec.library
	jsr	_LVOCloseLibrary(a6)
	lea intuiname(pc),a1
	moveq	#0,d0
	jsr _LVOOpenLibrary(a6)
	movea.l	d0,a6
	tst.l	d0		; movea doesn't affect flags
	beq.s	error
	suba.l	a0,a0	; a0 = 0
	jsr	_LVODisplayBeep(a6)
	jsr	_LVOWrite(a6)
	move.l	a6,a1
	movea.l	4,a6	; exec.library
	jsr	_LVOCloseLibrary(a6)

	moveq	#0,d0
	addq	#8,sp
	rts
error
	moveq	#-1,d0
	addq	#8,sp
	rts

	; PC relative data :
dosname	dc.b 'dos.library',0
intuiname	dc.b 'intuition.library',0
	;data
message	dc.b 'Hello Amiga !',10
messageend

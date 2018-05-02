; Amiga helloworld

;_LVOOpenLibrary	equ -552
_LVOOpenLibrary	equ -408
_LVOCloseLibrary	equ -414

_LVOWrite	EQU -48
_LVOOutput	EQU -60

	code
;start
	lea	dosname,a1
	moveq	#0,d0
	movea.l	4,a6	; exec.library
	jsr     _LVOOpenLibrary(a6)
	move.l	d0,a6
	;tst.l	d0
	beq.s	error
	jsr     _LVOOutput(a6)
	move.l	d0,d1
	move.l	#message,d2
	move.l	#messageend-message,d3
	jsr	_LVOWrite(a6)
	move.l	a6,a1
	movea.l	4,a6	; exec.library
	jsr	_LVOCloseLibrary(a6)
	moveq	#0,d0
	rts
error
	moveq	#-1,d0
	rts

	data
dosname	dc.b 'dos.library',0
message	dc.b 'Hello Amiga !',10
messageend

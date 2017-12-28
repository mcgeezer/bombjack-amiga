FONT_WIDTH:	equ	(416/8)*3
SCRPTR_FONT:		equ	$5e000+MEMOFF



; d0=8x8 x
; d1=8x8 y
; d6=Colour number 0-3 (0=BP1, 1=BP2, 2=BP3, 3=BP4)
; a0=text
; a1=Screen addresses
DRAW_TEXT:
	lsl.w	#3,d1

	mulu	#PLAYFIELD_SIZE_X,d1

	lsl.w	#2,d6
	move.l	(a1,d6),a1
	
	add.w	d1,a1
	add.w	d0,a1

	moveq	#0,d0
.loop:	lea	FONT_ASSET+92,a2	; start of BODY
	tst.b	(a0)
	beq	.exit
	move.b	(a0)+,d0

	cmp.b	#58,d0
	ble.s	.number
	sub.b	#39,d0
	bra.s	.draw

.number:	
	sub.b	#32,d0
	
.draw:
	add.w	d0,a2		; index into character

	move.b	(a2),(a1)
	move.b	FONT_WIDTH*1(a2),PLAYFIELD_SIZE_X*1(a1)
	move.b	FONT_WIDTH*2(a2),PLAYFIELD_SIZE_X*2(a1)
	move.b	FONT_WIDTH*3(a2),PLAYFIELD_SIZE_X*3(a1)
	move.b	FONT_WIDTH*4(a2),PLAYFIELD_SIZE_X*4(a1)
	move.b	FONT_WIDTH*5(a2),PLAYFIELD_SIZE_X*5(a1)
	move.b	FONT_WIDTH*6(a2),PLAYFIELD_SIZE_X*6(a1)
	move.b	FONT_WIDTH*7(a2),PLAYFIELD_SIZE_X*7(a1)
	
	addq.w	#1,a1
	bra	.loop
.exit:	rts


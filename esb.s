ESB_CYLON_COLOUR:	equ	11
ESB_CYLON_SPEED:	equ	1

ESB_BONUS:	equ	0
ESB_EXTRA:	equ	1
ESB_SPECIAL:	equ	2	

ESB_MOVE_RIGHT:	equ	1
ESB_MOVE_LEFT:	equ	0
ESB_FALLING:	equ	2
ESB_TURNS:		equ	1
ESB_SPEED:		equ	2

ESB_TOKEN_BONUS:	equ	0
ESB_TOKEN_EXTRA:	equ	1
ESB_TOKEN_SPECIAL:	equ	2

;
; HDL_ESB
;
; Sprite Handler for moving the Extra, Bonus and Special token.
; Pretty much the same as the Metal Man Handler, but with no turns.
;
; Each handler must have d1 set to the animation type and then a call to 
; ANIMATE made.
; 
HDL_ESB:
	move.w	d0,d1
	move.w	d0,d2
	lea	HDL_ESB_STATUS,a2	
	lsl.w	#4,d2		; multiply by 16
	add.w	d2,a2		; now pointing at sprite
	
	cmp.w	(a2),d1
	beq.s	.move
; initialize
.init	move.w	d1,(a2)
	move.w	#ESB_FALLING,2(a2)	; walk left
	move.w	#ESB_TURNS,4(a2)	; 3 turns for metal man
	move.w	#0,6(a2)	; this is the index for falling
	
	move.w	#ESB_SPEED,8(a2)	
	clr.w	10(a2)			; reset speed index
	bra.s	.move
	nop
	
.move:	move.w	8(a2),d2
	lea	SPEEDINDEX(pc),a3
	lsl.w	#2,d2
	move.l	(a3,d2),a3
	move.w	10(a2),d2
	cmp.b	#-1,(a3,d2)
	bne.s	.move1
	move.w	#-1,10(a2)
	moveq	#0,d2
	
.move1:	addq.w	#1,10(a2)
	move.b	(a3,d2),d5			; speed to add

	cmp.w	#ESB_MOVE_LEFT,2(a2)	; are we walking left?
	beq.s	.moveleft
	cmp.w	#ESB_MOVE_RIGHT,2(a2)	; are we walking right?
	beq	.moveright
	cmp.w	#ESB_FALLING,2(a2)		; is falling?
	beq	.fall
	bra	.exit

; we are moving left
.moveleft:
	moveq	#IS_OBSTACLE_LEFT,d7	; check for obstacle to the left
	bsr	CHECK_TILE_OBSTACLE	
	moveq	#0,d6
	tst.w	d7			; obstacle is there! check platform
	bmi.s	.set_move_right
	
	moveq	#IS_PLATFORM_LEFT,d7
	bsr	CHECK_TILE_OBSTACLE
	moveq	#1,d6			; do not subtract turn if obtacle
	tst.w	d7
	bpl.s	.set_move_right
	bra	.contleft			; keep walking left
	
.set_move_right:
	move.w	#ESB_MOVE_RIGHT,2(a2)	; set walking right
	sub.w	d6,4(a2)			; subtract turn
	cmp.w	#0,4(a2)
	bne	.exit
	sub.w	#16,TS_SPR16_XPOS(a1)
	move.w	#ESB_FALLING,2(a2)		; set falling
	bra	.exit

; we are walking right
.moveright:
	moveq	#IS_OBSTACLE_RIGHT,d7	; check for obstacle to the right?
	bsr	CHECK_TILE_OBSTACLE
	moveq	#0,d6			; obstacle so no turns to subtract
	tst.w	d7			; 
	bmi.s	.set_move_left		; obstacle is there, check platform

	moveq	#IS_PLATFORM_RIGHT,d7
	bsr	CHECK_TILE_OBSTACLE
	moveq	#1,d6			; platform so subtract a turn
	tst.w	d7
	bpl.s	.set_move_left
	bra.s	.contright		; keep walking right

; start walking left
.set_move_left:	
	move.w	#ESB_MOVE_LEFT,2(a2)	; yes, set walking left
	sub.w	d6,4(a2)		; subtract 1 turn

	cmp.w	#0,4(a2)		; need to set falling?
	bne	.exit
	move.w	#ESB_FALLING,2(a2)		; set falling
	add.w	#16,TS_SPR16_XPOS(a1)
	bra.s	.exit
	
.contleft:
	moveq	#TS_SPR16_WALKRIGHT,d1
	sub.w	d5,TS_SPR16_XPOS(a1)
	moveq	#0,d1
	move.w	ESB_TOKEN,d1
	bsr	ANIMATE
	bra.s	.exit
.contright:
	moveq	#TS_SPR16_WALKLEFT,d1
	add.w	d5,TS_SPR16_XPOS(a1)
	moveq	#0,d1
	move.w	ESB_TOKEN,d1
	bsr	ANIMATE
	bra.s	.exit

.fall:	moveq	#IS_PLATFORM_UNDER,d7
	bsr	CHECK_TILE_OBSTACLE
	tst.w	d7
	bmi.s	.onplatform

	addq.w	#1,6(a2)		; index
	move.w	6(a2),d2
	lsr.w	#2,d2			; half the speed when falling.
	lsl.w	#1,d2
	lea	GRAVITY(pc),a3
	move.w	(a3,d2),d2		; get number to add
	moveq	#TS_SPR16_FALLING,d1
	add.w	d2,TS_SPR16_YPOS(a1)
	moveq	#0,d1
	move.w	ESB_TOKEN,d1
	bsr	ANIMATE
	bra.s	.exit

.onplatform:

; Set metal man walking left when he hits the platform
	move.w	#ESB_MOVE_LEFT,2(a2)	; walk left
	move.w	#ESB_TURNS,4(a2)	; 3 turns for metal man
	move.w	#0,6(a2)	; this is the index for falling
	
	and.w	#$fff8,TS_SPR16_YPOS(a1)		; nearest 8 pixels
	bra	.move
.exit:	rts


ESB_CYLON:	
	move.w	ESB_TOKEN,d0
	cmp.w	#ESB_BONUS,d0
	beq.s	.bonus
	cmp.w	#ESB_EXTRA,d0
	beq.s	.extra
	cmp.w	#ESB_SPECIAL,d0
	beq.s	.special
	bra.s	.bonus	
.extra:
	lea	COPPER+2,a2
	add.l	COPPTR_MAIN_PAL,a2
	add.l	#(ESB_CYLON_COLOUR*4),a2
	move.w	PAL_ESB_EXTRA,(a2)
	bra.s	.exit

.special:
	lea	COPPER+2,a2
	add.l	COPPTR_MAIN_PAL,a2
	add.l	#(ESB_CYLON_COLOUR*4),a2
	move.w	PAL_ESB_SPECIAL,(a2)
	bra.s	.exit
	
.bonus:
	lea	PTR_ESB_CYLON,a0
.go:	lea	PAL_ESB_CYLON,a1
	move.w	(a0),d0
	
	moveq	#ESB_CYLON_SPEED,d1
	lsr.w	d1,d0
	lsl.w	#1,d0
	add.w	d0,a1
	
	cmp.w	#-1,(a1)
	bne.s	.cycle
	clr.w	(a0)
	bra.s	.go
	
.cycle:	
	lea	COPPER+2,a2		; Colour 8
	add.l	COPPTR_MAIN_PAL,a2
	add.l	#(ESB_CYLON_COLOUR*4),a2
	move.w	(a1),(a2)
	addq.w	#1,(a0)
.exit:	rts


ESB_SPRITES:	dc.l	ANIM_ESB_VARS
		dc.l	HDL_ESB
		dc.l	ANIM_ESB_BONUS
		dc.l	ANIM_ESB_EXTRA
		dc.l	ANIM_ESB_SPECIAL
		dc.l	-1

ANIM_ESB_VARS:	dc.w	0,90,90,0
		dc.l	ANIM_ESB_BUFFER

ANIM_ESB_BUFFER:	ds.l	16*(SPR16_BITPLANES*2)


ANIM_ESB_BONUS:		dc.l	ANIM_ESB_BONUS_VARS
			dc.l	ANIM_ESB_BONUS_FRAME
			dc.l	ANIM_ESB_BONUS_SPEED
			
ANIM_ESB_EXTRA:		dc.l	ANIM_ESB_EXTRA_VARS
			dc.l	ANIM_ESB_EXTRA_FRAME
			dc.l	ANIM_ESB_EXTRA_SPEED
			
ANIM_ESB_SPECIAL:	dc.l	ANIM_ESB_SPECIAL_VARS
			dc.l	ANIM_ESB_SPECIAL_FRAME
			dc.l	ANIM_ESB_SPECIAL_SPEED

ANIM_ESB_BONUS_VARS:	dc.w	0,0
ANIM_ESB_BONUS_FRAME:	dc.w	83,84,85,86,86,$ffff
ANIM_ESB_BONUS_SPEED:	dc.w	3

ANIM_ESB_EXTRA_VARS:	dc.w	0,0
ANIM_ESB_EXTRA_FRAME:	dc.w	87,88,89,90,90,$ffff
ANIM_ESB_EXTRA_SPEED:	dc.w	3

ANIM_ESB_SPECIAL_VARS:	dc.w	0,0
ANIM_ESB_SPECIAL_FRAME:	dc.w	91,92,93,94,94,$ffff
ANIM_ESB_SPECIAL_SPEED:	dc.w	3

ESB_ACTIVE:	dc.w	-1

PAL_ESB_EXTRA:	dc.w	$ff0		; brown extra
PAL_ESB_SPECIAL:	dc.w	$f00	; red special

PTR_ESB_CYLON:	dc.w	0
PAL_ESB_CYLON:	dc.w	$33f,$55f,$77f,$99f,$bbf
		dc.w	$99f,$77f,$55f,$33f,$ffff

HDL_ESB_STATUS:	ds.w	32*MAX_SPRITES

ESB_TOKEN:	dc.w	0

















POWERBALL_COLOUR_BLUE:	equ	0
POWERBALL_COLOUR_RED:	equ	1
POWERBALL_COLOUR_PINK:	equ	2
POWERBALL_COLOUR_GREEN:	equ	3
POWERBALL_COLOUR_AQUA:	equ	4
POWERBALL_COLOUR_YELLOW	equ	5
POWERBALL_COLOUR_GRAY:	equ	6

POWERBALL_PAL_COLOUR1:	equ	13
POWERBALL_PAL_COLOUR2:	equ	17
POWERBALL_CYCLE_SPEED:	equ	1

POWERBALL_SPEED:	equ	1

HDL_POWERBALL:
	movem.l	d0-d7/a0-a6,-(a7)
	lea	POWERBALL_ACTIVE(pc),a5
	tst.w	(a5)
	bmi.s	.active
	move.w	#CENTRE,TS_SPR16_XPOS(a1)	; Initialise into centre
	move.w	#CENTRE,TS_SPR16_YPOS(a1)
	move.w	#-1,(a5)			; Set active
	
.active:
	lea	SCRPTR_TILE_COLLISIONS,a5
	move.w	TS_SPR16_XPOS(a1),d4
	move.w	TS_SPR16_YPOS(a1),d5
	
.check_x_axis:
	lea	POWERBALL_DIRECTION_X(pc),a0
	tst.w	(a0)
	bmi.s	.moveleft
	bra.s	.moveright	

.moveleft:
	sub.w	#POWERBALL_SPEED,d4
	bsr	CHECK_COLLISION			; it was colliding
	tst.w	d7
	bmi	.setright
	sub.w	#POWERBALL_SPEED,TS_SPR16_XPOS(a1)	; move sprite position right
	bra.s	.check_y_axis
.setright:
	clr.w	(a0)
	bra.s	.check_y_axis
	
.moveright:
	add.w	#POWERBALL_SPEED,d4
	bsr	CHECK_COLLISION			; it was colliding
	tst.w	d7
	bmi	.setleft
	add.w	#POWERBALL_SPEED,TS_SPR16_XPOS(a1)	; move sprite position right
	bra.s	.check_y_axis
.setleft:
	move.w	#-1,(a0)
	bra.s	.check_y_axis
	nop
	
;-------
.check_y_axis:
	move.w	TS_SPR16_XPOS(a1),d4
	move.w	TS_SPR16_YPOS(a1),d5
	lea	POWERBALL_DIRECTION_Y(pc),a0
	tst.w	(a0)
	bmi.s	.moveup
	bra.s	.movedown	

.moveup:
	sub.w	#POWERBALL_SPEED,d5
	bsr	CHECK_COLLISION			; it was colliding
	tst.w	d7
	bmi	.setdown
	sub.w	#POWERBALL_SPEED,TS_SPR16_YPOS(a1)	; move sprite position right
	bra.s	.done
.setdown:
	clr.w	(a0)
	bra.s	.done
	
.movedown:
	add.w	#POWERBALL_SPEED,d5
	bsr	CHECK_COLLISION			; it was colliding
	tst.w	d7
	bmi	.setup
	add.w	#POWERBALL_SPEED,TS_SPR16_YPOS(a1)	; move sprite position right
	bra.s	.done
.setup:
	move.w	#-1,(a0)
	bra.s	.done
	nop

.done:	;bsr	POWERBALL_COLOUR_CYCLE

	movem.l	(a7)+,d0-d7/a0-a6

	moveq	#0,d1
	bsr	ANIMATE
	
.exit:	rts


POWERBALL_NEXT_COLOUR:
	move.l	a0,-(a7)
	lea	POWERBALL_COLOUR(pc),a0
	
	cmp.w	#POWERBALL_COLOUR_GRAY,(a0)
	beq.s	.reset	
	addq.w	#1,(a0)
	bra.s	.exit
.reset:	clr.w	(a0)
.exit:	move.l	(a7)+,a0
	rts


POWERBALL_COLOUR_CYCLE:
	movem.l	d0-d2/a0-a2,-(a7)
	moveq	#0,d2
	lea	POWERBALL_INDEX,a0
.go:	move.w	POWERBALL_COLOUR,d2
	lea	POWERBALL_CYCLE,a1
	lsl.w	#2,d2

	move.l	(a1,d2),a1
	move.w	(a0),d0
	moveq	#POWERBALL_CYCLE_SPEED,d1
	lsr.w	d1,d0
	lsl.w	#1,d0
	add.w	d0,a1
	
	cmp.w	#-1,(a1)
	bne.s	.cycle
	clr.w	(a0)
	bra.s	.go
	
.cycle:	
	tst.w	POWERBALL_ACTIVE
	bmi.s	.active
	move.w	RAINBOW_CYCLE,d0
	bra.s	.rainbow
	
.active:	
	move.w	(a1),d0

	lea	COPPER+2,a2		; Colour 8
	add.l	COPPTR_MAIN_PAL,a2
	add.l	#(POWERBALL_PAL_COLOUR1*4),a2
	move.w	d0,(a2)

.rainbow:	
	move.w	d0,d1
	lea	COPPER+2,a2
	add.l	COPPTR_GRADIENT_COL,a2
	
	move.w	4(a2),0(a2)
	move.w	8(a2),4(a2)
	move.w	12(a2),8(a2)
	move.w	16(a2),12(a2)
	move.w	20(a2),16(a2)
	move.w	24(a2),20(a2)
	move.w	d0,24(a2)
	
	move.w	d1,d0

	lea	COPPER+2,a2		; Colour 8
	add.l	COPPTR_MAIN_PAL,a2
	add.l	#(POWERBALL_PAL_COLOUR2*4),a2
	add.w	#$333,d0
	move.w	d0,(a2)
	
	addq.w	#1,(a0)			; Next cycle
	movem.l	(a7)+,d0-d2/a0-a2
	rts

POWERBALL_CYCLE dc.l	POWERBALL_CYCLE_BLUE
		dc.l	POWERBALL_CYCLE_RED
		dc.l	POWERBALL_CYCLE_PINK
		dc.l	POWERBALL_CYCLE_GREEN
		dc.l	POWERBALL_CYCLE_AQUA	
		dc.l	POWERBALL_CYCLE_YELLOW	
		dc.l	POWERBALL_CYCLE_GRAY
	
POWERBALL_CYCLE_BLUE:	dc.w	$001,$002,$003,$004,$005,$006,$007,$008,$007,$006,$005,$004,$003,$002,-1
POWERBALL_CYCLE_RED:	dc.w	$100,$200,$300,$400,$500,$600,$700,$800,$700,$600,$500,$400,$300,$200,-1
POWERBALL_CYCLE_PINK:	dc.w	$101,$202,$303,$404,$505,$606,$707,$808,$707,$606,$505,$404,$303,$202,-1
POWERBALL_CYCLE_GREEN:	dc.w	$010,$020,$030,$040,$050,$060,$070,$080,$070,$060,$050,$040,$030,$020,-1
POWERBALL_CYCLE_AQUA:	dc.w	$011,$022,$033,$048,$055,$066,$077,$088,$077,$066,$055,$044,$033,$022,-1
POWERBALL_CYCLE_YELLOW:	dc.w	$110,$220,$330,$440,$550,$660,$770,$880,$770,$660,$550,$440,$330,$220,-1
POWERBALL_CYCLE_GRAY:	dc.w	$111,$222,$333,$444,$555,$666,$777,$888,$999,$aaa,$999,$888,$777,$666,$555,$444,$333,$222,-1

POWERBALL_ACTIVE:	dc.w	0	; -1 = true; 0 = false

POWERBALL_DIRECTION_X:	dc.w	0	; -1=Left, 0=Right
POWERBALL_DIRECTION_Y:	dc.w	0	; -1=Up, 0=Down
POWERBALL_START:	dc.w	0
POWERBALL_COLOUR:	dc.w	POWERBALL_COLOUR_GRAY	; Start on Blue

POWERBALL_INDEX:	dc.w	0

POWERBALL:	dc.l	ANIM_POWERBALL_VARS
		dc.l	HDL_DUMMY
		dc.l	ANIM_POWERBALL_MOVE
		dc.w	-1

ANIM_POWERBALL_VARS:	dc.w	0,0,0,$0		
			dc.l	ANIM_POWERBALL_BUFFER

ANIM_POWERBALL_BUFFER:	ds.l	16*(SPR16_BITPLANES*2)

ANIM_POWERBALL_MOVE:	dc.l	ANIM_POWERBALL_MOVE_VARS
			dc.l	ANIM_POWERBALL_MOVE_FRAME
			dc.l	ANIM_POWERBALL_MOVE_SPEED
			
ANIM_POWERBALL_MOVE_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_POWERBALL_MOVE_FRAME	dc.w	95,95,95,95,$ffff
ANIM_POWERBALL_MOVE_SPEED	dc.w	2



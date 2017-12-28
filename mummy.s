
MUMMY_WALK_RIGHT:	equ	1
MUMMY_WALK_LEFT:	equ	0
MUMMY_FALLING:	equ	2
MUMMY_SPEED:		equ	3

;
; HDL_MUMMY
;
; Sprite Handler for moving the Metal Man
; Upon entry d0 will have the sprite number.
; Upon entry a1 will have a pointer to the sprite attributes.
;
; Each handler must have d1 set to the animation type and then a call to 
; ANIMATE made.
; 


HDL_MUMMY:
	move.w	d0,d1
	move.w	d0,d2
	lea	HDL_MUMMY_STATUS,a2	
	lsl.w	#4,d2		; multiply by 16
	add.w	d2,a2		; now pointing at sprite
	
	cmp.w	(a2),d1
	beq.s	.walk
; initialize
.init	move.w	d1,(a2)
	move.w	#MUMMY_FALLING,2(a2)	; walk left
	move.w	MUMMY_TURNS,4(a2)	; 3 turns for metal man
	move.w	#0,6(a2)	; this is the index for falling
	
	move.w	#MUMMY_SPEED,8(a2)	
	clr.w	10(a2)			; reset speed index
	
	bra.s	.walk
	
	nop
	
.walk:	move.w	8(a2),d2
	lea	SPEEDINDEX(pc),a3
	lsl.w	#2,d2
	move.l	(a3,d2),a3
	move.w	10(a2),d2
	cmp.b	#-1,(a3,d2)
	bne.s	.walk1
	move.w	#-1,10(a2)
	moveq	#0,d2
	
.walk1:	addq.w	#1,10(a2)
	move.b	(a3,d2),d5			; speed to add

	cmp.w	#MUMMY_WALK_LEFT,2(a2)	; are we walking left?
	beq.s	.walkleft
	cmp.w	#MUMMY_WALK_RIGHT,2(a2)	; are we walking right?
	beq	.walkright
	cmp.w	#MUMMY_FALLING,2(a2)		; is falling?
	beq	.fall
	bra	.exit

; we are walking left
.walkleft:
	moveq	#IS_OBSTACLE_LEFT,d7	; check for obstacle to the left
	bsr	CHECK_TILE_OBSTACLE	
	moveq	#0,d6
	tst.w	d7			; obstacle is there! check platform
	bmi.s	.set_walk_right
	
	moveq	#IS_PLATFORM_LEFT,d7
	bsr	CHECK_TILE_OBSTACLE
	moveq	#1,d6			; do not subtract turn if obtacle
	tst.w	d7
	bpl.s	.set_walk_right
	bra	.contleft			; keep walking left
	
.set_walk_right:
	move.w	#MUMMY_WALK_RIGHT,2(a2)	; set walking right
	sub.w	d6,4(a2)			; subtract turn
	cmp.w	#0,4(a2)
	bne	.exit
	sub.w	#16,TS_SPR16_XPOS(a1)
	move.w	#MUMMY_FALLING,2(a2)		; set falling
	bra	.exit

; we are walking right
.walkright:
	moveq	#IS_OBSTACLE_RIGHT,d7	; check for obstacle to the right?
	bsr	CHECK_TILE_OBSTACLE
	moveq	#0,d6			; obstacle so no turns to subtract
	tst.w	d7			; 
	bmi.s	.set_walk_left		; obstacle is there, check platform

	moveq	#IS_PLATFORM_RIGHT,d7
	bsr	CHECK_TILE_OBSTACLE
	moveq	#1,d6			; platform so subtract a turn
	tst.w	d7
	bpl.s	.set_walk_left
	bra.s	.contright		; keep walking right
	

; start walking left
.set_walk_left:	
	move.w	#MUMMY_WALK_LEFT,2(a2)	; yes, set walking left
	sub.w	d6,4(a2)		; subtract 1 turn

	cmp.w	#0,4(a2)		; need to set falling?
	bne.s	.exit
	move.w	#MUMMY_FALLING,2(a2)		; set falling
	add.w	#16,TS_SPR16_XPOS(a1)
	bra.s	.exit
	
.contleft:
	moveq	#TS_SPR16_WALKRIGHT,d1
	sub.w	d5,TS_SPR16_XPOS(a1)
	bsr	ANIMATE
	bra.s	.exit
.contright:
	moveq	#TS_SPR16_WALKLEFT,d1
	add.w	d5,TS_SPR16_XPOS(a1)
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
	bsr	ANIMATE
	bra.s	.exit

.onplatform:

; Set metal man walking left when he hits the platform
	move.w	#MUMMY_WALK_LEFT,2(a2)	; walk left
	move.w	MUMMY_TURNS,4(a2)	; 3 turns for metal man
	move.w	#0,6(a2)	; this is the index for falling
	
	and.w	#$fff8,TS_SPR16_YPOS(a1)		; nearest 8 pixels
	bra	.walk

.exit:	rts

HDL_MUMMY_STATUS:	ds.w	32*MAX_SPRITES

MUMMY_TURNS:	dc.w	0

ENEMY_START_POSITIONS:	ds.w	4

ENY_MUMMY	dc.l	ANIM_MM_VARS
		dc.l	HDL_MUMMY
		dc.l	ANIM_MM_STANDING
		dc.l	ANIM_MM_WALKLEFT
		dc.l	ANIM_MM_WALKRIGHT	
		dc.l	ANIM_MM_FALLING					
		dc.w	-1

ANIM_MM_VARS:		dc.w	0,32,0,0
			dc.l	ANIM_MM_BUFFER

ANIM_MM_BUFFER:		ds.l	16*(SPR16_BITPLANES*2)

ANIM_MM_STANDING:	dc.l	ANIM_MM_STANDING_VARS	; 12 bytes
			dc.l	ANIM_MM_STANDING_FRAME
			dc.l	ANIM_MM_STANDING_SPEED
			
ANIM_MM_WALKLEFT:	dc.l	ANIM_MM_WALKLEFT_VARS
			dc.l	ANIM_MM_WALKLEFT_FRAME
			dc.l	ANIM_MM_WALKLEFT_SPEED


ANIM_MM_WALKRIGHT:	dc.l	ANIM_MM_WALKRIGHT_VARS
			dc.l	ANIM_MM_WALKRIGHT_FRAME
			dc.l	ANIM_MM_WALKRIGHT_SPEED
			
ANIM_MM_FALLING:	dc.l	ANIM_MM_FALLING_VARS
			dc.l	ANIM_MM_FALLING_FRAME
			dc.l	ANIM_MM_FALLING_SPEED

ANIM_MM_STANDING_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_MM_STANDING_FRAME:	dc.w	25,26,$ffff
ANIM_MM_STANDING_SPEED:	dc.w	6	

ANIM_MM_WALKLEFT_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_MM_WALKLEFT_FRAME:	dc.w	27,28,29,$ffff
ANIM_MM_WALKLEFT_SPEED:	dc.w	9

ANIM_MM_WALKRIGHT_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_MM_WALKRIGHT_FRAME:	dc.w	30,31,32,$ffff
ANIM_MM_WALKRIGHT_SPEED:	dc.w	9

ANIM_MM_FALLING_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_MM_FALLING_FRAME:	dc.w	25,26,$ffff
ANIM_MM_FALLING_SPEED:	dc.w	6







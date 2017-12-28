
BJ_MOVE_SPEED:	equ	2

;
; HDL_BOMBJACK	
;
; Sprite Handler for moving Player 1 Bomback
; Probes Joystick directions and moves left or right.
;
; Upon entry d0 will have the sprite number
; Upon entry a1 will point to the sprite attributes.
; Each handler must have d1 to the animation type
; and then call ANIMATE.
;  
HDL_BOMBJACK:
	bsr	JOYDETECT
	lea	SCRPTR_TILE_COLLISIONS,a5
	move.w	TS_SPR16_XPOS(a1),d4
	move.w	TS_SPR16_YPOS(a1),d5
	cmp.w	#JOY1_NO_MOVE,d3
	bne.s	.check_right
	moveq	#TS_SPR16_STANDING,d1		; Animate sprite standing
	
.check_right:	
	cmp.w	#JOY1_RIGHT,d3
	bne.s	.check_left
	moveq	#TS_SPR16_WALKRIGHT,d1
	tst.w	d4
	bmi	.enemy
	
	sub.w	#BJ_MOVE_SPEED,d4		; check if next frame will
	bsr	CHECK_COLLISION		 ; collide.
	tst.w	d7
	bmi	.enemy
	sub.w	#BJ_MOVE_SPEED,TS_SPR16_XPOS(a1) ; move sprite X POS
	bra	.enemy

.check_left:	
	cmp.w	#JOY1_LEFT,d3
	bne.s	.check_up
	moveq	#TS_SPR16_WALKLEFT,d1
	tst.w	d4
	bmi	.enemy

	add.w	#BJ_MOVE_SPEED,d4
	cmp.w	#202,d4
	bge	.enemy
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	add.w	#BJ_MOVE_SPEED,TS_SPR16_XPOS(a1)	; move sprite position right
	bra	.enemy

.check_up:	
	cmp.w	#JOY1_UP,d3
	bne.s	.check_down
	moveq	#TS_SPR16_STANDING,d1
	
	sub.w	#BJ_MOVE_SPEED,d5
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	sub.w	#BJ_MOVE_SPEED,TS_SPR16_YPOS(a1)
	bra	.enemy
	
.check_down:	
	cmp.w	#JOY1_DOWN,d3
	bne.s	.check_up_right
	moveq	#TS_SPR16_STANDING,d1
	
	add.w	#BJ_MOVE_SPEED,d5
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	add.w	#BJ_MOVE_SPEED,TS_SPR16_YPOS(a1)
	bra	.enemy
	
.check_up_right:
	cmp.w	#JOY1_UP_RIGHT,d3
	bne.s	.check_down_right
	moveq	#TS_SPR16_WALKLEFT,d1
	
	add.w	#BJ_MOVE_SPEED,d4
	sub.w	#BJ_MOVE_SPEED,d5
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	add.w	#BJ_MOVE_SPEED,TS_SPR16_XPOS(a1)
	sub.w	#BJ_MOVE_SPEED,TS_SPR16_YPOS(a1)
	bra.s	.enemy
	
.check_down_right:
	cmp.w	#JOY1_DOWN_RIGHT,d3		; working
	bne.s	.check_up_left
	moveq	#TS_SPR16_WALKLEFT,d1
	
	add.w	#BJ_MOVE_SPEED,d4
	add.w	#BJ_MOVE_SPEED,d5
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	add.w	#BJ_MOVE_SPEED,TS_SPR16_XPOS(a1)
	add.w	#BJ_MOVE_SPEED,TS_SPR16_YPOS(a1)
	bra.s	.enemy

.check_up_left:
	cmp.w	#JOY1_UP_LEFT,d3		; working
	bne.s	.check_down_left
	moveq	#TS_SPR16_WALKRIGHT,d1
	
	sub.w	#BJ_MOVE_SPEED,d4
	sub.w	#BJ_MOVE_SPEED,d5
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	sub.w	#BJ_MOVE_SPEED,TS_SPR16_XPOS(a1)
	sub.w	#BJ_MOVE_SPEED,TS_SPR16_YPOS(a1)
	bra.s	.enemy
	
.check_down_left:
	cmp.w	#JOY1_DOWN_LEFT,d3		; working
	bne.s	.check_done
	moveq	#TS_SPR16_WALKRIGHT,d1
	
	sub.w	#BJ_MOVE_SPEED,d4
	add.w	#BJ_MOVE_SPEED,d5
	bsr	CHECK_COLLISION
	tst.w	d7
	bmi	.enemy
	sub.w	#BJ_MOVE_SPEED,TS_SPR16_XPOS(a1)
	add.w	#BJ_MOVE_SPEED,TS_SPR16_YPOS(a1)
	bra.s	.enemy

.check_done:
	moveq	#TS_SPR16_STANDING,d1	
.enemy:
	tst.w	d7
	bpl.s	.skip_colour_cycle
	bsr	POWERBALL_NEXT_COLOUR
	
.skip_colour_cycle:
	move.w	TS_SPR16_XPOS(a1),d4
	move.w	TS_SPR16_YPOS(a1),d5
	move.w	d4,BJ_XPOS
	move.w	d5,BJ_YPOS
	
; Set the zone that Bombjack is currently in.
; Used so that Enemies always generate away from him.
	lea	BJ_ZONE(pc),a5
	cmp.w	#CENTRE,d4
	blt.s	.leftzone
	move.w	#-1,(a5)
	bra.s	.enemy1	
	
.leftzone:
	clr.w	(a5)
	
.enemy1:
; check enemy
	lea	SCRPTR_ENEMY_COLLISIONS,a5
	bsr	CHECK_COLLISION
	tst.w	d7
	bpl.s	.bomb
	nop
	move.w	#$070,$dff180		; enemy touching

.bomb:
	move.l	d0,-(a7)
	move.l	d1,-(a7)
	
	move.w	BJ_XPOS,d4
	move.w	BJ_YPOS,d5
	move.w	d4,$80000
	move.w	d5,$80002

	lea	SCRPTR_BOMB_COLLISIONS,a5
	bsr	CHECK_COLLISION
	tst.w	d7			; No collision
	bpl	.anim1
	
	bsr	FIND_BOMB_IN_MAP
	tst.b	d7
	bmi	.anim1
	and.l	#$ff,d7

		
	
; d7 has the bomb number that was touched.
; Remove the mask for this bomb
; Remove the bomb from the bomb list
; Find the next bomb to light (if a bomb isn't already lit)
; Restore background from pre over this bomb
; Add a sprite that animates the bomb being collected.

	move.w	d7,d1
	bsr	REMOVE_BOMB_MASK

	move.w	d7,d1
	bsr	REMOVE_BOMB_SPRITE

; There needs to be multiple bombs... so we to maintain a free list
; controlling bombs 2,3,4 as these might always be present on screen
	bsr	GET_NEXT_FREE_COLLECT_BOMB
	bsr	ENABLE_SPRITE
	bsr	DETONATE_BOMB	

	move.w	d7,d1
	bsr	REMOVE_BOMB_FROM_LIST
; returns d6 -1 if collected bomb was lit, 0 otherwise


	move.w	NEW_BOMB_TOUCHED,OLD_BOMB_TOUCHED ; check still collision
	move.w	d7,NEW_BOMB_TOUCHED
	cmp.w	OLD_BOMB_TOUCHED(pc),d7
	beq	.anim1	
	add.w	#1,VAR_POWERMETER



	tst.w	ANY_BOMB_TOUCHED	; Was any bomb lit.?
	bmi.s	.light_next		; No so light the next one. 
					; Yes a bomb is lit.


	tst.w	d6			; Was it the bomb we touched?
	bpl.s	.anim1			; No so don't light another bomb. 

; This routine lights the next bomb
.light_next:
	add.w	#1,VAR_POWERMETER	; touched a lit bomb!
	clr.w	ANY_BOMB_TOUCHED
	
; Light next bomb in list					
	move.w	d7,d1
	bsr	GET_NEXT_BOMB_IN_LIST

; If the bomb collected was the last one (24 then just loop to 1)
	cmp.b	#NUM_BOMBS,d7
	bne.s	.nextbomb
	moveq	#0,d7			; light bomb 1
.nextbomb:
	move.w	d7,d1
	bsr	LIGHT_BOMB
	moveq	#LIT_BOMB,d0
	bsr	ENABLE_SPRITE

.anim1:	
.powerball:
	move.w	TS_SPR16_XPOS(a1),d4
	move.w	TS_SPR16_YPOS(a1),d5
	tst.w	POWERBALL_ACTIVE
	bpl.s	.esb
	
	lea	SCRPTR_POWER_COLLISIONS,a5
	bsr	CHECK_COLLISION
	tst.w	d7
	bpl.s	.esb
	clr.w	POWERBALL_ACTIVE
	clr.w	VAR_POWERMETER
	moveq	#7,d0
	bsr	DISABLE_SPRITE

.esb:
	move.w	TS_SPR16_XPOS(a1),d4
	move.w	TS_SPR16_YPOS(a1),d5
	tst.w	ESB_ACTIVE
	bpl.s	.exit
	
	lea	SCRPTR_ESB_COLLISIONS,a5
	bsr	CHECK_COLLISION
	tst.w	d7
	bpl.s	.exit
	add.w	#1,VAR_BONUS_MULTI
	moveq	#9,d0
	bsr	DISABLE_SPRITE

.exit:	move.l	(a7)+,d1
	move.l	(a7)+,d0
;	moveq	#1,d0			; Bomb is sprite number 2
;	moveq	#0,d1			; Use lit bomb
	bsr	ANIMATE		; animate sprite
	rts	

; Holder for Bombjacks position cordinates
; Come in handy for enemies going after him.
BJ_XPOS:	dc.w	0
BJ_YPOS:	dc.w	0
BJ_ZONE:	dc.w	0 ; (0=in left zone, 1=right zone)
BJ_LIVES:	dc.w	3



PLY1_SPRITES:	dc.l	ANIM_BJ_VARS		; temp vars for sprite
		dc.l	HDL_BOMBJACK		; Sprite control handler
		dc.l	ANIM_BJ_STANDING	; 0 Standing Still
		dc.l	ANIM_BJ_WALKLEFT	; 1 Sprite 0 walk left
		dc.l	ANIM_BJ_WALKRIGHT	; 2 Sprite 0 walk right
		dc.w	-1

ANIM_BJ_VARS:		dc.w	0,16,0,0		; 8
			dc.l	ANIM_BJ_BUFFER		; 8
			
ANIM_BJ_BUFFER:		ds.l	16*(SPR16_BITPLANES*2)

ANIM_BJ_STANDING:	dc.l	ANIM_BJ_STANDING_VARS	; 12 bytes
			dc.l	ANIM_BJ_STANDING_FRAME
			dc.l	ANIM_BJ_STANDING_SPEED

ANIM_BJ_WALKLEFT:	dc.l	ANIM_BJ_WALKLEFT_VARS
			dc.l	ANIM_BJ_WALKLEFT_FRAME
			dc.l	ANIM_BJ_WALKLEFT_SPEED

ANIM_BJ_WALKRIGHT:	dc.l	ANIM_BJ_WALKRIGHT_VARS
			dc.l	ANIM_BJ_WALKRIGHT_FRAME
			dc.l	ANIM_BJ_WALKRIGHT_SPEED
			even

ANIM_BJ_STANDING_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_BJ_STANDING_FRAME:	dc.w	0,0,9,9,$ffff
ANIM_BJ_STANDING_SPEED:	dc.w	6

ANIM_BJ_WALKRIGHT_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_BJ_WALKRIGHT_FRAME:	dc.w	5,6,7,8,$ffff
ANIM_BJ_WALKRIGHT_SPEED:	dc.w	6	

ANIM_BJ_WALKLEFT_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_BJ_WALKLEFT_FRAME:	dc.w	1,2,3,4,$ffff
ANIM_BJ_WALKLEFT_SPEED:	dc.w	6	






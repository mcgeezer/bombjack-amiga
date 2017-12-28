SCRPTR_TILE_COLLISIONS:	equ	$48000+MEMOFF
SCRPTR_ENEMY_COLLISIONS	equ	$4a000+MEMOFF
SCRPTR_BOMB_COLLISIONS:	equ	$4c000+MEMOFF
SCRPTR_POWER_COLLISIONS	equ	$4e000+MEMOFF
SCRPTR_ESB_COLLISIONS:	equ	$5c000+MEMOFF

IS_OBSTACLE_LEFT:	equ	2
IS_OBSTACLE_RIGHT:	equ	1
IS_PLATFORM_LEFT:	equ	3
IS_PLATFORM_RIGHT:	equ	4
IS_PLATFORM_UNDER:	equ	5
IS_WALL_LEFT:		equ	6
IS_WALL_RIGHT:		equ	7
IS_PLATFORM_ABOVE:	equ	8

;
; CHECK_TILE_OBSTACLE (needs improvement)
;
; Check tile obstacle routine used for knowing where Metal man is on
; platforms.
;
; In:
;	d7 = Obstacle type to check
;

CHECK_TILE_OBSTACLE:
	lea	LEVEL_1_TILES(pc),a6
	move.w	TS_SPR16_XPOS(a1),d3
	move.w	TS_SPR16_YPOS(a1),d4

	lsr.w	#3,d3			; divide by 8 to get byte position
	lsr.w	#3,d4			
	mulu	#PLAYFIELD_SIZE_X,d4	; multiply by 5 8 bytes
	
	add.w	d3,a6
	add.w	d4,a6			; a6 now points to position of 
					; this sprite in the array.
	
	cmp.w	#IS_OBSTACLE_LEFT,d7
	beq.s	.check_obs_left
	cmp.w	#IS_OBSTACLE_RIGHT,d7
	beq.s	.check_obs_right
	cmp.w	#IS_PLATFORM_LEFT,d7
	beq.s	.check_plat_left
	cmp.w	#IS_PLATFORM_RIGHT,d7
	beq.s	.check_plat_right
	cmp.w	#IS_PLATFORM_UNDER,d7
	beq.s	.check_plat_under
	cmp.w	#IS_WALL_LEFT,d7
	beq.s	.check_wall_left
	cmp.w	#IS_WALL_RIGHT,d7
	beq.s	.check_wall_right
	cmp.w	#IS_PLATFORM_ABOVE,d7
	beq.s	.check_plat_above

	
; get current pixel blocks to the right
.check_obs_left:
	moveq	#0,d3
	add.b	0(a6),d3
	add.b	PLAYFIELD_SIZE_X(a6),d3
	bra.s	.check
	
.check_wall_left:
	moveq	#0,d3
	add.b	0(a6),d3
	add.b	PLAYFIELD_SIZE_X(a6),d3
	bra.s	.check
	
.check_obs_right:
	moveq	#0,d3
	add.b	2(a6),d3
	add.b	PLAYFIELD_SIZE_X+2(a6),d3
	bra.s	.check
	
.check_wall_right:
	moveq	#0,d3
	add.b	2(a6),d3
	add.b	PLAYFIELD_SIZE_X+2(a6),d3
	bra.s	.check

.check_plat_left:
	moveq	#0,d3
	add.b	PLAYFIELD_SIZE_X*2(a6),d3
	bra.s	.check
	
.check_plat_right:
	moveq	#0,d3
	add.b	(PLAYFIELD_SIZE_X*2)+2(a6),d3
	bra.s	.check
	
.check_plat_above:
	moveq	#0,d3
;	add.b	-1(a6),d3
	add.b	0(a6),d3
	add.b	1(a6),d3
;	add.b	2(a6),d3
	bra.s	.check
	
.check_plat_under:
	moveq	#0,d3
	add.b	PLAYFIELD_SIZE_X*2(a6),d3		; platform center
	add.b	(PLAYFIELD_SIZE_X*2)+1(a6),d3
;	add.b	(PLAYFIELD_SIZE_X*2)+2(a6),d3
	bra.s	.check
	nop
	
.check:	moveq	#0,d7
	tst.w	d3
	beq.s	.exit
	moveq	#-1,d7
	
.exit:	rts



;
; CHECK_COLLISION
;
; Check collision with Bomb jack
; Plots the bombjack mask into the desired collision screen and 
; returns if it hit anything.
;
; In:
; 	d0 = Sprite number to check (normally always 0 for bombjack)
; 	d4 = Bomb Jack's xpos (typically)
; 	d5 = Bomb Jack's ypos (typically)
; 	a5 = Collision screen to check
; 	
; Out:
;	d4 = 0 no collision, -1 = collision
;

CHECK_COLLISION:
	move.l	d0,-(a7)
	move.l	d1,-(a7)
	move.l	a0,-(a7)
	move.l	a1,-(a7)
	move.w	d0,d7
	
; Get the sprite mask addresses first
	bsr	GET_SPRITE_POINTER	; a0 now has sprite pointer
	tst.w	(a0)
	bmi.s	.exit

	move.l	a0,a6
	
	move.w	(a0),d0			; current sprite number 
	bsr	GET_SPRITE_MASK_POINTERS ; a2=sprite asset, a3=mask offset
	
; Now get sprite attributes
	move.w	d7,d0
	move.l	a6,a0

	move.w	d4,d0			; Arbitrary 
	move.w	d5,d1			
	move.w	TS_SPR16_CTL1(a0),d3	; Get control word

	move.w	d0,d3
	and.w	#$f,d3
	lsl.w	#8,d3
	lsl.w	#4,d3			; bits to shift needs to be in upper
	bsr	GET_SPRITE_OFFSETS

; a2=Sprite address (4 SPR16_BITPLANES)
; a3=Mask address plane
; d0=X offset words to add per plane
; d1=Y Offset to add per plane
; d3=Number of bits to rotate.
; d4=Words per plane wide
	
	move.l	a5,a1			; Screen address
	add.w	d0,a1			; add X word offset
	add.w	d1,a1			; add Y line offset
		
	lea	CHIPBASE,a6	
	bsr	WAIT_FOR_BLITTER
	
	move.w	d3,d4
	or.w	#$0aa0,d4		; a + c + d
	move.w	d4,BLTCON0(a6)
	move.w	d3,BLTCON1(a6)	
	move.w	#$ffff,BLTAFWM(a6)	; Only want the first word
	move.w	#$0,BLTALWM(a6)		; Dump the last word
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTAMOD(a6)
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTCMOD(a6)	
	move.l	a3,BLTAPTH(a6)		; Load the mask address
	move.l	a1,BLTCPTH(a6)		; Destination background
	move.w	#(SPR16_SIZE*64)+2,BLTSIZE(a6)
	
	bsr	WAIT_FOR_BLITTER
	
	moveq	#0,d7
	btst	#13,DMACONR(a6)
	bne.s	.exit
	moveq	#-1,d7
;	move.w	#$700,$dff180
.exit:	move.l	(a7)+,a1
	move.l	(a7)+,a0
	move.l	(a7)+,d1
	move.l	(a7)+,d0
	rts

;
; PLOT_CHECK_WINDOW
;
; This routine determines if an enemy is with 16 pixels of Bomb Jack
; If it is then plot the sprite mask, otherwise don't bother.
;
; In:
;	d0 = enemy sprite xpos
;	d1 = enemy sprite ypos
;
PLOT_CHECK_WINDOW:
	movem.l	d0-d3,-(a7)
	moveq	#0,d4
	move.w	BJ_XPOS(pc),d2
	move.w	BJ_YPOS(pc),d3
	sub.w	#16,d2
	sub.w	#16,d3
	
; check x position
.win_left:
	cmp.w	d0,d2
	bgt.s	.done
	add.w	#48,d2
	cmp.w	d0,d2
	blt.s	.done
	nop
	cmp.w	d1,d3
	bgt.s	.done
	add.w	#48,d3
	cmp.w	d1,d3
	blt.s	.done
	moveq	#-1,d4			; is within window
; 	
	
.done:	movem.l	(a7)+,d0-d3
	rts


;d3 = Screen number (Matches sprite type)
; 0 = Tile screen
; 1 = Enemies
; 2 = Bombs
; 3 = Power balls
; a1 = returned screen
;
GET_COLLISION_SCREEN:
	move.l	d0,-(a7)
	move.l	a0,-(a7)
	lea	LSTPTR_COLLISION_SCREENS,a0
	lsl.w	#2,d3
	move.l	(a0,d3),a1
	move.l	(a7)+,a0
	move.l	(a7)+,d0
	rts	


LSTPTR_COLLISION_SCREENS:	dc.l	SCRPTR_TILE_COLLISIONS
				dc.l	SCRPTR_ENEMY_COLLISIONS
				dc.l	SCRPTR_BOMB_COLLISIONS
				dc.l	SCRPTR_POWER_COLLISIONS
				dc.l	SCRPTR_ENEMY_COLLISIONS ; smiley
				dc.l	SCRPTR_ESB_COLLISIONS ; ESB

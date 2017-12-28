

;
; DRAW_8X8_TILES
;
; Draws the 8x8 platform tiles
; In: 
; 	a0 = Pointer to tile map
;
DRAW_8X8_TILES:
	moveq	#0,d0
	moveq	#0,d2
	moveq	#PLAYFIELD_SIZE_Y-1,d4			; 28 rows down
	
.loop3:	moveq	#0,d1
	moveq	#(PLAYFIELD_SIZE_X-1),d5		; 28 rows wide
	
.loop2:	move.b	(a0)+,d0

	cmp.b	#$ff,d0
	beq.s	.set_enemy_left		; Get enemy start left
						; Position

	cmp.b	#$fe,d0
	beq.s	.set_enemy_right

	cmp.b	#0,d0
	bne.s	.drawblock
	bra	.next

.set_enemy_left:
	lea	ENEMY_START_POSITIONS(pc),a4
	moveq	#0,d6
	move.w	d1,d6
	lsl.w	#3,d6
	move.w	d6,(a4)				; set left x position
	moveq	#0,d6
	move.w	d2,d6
	lsl.w	#3,d6
	subq.w	#2,d6
	move.w	d6,2(a4)			; set left y position
	bra	.next

.set_enemy_right:
	lea	ENEMY_START_POSITIONS(pc),a4
	moveq	#0,d6
	move.w	d1,d6
	lsl.w	#3,d6
	move.w	d6,4(a4)			; set right x position
	moveq	#0,d6
	move.w	d2,d6
	lsl.w	#3,d6
	subq.w	#2,d6
	move.w	d6,6(a4)			; set right y position
	bra	.next

.drawblock:
	bsr	DRAW_8X8_TILE
	
	
.next:	addq.l	#1,d1			; Increment X
	dbf	d5,.loop2
	addq.l	#1,d2			; Increment Y
	dbf	d4,.loop3
	rts

; a2 = screen pointers or a0 = mask screen if d3=-1
; d0 = tile number
; d1 = X Position
; d2 = Y Position
; d3 = -1 (First Plane Only) for mask, 0 = all planes
DRAW_8X8_TILE:
	movem.l	d0-d7/a0-a6,-(a7)
	
	move.l	a2,a0
	
;	lsr.w	#3,d1			; div x by 8
	mulu	#(PLAYFIELD_SIZE_X*8),d2
;	lsr.w	#3,d2			; div y by 8
	
	moveq	#PLAYFIELD_BITPLANES-1,d7

	subq.w	#1,d0
	move.l	a2,a1			; Mask so direct for screen plane
	
	lea	SPR16_ASSETS,a2

.loop:	tst.w	d3
	bmi	.maskonly		; don't load next screen if mask

	lea	SPR16_ASSETS,a2
.planeloop
	move.l	(a0)+,a1		; first screen plane
	
.maskonly:	
	add.l	d2,a1
	add.l	d1,a1			; Index into screen
	
.maskloop:
	move.l	(a2)+,a3		; Get first bit plane
	add.l	#(SPRITE_ASSETS_SIZE_X*127),a3

	add.l	d0,a3			; a3 now at tile object

	tst.w	d3
	bpl.s	.draw_plane
	
.draw_mask:
	move.b	(a3),d5
	or.b	d5,(a1)
	move.b	SPRITE_ASSETS_SIZE_X*1(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*1(a1)
	move.b	SPRITE_ASSETS_SIZE_X*2(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*2(a1)
	move.b	SPRITE_ASSETS_SIZE_X*3(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*3(a1)
	move.b	SPRITE_ASSETS_SIZE_X*4(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*4(a1)
	move.b	SPRITE_ASSETS_SIZE_X*5(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*5(a1)
	move.b	SPRITE_ASSETS_SIZE_X*6(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*6(a1)
	move.b	SPRITE_ASSETS_SIZE_X*7(a3),d5
	or.b	d5,PLAYFIELD_SIZE_X*7(a1)
	dbf	d7,.maskloop
	bra.s	.exit
	
.draw_plane:
	move.b	(a3),(a1)
	move.b	SPRITE_ASSETS_SIZE_X*1(a3),PLAYFIELD_SIZE_X*1(a1)
	move.b	SPRITE_ASSETS_SIZE_X*2(a3),PLAYFIELD_SIZE_X*2(a1)
	move.b	SPRITE_ASSETS_SIZE_X*3(a3),PLAYFIELD_SIZE_X*3(a1)
	move.b	SPRITE_ASSETS_SIZE_X*4(a3),PLAYFIELD_SIZE_X*4(a1)
	move.b	SPRITE_ASSETS_SIZE_X*5(a3),PLAYFIELD_SIZE_X*5(a1)
	move.b	SPRITE_ASSETS_SIZE_X*6(a3),PLAYFIELD_SIZE_X*6(a1)
	move.b	SPRITE_ASSETS_SIZE_X*7(a3),PLAYFIELD_SIZE_X*7(a1)

.next:	dbf	d7,.planeloop

.exit:			
	movem.l	(a7)+,d0-d7/a0-a6
	rts
	

; SET_TILE_COLOURS
; 
; Sets the colour of the tiles depending on the scene that is shown.
;
; In:
;	a0 = Pointer to colour pallete
;	a1 = Scene colour index (the five scenes have different colour indexes)	

SET_TILE_COLOURS:
	lea	COPPER+2,a2
	add.l	COPPTR_MAIN_PAL,a2
	move.w	(a1)+,d1
	lsl.w	#2,d1		; mulitply by 4
	add.w	d1,a2		; index to colours
	moveq	#3,d7
.loop:
	move.w	(a0)+,d0
	move.w	d0,(a2)
	addq.w	#4,a2
	
	dbf	d7,.loop
	rts

	
TILE_COLOURS_EGYPT:	dc.w	24,25,26,27
TILE_COLOURS_RED:	dc.w	$600,$800,$a00,$c00
TILE_COLOURS_ORANGE:	dc.w	$fd0,$fa0,$f70,$f40



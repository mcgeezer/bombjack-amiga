
MAX_COLLECT_BOMBS:	equ	5

SPR_BOMB_ASSET:	equ	99
NUM_BOMBS:	equ	24	; Number of bombs per round.

BOMB_LIT:	equ	-1
BOMB_UNLIT:	equ	0
BOMB_DISABLED:	equ	-2

LIT_BOMB:	equ	1

TS_BOMBS_STATIC	equ	0
TS_BOMBS_LIT:	equ	1
TS_BOMBS_COLLECT	equ	2

;
; Bomb handler routine
;  
HDL_BOMBS:	moveq	#TS_BOMBS_LIT,d1
		bsr	ANIMATE
		rts


HDL_COLLECT_BOMBS:
		move.l	d0,-(a7)
		moveq	#TS_BOMBS_COLLECT,d1
		bsr	ANIMATE
		move.l	(a7)+,d0
		tst.w	d6
		bmi.s	.disable
		bra.s	.exit
.disable:	move.w	d0,d1			; Disable the sprite
		bsr	DISABLE_SPRITE
; Maintain free list here.
		bsr	FREE_COLLECT_BOMB
.exit:		rts


FIND_BOMB_IN_MAP:
	movem.l	d0-d1/a0-a1,-(a7)
	
	move.w	BJ_XPOS,d0
	move.w	BJ_YPOS,d1
	addq.w	#3,d0

	lsr.w	#3,d0
	lsr.w	#3,d1
	mulu	#PLAYFIELD_SIZE_X,d1

	lea	LEVEL_1_BOMBS(pc),a0
	add.w	d0,a0
	add.w	d1,a0
	
; a0 now pointing at Jack's x and y cordintate now in the map
	moveq	#-1,d0

	add.b	-(PLAYFIELD_SIZE_X)-1(a0),d0	; 1d
	add.b	-(PLAYFIELD_SIZE_X)(a0),d0	; 1c
	add.b	-(PLAYFIELD_SIZE_X)+1(a0),d0	; 1b

	add.b	-1(a0),d0
	add.b	(a0),d0
	add.b	1(a0),d0
	
	add.b	PLAYFIELD_SIZE_X-1(a0),d0
	add.b	PLAYFIELD_SIZE_X(a0),d0
	add.b	(PLAYFIELD_SIZE_X*1)+1(a0),d0

;	add.b	(PLAYFIELD_SIZE_X*2)-1(a0),d0
;	add.b	(PLAYFIELD_SIZE_X*2)(a0),d0
;	add.b	(PLAYFIELD_SIZE_X*2)+1(a0),d0
	move.l	d0,d7
	movem.l	(a7)+,d0-d1/a0-a1
	rts

;
; LIGHT_BOMB
;
; This sets the Bomb sprite animating over the background bomb
; In the bomb table if a bomb is -1 then it is lit, otherwise
; the bomb is the order number in which it must be collected.
;
; In:
; 	d1 = Bomb number to light
;
LIGHT_BOMB:
	move.l	a0,-(a7)
	move.l	a1,-(a7)
	move.l	d1,-(a7)
	moveq	#1,d0
	bsr	GET_SPRITE_POINTER

	lea	BOMB_TABLE(pc),a1
	lsl.w	#3,d1
	add.l	d1,a1
	move.w	#BOMB_LIT,6(a1)		; set bomb attribute to be lit
	move.w	2(a1),TS_SPR16_XPOS(a0)		; set x position
	move.w	4(a1),TS_SPR16_YPOS(a0)		; set y position
.exit:	move.l	(a7)+,d1
	move.l	(a7)+,a1
	move.l	(a7)+,a0
	rts	
	

; d0 = Allocated sprite number to use
; d1 = bomb number to detonate.
DETONATE_BOMB:
	move.l	a0,-(a7)
	move.l	a1,-(a7)
	move.l	d1,-(a7)
	bsr	GET_SPRITE_POINTER

	lea	BOMB_TABLE(pc),a1
	lsl.w	#3,d1
	add.l	d1,a1
	move.w	2(a1),TS_SPR16_XPOS(a0)		; set x position
	move.w	4(a1),TS_SPR16_YPOS(a0)		; set y position

.exit:	move.l	(a7)+,d1
	move.l	(a7)+,a1
	move.l	(a7)+,a0
	rts	

; d1 = Bomb number
REMOVE_BOMB_SPRITE:
	movem.l	d0-d7/a0-a6,-(a7)
	lea	LSTPTR_POST_SCREEN(pc),a1		; destination
	bsr	RESTORE_BOMB_FROM_PRE_BUFF
	movem.l	(a7)+,a0-a6/d0-d7
.exit:	rts
	
	
; d1 = Sprite number
; a1 = Destination screen list
RESTORE_BOMB_FROM_PRE_BUFF:
	move.l	d1,-(a7)
	bsr	GET_BOMB_XY
	bsr	GET_SPRITE_OFFSETS
	
	lea	LSTPTR_PRE_SCREEN(pc),a0
	moveq	#PLAYFIELD_SIZE_X,d2
	moveq	#PLAYFIELD_BITPLANES-1,d3
	and.l	#$ffff,d0
	and.l	#$ffff,d1
	
.loop:
	move.l	(a0)+,a2 	; read source plane address
	move.l	(a1)+,a3	; read destination plane address
	add.l	d0,a2		; add index into source plane
	add.l	d1,a2		
	add.l	d0,a3		; add index into destination plane
	add.l	d1,a3

; Use the Blitter on this
	move.b	(a2),(a3)	; copy byte
	move.b	1(a2),1(a3)	; copy adjacent byte
	move.b	(PLAYFIELD_SIZE_X*1)(a2),(PLAYFIELD_SIZE_X*1)(a3)
	move.b	(PLAYFIELD_SIZE_X*1)+1(a2),(PLAYFIELD_SIZE_X*1)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*2)(a2),(PLAYFIELD_SIZE_X*2)(a3)
	move.b	(PLAYFIELD_SIZE_X*2)+1(a2),(PLAYFIELD_SIZE_X*2)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*3)(a2),(PLAYFIELD_SIZE_X*3)(a3)
	move.b	(PLAYFIELD_SIZE_X*3)+1(a2),(PLAYFIELD_SIZE_X*3)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*4)(a2),(PLAYFIELD_SIZE_X*4)(a3)
	move.b	(PLAYFIELD_SIZE_X*4)+1(a2),(PLAYFIELD_SIZE_X*4)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*5)(a2),(PLAYFIELD_SIZE_X*5)(a3)
	move.b	(PLAYFIELD_SIZE_X*5)+1(a2),(PLAYFIELD_SIZE_X*5)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*6)(a2),(PLAYFIELD_SIZE_X*6)(a3)
	move.b	(PLAYFIELD_SIZE_X*6)+1(a2),(PLAYFIELD_SIZE_X*6)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*7)(a2),(PLAYFIELD_SIZE_X*7)(a3)
	move.b	(PLAYFIELD_SIZE_X*7)+1(a2),(PLAYFIELD_SIZE_X*7)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*8)(a2),(PLAYFIELD_SIZE_X*8)(a3)
	move.b	(PLAYFIELD_SIZE_X*8)+1(a2),(PLAYFIELD_SIZE_X*8)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*9)(a2),(PLAYFIELD_SIZE_X*9)(a3)
	move.b	(PLAYFIELD_SIZE_X*9)+1(a2),(PLAYFIELD_SIZE_X*9)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*10)(a2),(PLAYFIELD_SIZE_X*10)(a3)
	move.b	(PLAYFIELD_SIZE_X*10)+1(a2),(PLAYFIELD_SIZE_X*10)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*11)(a2),(PLAYFIELD_SIZE_X*11)(a3)
	move.b	(PLAYFIELD_SIZE_X*11)+1(a2),(PLAYFIELD_SIZE_X*11)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*12)(a2),(PLAYFIELD_SIZE_X*12)(a3)
	move.b	(PLAYFIELD_SIZE_X*12)+1(a2),(PLAYFIELD_SIZE_X*12)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*13)(a2),(PLAYFIELD_SIZE_X*13)(a3)
	move.b	(PLAYFIELD_SIZE_X*13)+1(a2),(PLAYFIELD_SIZE_X*13)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*14)(a2),(PLAYFIELD_SIZE_X*14)(a3)
	move.b	(PLAYFIELD_SIZE_X*14)+1(a2),(PLAYFIELD_SIZE_X*14)+1(a3)
	move.b	(PLAYFIELD_SIZE_X*15)(a2),(PLAYFIELD_SIZE_X*15)(a3)
	move.b	(PLAYFIELD_SIZE_X*15)+1(a2),(PLAYFIELD_SIZE_X*15)+1(a3)
	dbf	d3,.loop	; next plane
	move.l	(a7)+,d1
	rts

; d1 = Bomb to remove
REMOVE_BOMB_MASK:
	move.l	a0,-(a7)
	move.l	d0,-(a7)
	move.l	d1,-(a7)
	bsr	GET_BOMB_XY		; d0 and d1 now have x/y positions
	bsr	GET_SPRITE_OFFSETS	; d0 and d1 now has words to add
	lea	SCRPTR_BOMB_COLLISIONS,a0
	add.w	d0,a0
	add.w	d1,a0
	
	moveq	#PLAYFIELD_SIZE_X,d0

	rept	SPR16_SIZE
	clr.b	(a0)
	clr.b	1(a0)
	add.w	d0,a0
	endr	
	move.l	(a7)+,d1
	move.l	(a7)+,d0
	move.l	(a7)+,a0
	rts

;d1 = Bomb number to get
GET_BOMB_XY:
	move.l	a1,-(a7)
	lea	BOMB_TABLE(pc),a1
	lsl.w	#3,d1
	add.l	d1,a1
	move.w	2(a1),d0		; got bomb x pos
	move.w	4(a1),d1		; got bomb y pos
	move.l	(a7)+,a1
	rts



; d1 = Bomb number to remove
; Out:
;	d6 = -1 if collected bomb was lit, 0 otherwise
;
REMOVE_BOMB_FROM_LIST:
	move.l	a1,-(a7)
	move.l	d2,-(a7)
	move.w	d1,d2
	moveq	#0,d6
	lea	BOMB_TABLE(pc),a1
	lsl.w	#3,d1
	add.l	d1,a1
	cmp.w	#BOMB_LIT,6(a1)
	bne.s	.notlit
	moveq	#-1,d6
.notlit:	
	move.w	#BOMB_DISABLED,6(a1)	; Set bomb disabled
	move.l	(a7)+,d2
	move.l	(a7)+,a1
	rts

; d1 = Bomb number to start from
GET_NEXT_BOMB_IN_LIST:
	move.l	d1,-(a7)
	move.l	a1,-(a7)
	addq.w	#1,d1
	cmp.w	#NUM_BOMBS,d1
	bne.s	.next
	moveq	#0,d1
	
.next:	move.w	d1,d7
	
	lea	BOMB_TABLE(pc),a1
	lsl.w	#3,d1
	add.l	d1,a1
	cmp.w	#BOMB_DISABLED,6(a1)
	bne.s	.exit
	move.l	d7,d1
	addq.w	#1,d1
	bra.s	.next
	
.exit:	move.l	(a7)+,a1
	move.l	(a7)+,d1
	rts	
	
	
	

DRAW_BOMBS:
; Bomb sprite is always #1
	moveq	#1,d0			; Sprite 1 is always the Bomb
	bsr	GET_SPRITE_POINTER	

	move.w	(a0),d0	
	move.w	#SPR_BOMB_ASSET,d0
	bsr	GET_SPRITE_MASK_POINTERS ; a2 + a3 has assets and mask

	move.l	a5,a0
	lea	BOMB_TABLE(pc),a1
	moveq	#0,d3
	moveq	#0,d5
	moveq	#PLAYFIELD_SIZE_Y-2,d6

.loopy:	moveq	#PLAYFIELD_SIZE_X-1,d7		; x rows
	moveq	#0,d4
.loopx:	move.b	(a0)+,d3
	cmp.b	#1,d3
	bge.s	.draw
	bra.s	.next

.draw:	move.w	d4,d0
	move.w	d5,d1
	lsl.w	#3,d0			; muliply x by 8
	lsl.w	#3,d1

; order bombs

	subq.w	#1,d3
	move.w	d3,d2
	lsl.w	#3,d3
	move.w	d2,0(a1,d3)
	move.w	d0,2(a1,d3)
	move.w	d1,4(a1,d3)
	move.w	#0,6(a1,d3)
; order bombs

	movem.l	d0-d7/a0-a3,-(a7)
	moveq	#-1,d2
	moveq	#0,d3
	bsr	PLOT_BOMB_ASSET
	movem.l	(a7)+,d0-d7/a0-a3
		
	movem.l	d0-d7/a0-a3,-(a7)
	lea	SCRPTR_BOMB_COLLISIONS,a1
	bsr	PLOT_BOMB_MASK
	movem.l	(a7)+,d0-d7/a0-a3

.next:	addq.w	#1,d4
	dbf	d7,.loopx
	addq.w	#1,d5			; increment x
	dbf	d6,.loopy
	rts	
	
	
; d0 = xposition
; d1 = yposition
; a1 = screen to plot in.
PLOT_BOMB_MASK:
	move.w	d0,d3			; bomb xpos in d0
	and.w	#$f,d3			; bomb ypos in d1
	lsl.w	#8,d3
	lsl.w	#4,d3			; bits to shift needs to be in upper

	bsr	GET_SPRITE_OFFSETS
	add.w	d0,a1			; add X word offset
	add.w	d1,a1			; add Y line offset
	
	lea	CHIPBASE,a6
	bsr	WAIT_FOR_BLITTER		
	
	move.w	d3,d4
	or.w	#$0bfa,d4		; d = (a or c)
	move.w	d4,BLTCON0(a6)
	move.w	d3,BLTCON1(a6)	
	move.w	#$ffff,BLTAFWM(a6)	; Only want the first word
	move.w	#$0,BLTALWM(a6)		; Dump the last word
	move.w	#36,BLTAMOD(a6)

	move.w	#(PLAYFIELD_SIZE_X)-4,BLTCMOD(a6)	
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTDMOD(a6)

	move.l	a3,BLTAPTH(a6)		; Load the mask address
	move.l	a1,BLTCPTH(a6)		; Destination background
	move.l	a1,BLTDPTH(a6)
	move.w	#(SPR16_SIZE*64)+2,BLTSIZE(a6)
	
.exit:	
.rts:	rts

; d0 = bomb to free up
FREE_COLLECT_BOMB:
	move.l	d0,-(a7)
	move.l	a0,-(a7)
	lea	MAX_COLLECT_FREELIST(pc),a0
	subq.w	#2,d0
	lsl.w	#1,d0
	add.w	d0,a0
	clr.w	(a0)
	move.l	(a7)+,a0
	move.l	(a7)+,d0
	rts
	
; Get the next free available bomb sprite
; Returns bomb in d0
GET_NEXT_FREE_COLLECT_BOMB:
	move.l	d1,-(a7)
	move.l	a0,-(a7)
	
	moveq	#MAX_COLLECT_BOMBS-1,d1
	moveq	#2,d0
	lea	MAX_COLLECT_FREELIST(pc),a0
	
.loop:	cmp.w	#0,(a0)
	beq.s	.found
	addq.w	#2,a0
	addq.w	#1,d0
	dbf	d1,.loop
	moveq	#2,d0			; Return 2 as default if all used
	bra.s	.exit
.found:	move.w	#-1,(a0)
.exit:	move.l	(a7)+,a0
	move.l	(a7)+,d1
	rts

; Bomb number, xposition, yposition, lit=$ff, unlit=$0, disabled=$fe
BOMB_TABLE:	ds.l	4*NUM_BOMBS	; 24 bombs

MAX_COLLECT_FREELIST:	ds.w	MAX_COLLECT_BOMBS

NEW_BOMB_TOUCHED:	dc.w	0
OLD_BOMB_TOUCHED:	dc.w	-1
ANY_BOMB_TOUCHED:	dc.w	-1	

BOMB_SPRITES:	dc.l	ANIM_BOMB_VARS		; temp vars for sprite
		dc.l	HDL_BOMBS		; Sprite control handler
		dc.l	ANIM_BOMB_STATIC	; 0 Static Bomb
		dc.l	ANIM_BOMB_LIT		; 1 Bomb is Lit
		dc.l	ANIM_BOMB_COLLECT	; 2 Bomb Collected
		dc.w	-1

ANIM_BOMB_VARS:		dc.w	0,48,48,$8000		
			dc.l	ANIM_BOMB_BUFFER

ANIM_BOMB_BUFFER:	ds.l	16*(SPR16_BITPLANES*2)

ANIM_BOMB_STATIC:	dc.l	ANIM_BOMB_STATIC_VARS
			dc.l	ANIM_BOMB_STATIC_FRAME
			dc.l	ANIM_BOMB_STATIC_SPEED
			
ANIM_BOMB_LIT:		dc.l	ANIM_BOMB_LIT_VARS
			dc.l	ANIM_BOMB_LIT_FRAME
			dc.l	ANIM_BOMB_LIT_SPEED
			
ANIM_BOMB_COLLECT:	dc.l	ANIM_BOMB_COLLECT_VARS
			dc.l	ANIM_BOMB_COLLECT_FRAME
			dc.l	ANIM_BOMB_COLLECT_SPEED

ANIM_BOMB_STATIC_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_BOMB_STATIC_FRAME:	dc.w	38,38,$ffff
ANIM_BOMB_STATIC_SPEED:	dc.w	6	

ANIM_BOMB_LIT_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_BOMB_LIT_FRAME:	dc.w	96,97,$ffff
ANIM_BOMB_LIT_SPEED:	dc.w	3	

ANIM_BOMB_COLLECT_VARS:	dc.w	$0,$0	; index to anim frame, current speed
ANIM_BOMB_COLLECT_FRAME	dc.w	82,81,80,120,120,120,120,120,120,120,120,119,119,$fffe,$ffff
ANIM_BOMB_COLLECT_SPEED	dc.w	4












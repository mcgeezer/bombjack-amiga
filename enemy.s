ENEMY_CYLON_COLOUR:	equ	8
ENEMY_CYLON_SPEED:	equ	2

MAX_ENEMIES:	equ	10
	
; Enemy formation for level 1
; enemy number (word)
; Frame number (word)
; Sprite type (see constants)
; Position (word) ($ff=left position, $0=right position)
; Speed (word)
; Attribute 1 (number of turns for metal man)
; Attribute 2 (Enemy type to transform to)
; 0
; (Max 10) Terminal with -1
; a0=Formation

LOAD_ENEMIES:
	moveq	#MAX_ENEMIES-1,d7
	lea	ENEMY_START_POSITIONS(pc),a1
	
	move.w	FRAME_COUNTER,d3
.loop:	tst.w	(a0)
	bmi.s	.exit
	cmp.w	2(a0),d3		; Do we have a matching frame?
	beq.s	.init_enemy
.loop1:	add.w	#16,a0			; next enemy check at frame
	dbf	d7,.loop
	bra.s	.exit
	
.init_enemy:
	move.w	4(a0),d0		; Sprite type number

	tst.w	BJ_ZONE			; Check what zone bombjack is
	bmi.s	.left			; in and spawn enemy to the opposite
	bra.s	.right			; $fe pos enemy starts on the right
	
.left:	move.w	(a1),d1			; load left start x position
	move.w	2(a1),d2		; load right start y position
	bra.s	.begin

.right:	move.w	4(a1),d1		; load right start x position
	move.	6(a1),d2		; load right start y position
	bra.s	.begin
	nop
.begin:	
	tst.w	(a0)			; Only the first enemy will
	bne.s	.not_mummy		; load the number of turns for mummy.
	move.w	10(a0),MUMMY_TURNS
	
.not_mummy:
	move.w	#SPR_TYPE_ENEMY,d3
	move.l	a0,-(a7)
	move.l	a1,-(a7)
	move.l	d7,-(a7)
	lea	HDL_MUMMY,a0		; Handler for metal man.
	bsr	PUSH_SPRITE
	move.l	(a7)+,d7
	move.l	(a7)+,a1
	move.l	(a7)+,a0
;	bra.s	.loop1
.exit:	rts



; d2=Limit to these sprite types (i.e enemies)
; d3=Set sprite type to this
; a2=Handler address.
CHANGE_ENEMIES:
	moveq	#SPR_TYPE_ENEMY,d2
	moveq	#SPR_TYPE_SMILEY,d3
	move.l	#HDL_SMILEY,a2
	
	moveq	#0,d0
	moveq	#0,d1
	moveq	#MAX_SPRITES-1,d7
	lea	SPRITE_ATTRIBUTES_BUFFER,a6
	
	move.w	d0,d1

.loop:	move.w	d1,d0
	and.l	#$ffff,d0
	lea	SPR16_SLOTS(pc),a0
	lsl.w	#2,d0
	move.l	(a0,d0),a0
	move.l	(a0),a1

	tst.w	(a1)			; Skip if the sprite is disabled
	bmi.s	.next
	cmp.w	6(a1),d2			; Only set these sprite types
	bne.s	.next

; Get the attributes for the sprite number


; Need to set these from the saved enemy sprites.

;	move.l	#ANIM_SMILEY_ACTIVE_VARS,(a0)		; Set VARS Pointer
	move.l	a2,4(a0)			; Sprite Handler

	move.l	#ANIM_SMILEY_ACTIVE,8(a0)	; Set Frames Pointer

	move.w	d3,6(a1)		; Sprite Type

.next:	addq.w	#1,d1
	add.l	#16,a6			; next sprite
	dbf	d7,.loop
	rts

; 
; CYLON
; 
; Simple Red colour cycler for the enemies
;
ENEMY_CYLON:	
	lea	PTR_ENEMY_CYLON,a0
.go:	lea	PAL_ENEMY_CYLON,a1
	move.w	(a0),d0
	
	moveq	#ENEMY_CYLON_SPEED,d1
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
	add.l	#ENEMY_CYLON_COLOUR*4,a2
	move.w	(a1),(a2)
	addq.w	#1,(a0)
	
	lea	COPPER+2,a2		; Colour 8
	add.l	COPPTR_MULTIPLIER_COL,a2

	lea	RAINBOW_CYCLE(pc),a3
	cmp.w	#$fff,(a3)
	blt.s	.rainbow
	clr.w	(a3)
	
.rainbow:
	lea	RAINBOW_CYCLE_SPEED(pc),a4
	addq.w	#1,(a4)
	move.w	(a4),d4
	and.w	#1,d4
	add.w	d4,(a3)
	move.w	(a3),(a2)
	rts

PTR_ENEMY_CYLON:	dc.w	0
PAL_ENEMY_CYLON:	dc.w	$500,$600,$700,$800,$900,$a00,$b00,$c00,$d00,$e00
			dc.w	$e00,$d00,$c00,$b00,$a00,$900,$800,$700,$600,$ffff







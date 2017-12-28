MAX_SPRITES:	equ	21

SPRITE_ASSETS_SIZE_X:	equ	40
SPRITE_ASSETS_SIZE_Y:	equ	10
SPR16_SIZE:		equ	16
SPR16_BITPLANES:	equ	5

SCRPTR_PRE_SPRITES:	equ	$70000+MEMOFF	; Pre Sprites Buffer
SCRPTR_POST_SPRITES:	equ	$60000+MEMOFF	; Post Sprites Buffer

; This is shite.
SPRPTR_ASSETS16_BASE:	equ	$20000+MEMOFF	; $68000 
SPRPTR_ASSETS16_BP1:	equ	SPRPTR_ASSETS16_BASE
SPRPTR_ASSETS16_BP2:	equ	SPRPTR_ASSETS16_BASE+$2000
SPRPTR_ASSETS16_BP3:	equ	SPRPTR_ASSETS16_BASE+$4000
SPRPTR_ASSETS16_BP4:	equ	SPRPTR_ASSETS16_BASE+$6000
SPRPTR_ASSETS16_BP5:	equ	SPRPTR_ASSETS16_BASE+$8000

SPRPTR_STRUCTURES:	equ	$78000+MEMOFF	; Dynamic Sprite list
SPRPTR_MASKS16:		equ	$58000+MEMOFF	; Address of sprite masks

; Pointer Offset
ANIM_DATASIZE:	equ	512		; whole size of a sprite data structure
ANIM_POINTERS:	equ	256		; div by 4 for max onscreen sprites
ANIM_COORDS:	equ	16
ANIM_SET:	equ	12		; animation pointers
ANIM_TEMP:	equ	4		; temp variables for sprite
ANIM_SPEED:	equ	2		;
ANIM_FRAME:	equ	32		; max 16 frames per anim set
ANIM_SET_SZ:	equ	(ANIM_SET+ANIM_TEMP+ANIM_SPEED+ANIM_FRAME)

TS_SPR16_STANDING	equ	0
TS_SPR16_WALKLEFT	equ	1
TS_SPR16_WALKRIGHT	equ	2
TS_SPR16_FALLING	equ	3
TS_SPR16_JUMPING	equ	4
TS_SPR16_FLYLEFT	equ	5
TS_SPR16_FLYRIGHT	equ	6
TS_SPR16_FALLLEFT	equ	7
TS_SPR16_FALLRIGHT	equ	8

TS_SPR16_ANIM:	equ	0	; current animation
TS_SPR16_XPOS:	equ	2	; Sprite screen x position
TS_SPR16_YPOS:	equ	4	; Sprite screen y position
TS_SPR16_CTL1:	equ	6	; Sprite control word
TS_SPR16_BUFFPTR:	equ	8	; Sprite copy buffer address
TS_SPR16_BUFFPTR_OLD:	equ	12	; Old Sprite buff pointer
				
; These are sprite definitions.[anim index]
; Max 32 anim types - 32x4 = 128 bytes

MAX_SPR16_ANIMS:	equ	5

;
; INIT_SPRITES		 
;
; This section simply builds up a sprite list from a table
; calls push sprite.
;
INIT_SPRITES:
	lea	SPR16_ATTR(pc),a1
	move.w	#-1,SPRITE_COUNT

.loop:	cmp.w	#MAX_SPRITES-1,SPRITE_COUNT
	beq.s	.done
	cmp.w	#-1,(a1)
	beq	.done
	move.w	(a1)+,d0		; sprite number
	move.w	(a1)+,d1		; xposition
	move.w	(a1)+,d2		; yposition
	move.w	(a1)+,d3		; control
	cmp.w	#SPR_TYPE_BOMB,d3
	bne.s	.nobomb
	addq.w	#3,d3
	
.nobomb:	move.l	(a1)+,a0
	move.l	a1,-(a7)
	bsr	PUSH_SPRITE
	move.l	(a7)+,a1
	bra.s	.loop	
.done:	rts


	
;
; SAVE_ALL_SPRITES
;
; Routine which simply saves the screen location
; of each sprite to a list so that it can be restored later.
; 	
SAVE_ALL_SPRITES:
	move.w	SPRITE_COUNT(pc),d7
	cmp.w	#MAX_SPRITES,d7
	ble.s	.skip
	moveq	#MAX_SPRITES,d7
.skip:	moveq	#0,d0
.loop:	move.l	d0,-(a7)
	bsr	SAVE_SPRITE_BACKGROUND
	move.l	(a7)+,d0
	addq.w	#1,d0
	dbf	d7,.loop
	rts

;
; PLOT_ALL_SPRITES
;
; Subroutine responsible for displaying all sprites on screen.
;
PLOT_ALL_SPRITES:
	move.w	SPRITE_COUNT(pc),d7
	cmp.w	#MAX_SPRITES,d7
	ble.s	.skip
	moveq	#MAX_SPRITES,d7
	
	moveq	#0,d1

.skip:	moveq	#0,d0
.loop:	move.l	d0,-(a7)
	move.l	d1,-(a7)
	move.l	d7,-(a7)
	bsr	PLOT_SPRITE_ASSET
	move.l	(a7)+,d7
	move.l	(a7)+,d1
	move.l	(a7)+,d0
	
	move.l	d0,-(a7)
	move.l	d1,-(a7)
	move.l	d7,-(a7)
	moveq	#1,d6			; This is a bomb mask
	bsr	PLOT_SPRITE_MASK
	move.l	(a7)+,d7
	move.l	(a7)+,d1
	move.l	(a7)+,d0
	
	addq.w	#1,d0
	dbf	d7,.loop
	rts

;
; RESTORE_ALL_SPRITES
; 
; Restore sprite routine that removes all sprites from screen and
; restores their background from the pre/post buffer.
;	
RESTORE_ALL_SPRITES:
	move.w	SPRITE_COUNT(pc),d7
	cmp.w	#MAX_SPRITES,d7
	ble.s	.skip
	moveq	#MAX_SPRITES,d7
.skip:
	moveq	#0,d0
.loop:	move.l	d0,-(a7)
	move.l	d7,-(a7)
	bsr	REST_SPRITE_BACKGROUND
	move.l	(a7)+,d7
	move.l	(a7)+,d0
	addq.w	#1,d0
	dbf	d7,.loop
	
	bsr	RESTORE_MASKS
	rts

;
; RESTORE_MASKS
;
; This routine simply clears a block of memory around Bomb Jack
; in the mask screens.
;
RESTORE_MASKS:
	move.w	BJ_XPOS,d0
	move.w	BJ_YPOS,d1
	sub.w	#16,d0
	sub.w	#16,d1
.check_x_boundary:
	tst.w	d0
	bpl.s	.check_y_boundary
	clr.w	d0
.check_y_boundary
	tst.w	d1
	bpl.s	.cont1
	clr.w	d1
	
.cont1:	bsr	GET_SPRITE_OFFSETS

	
	moveq	#PLAYFIELD_SIZE_X-10,d3		; modulo for 48 pixels (3 words)
	move.w	#64,d2			; 48 lines			
	lsl.w	#6,d2
	add.w	#5,d2			; 5 words (80x64)

	lea	SCRPTR_POWER_COLLISIONS,a0
	add.w	d1,a0
	add.w	d0,a0

; a0=destination
	bsr	WAIT_FOR_BLITTER
		
	move.l	#$0b500000,BLTCON0(a6)	; Select A,C,D not D=A NOT C
	move.w	#$ffff,BLTAFWM(a6)  ; Don't send any bits
	move.w	#$ffff,BLTALWM(a6)
	move.w	d3,BLTAMOD(a6)		; set source modulo
	move.w	d3,BLTCMOD(a6)
	move.w	d3,BLTDMOD(a6)		; set dest modulo
	move.l	a0,BLTAPTH(a6)		; Source Address in A
	move.l	a0,BLTCPTH(a6)		; Source Address in C
	move.l	a0,BLTDPTH(a6)		; Copying to the same region
	move.w	d2,BLTSIZE(a6)	; boom.....
	
	lea	SCRPTR_ENEMY_COLLISIONS,a0
	add.w	d1,a0
	add.w	d0,a0

; a0=destination
	bsr	WAIT_FOR_BLITTER
		
	move.l	a0,BLTAPTH(a6)		; Source Address in A
	move.l	a0,BLTCPTH(a6)		; Source Address in C
	move.l	a0,BLTDPTH(a6)		; Copying to the same region
	move.w	d2,BLTSIZE(a6)	; boom.....

	bsr	WAIT_FOR_BLITTER

	lea	SCRPTR_ESB_COLLISIONS,a0
	add.w	d1,a0
	add.w	d0,a0

; a0=destination
	bsr	WAIT_FOR_BLITTER
		
	move.l	a0,BLTAPTH(a6)		; Source Address in A
	move.l	a0,BLTCPTH(a6)		; Source Address in C
	move.l	a0,BLTDPTH(a6)		; Copying to the same region
	move.w	d2,BLTSIZE(a6)	; boom.....
	rts


;
; LOAD_SPRITE16_ASSETS
; 
; Copies 16x16 sprite assets from IFF file and generate required masks
; and pointers.
; Routine needs improvement as it is shit.
;
; In:
; 	a0 = Pointer to uncompressed .IFF file
;	a6 = Pointer to palette buffer
;	
LOAD_SPRITE16_ASSETS:
	cmp.l	#"FORM",(a0)	; compare header
	bne	.return
	move.l	4(a0),d7	; size of entire FORM block
	addq.l	#8,a0
	
	cmp.l	#"ILBM",(a0)	; Format should be ILBM
	bne	.return
	addq.l	#4,a0
	
	cmp.l	#"BMHD",(a0)	; Bitmap Header
	bne	.return
	move.l	4(a0),d6	
				; read in bitmap header here
	addq.l	#8,a0
	
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	move.l	(a0),d4		; Get image sizes
	move.w	8(a0),d3	; Get number of planes
	lsr.w	#8,d3		; d1 now has number of planes
	subq.w	#1,d3
	
	move.w	d4,d5		; Y size of image
	subq.w	#1,d5
	swap	d4
	and.l	#$ffff,d4
	lsr.l	#4,d4		; divide x pixels by 16 to get words
				; d4 has number of words wide.
				; d5 has y lines
	
	add.l	d6,a0		; next chunk
	
	cmp.l	#"CMAP",(a0)
	bne	.return
	move.l	4(a0),d6	; next chunk
	addq.l	#8,a0
				; handle pallete here.

	divu.w	#3,d6		; divide by 3 colours each
	subq.w	#1,d6

	moveq	#0,d0
	moveq	#0,d1
	
.cmap	move.b	(a0)+,d0
	lsr.b	#4,d0
	move.b	d0,d1
	move.b	(a0)+,d0
	lsr.b	#4,d0
	lsl.w	#4,d1
	or.b	d0,d1
	move.b	(a0)+,d0
	lsr.w	#4,d0
	lsl.w	#4,d1
	or.w	d0,d1
	move.w	d1,(a6)+	; store pallete
	dbf	d6,.cmap

.findcamg:
	cmp.l	#"CAMG",(a0)
	beq.s	.foundcamg
	addq.l	#2,a0
	bra.s	.findcamg
	
.foundcamg:
	move.l	4(a0),d6
	addq.l	#8,a0
	
	add.l	d6,a0		;next chunk

	cmp.l	#"DPI ",(a0)
	bne.s	.return
	move.l	4(a0),d6
	addq.l	#8,a0
	add.l	d6,a0
		
	
	cmp.l	#"BODY",(a0)
	bne.s	.return
	move.l	4(a0),d6	; get size of body chunk
	addq.l	#8,a0

				; d4 has words wide
				; d5 has lines to copy
	
	move.w	d3,d0		; save number of planes
	moveq	#0,d6
.copy:	move.w	d6,d1
	lea	LSTPTR_CURRENT_SCREEN,a2
	lea	SPR16_ASSETS,a3
	
; next line
	mulu	d4,d1
	lsl.w	#1,d1
	move.w	d0,d3		; set number of planes

.copybp:
	lea 	SPRPTR_MASKS16,a4
	move.l	(a2)+,a1	; move in screen address
	move.l	(a3)+,a5	; a5 has assets sprite plane
	
	add.l	d1,a1
	add.l	d1,a4
	add.l	d1,a5
	
	move.l	d4,d2
	subq.l	#1,d2

.lp:	move.w	(a0)+,d7	; copy in word from sprite
;	move.w	d7,(a1)+	; copy word to screen plane <DISPLAY_BG>
	move.w	d7,(a5)+	; copy word to sprite asset
	or.w	d7,(a4)+	; create inverted mask
	dbf	d2,.lp
	dbf	d3,.copybp
	
	addq.l	#1,d6		; next line
	dbf 	d5,.copy

.return:
	rts


;
; GET_SPRITE_POINTER
;
; Returns sprite attributes for a given sprite number
; d0 = sprite to point to
; a0 = returns sprite ptr structure
;
GET_SPRITE_POINTER:
	lea	SPR16_SLOTS(pc),a0	; Sprites base pointer
	lsl.l	#2,d0			; Current sprite * 4 for lwords
	add.l	d0,a0			; Index a0 to correct sprite
	move.l	(a0),a0			; a0 now points to this sprite data
	move.l	(a0)+,a0	
	rts
	
;
; GET_SPRITE_OFFSETS
;
; Returns the word offset within bitplane of where to plot a sprite
; In:
; 	d0 = Sprite X Position
; 	d1 = Sprite Y Position
; Out:
; 	d0 = X bytes offset
; 	d1 = Y bytes offset
;
GET_SPRITE_OFFSETS:
	lea	TAB_Y(pc),a4		; load y table positions
	lsl.w	#1,d1			; Dealing with words
	move.w	(a4,d1.w),d1		; Get offset y line in bitplane
	lsr.w	#3,d0
	rts

;
; GET_SPRITE_MASK_POINTERS
;
; Returns pointers to sprite assets
;
; In:
; 	d0 = Sprite number to get
;
; Out:
; 	a2 = Pointer to sprite asset address
; 	a3 = Pointer to sprite mask address	
;
GET_SPRITE_MASK_POINTERS:
	lea	SPR16_AM_PTR,a0		; pointer to sprite addresses 
					; and mask addresses
	lsl.l	#3,d0			; multiply by 8 (2 long words)
					; 1 long for sprite asset in chip
					; 1 long for sprite mask in chip
	add.l	d0,a0
	move.l	(a0)+,a2		; a2 has Sprite address
	move.l	(a0)+,a3		; a3 has Mask Address
	rts


;	
; SAVE_SPRITE_BACKGROUND
;
; Save pointer to sprite background, for a sprite
;
; In:
; 	d0 = Sprite number to save
;
SAVE_SPRITE_BACKGROUND:
	bsr	GET_SPRITE_POINTER
	tst.w	(a0)
	bmi.s	.exit
	move.w	TS_SPR16_XPOS(a0),d0	; d0 now has pos x 
	move.w	TS_SPR16_YPOS(a0),d1	; d1 now has pos y
	move.w	TS_SPR16_CTL1(a0),d3	; Get control word
	move.l	TS_SPR16_BUFFPTR(a0),a1	; Restore buffer from here
	
	move.l	a1,TS_SPR16_BUFFPTR_OLD(a0)	; save this pointer
	moveq	#SPR16_SIZE-1,d2		; Sprite 16x16

	bsr	GET_SPRITE_OFFSETS

	moveq	#0,d3
	add.w	d1,d3			; offset into plane 1
	add.w	d0,d3			; a2 now points to restore word.
	
	move.l	d3,TS_SPR16_BUFFPTR(a0)	; Store the screen pointer
.exit	rts


;
; REST_SPRITE_BACKGROUND
;
; Restore background from pre/post buffer over currently displayed sprite	
; In:
; 	d0 = Sprite number to restore	
;
REST_SPRITE_BACKGROUND:
	bsr	GET_SPRITE_POINTER
	tst.w	(a0)
	bmi.s	.exit

	move.w	TS_SPR16_CTL1(a0),d3	; Get control word
	move.l	TS_SPR16_BUFFPTR_OLD(a0),d0	; Restore buffer offset

	cmp.w	#SPR_TYPE_BOMB,d3	; don't restore if it's a bomb
	beq.s	.exit

	moveq	#SPR16_BITPLANES-1,d7		; Number of blits
	moveq	#(PLAYFIELD_SIZE_X)-4,d1

	lea	LSTPTR_POST_SCREEN,a2
	lea	LSTPTR_CURRENT_SCREEN,a0
	lea	CHIPBASE,a6

	bsr	WAIT_FOR_BLITTER
	move.l	#$09f00000,BLTCON0(a6)	; Select straigt A-D mode $f0
	move.l	#$ffffffff,BLTAFWM(a6)  ; No masking needed
	move.w	d1,BLTAMOD(a6)		; set source modulo
	move.w	d1,BLTDMOD(a6)		; set dest modulo

.loopb:	move.l	(a0)+,a1		; next bitplane for dest
	move.l	(a2)+,a3		; next bitplane for src in tbuff
	add.w	d0,a1			; a1 = dest
	add.w	d0,a3			; a3 = src
	bsr	WAIT_FOR_BLITTER			

	move.l	a3,BLTAPTH(a6)		; set source address
	move.l	a1,BLTDPTH(a6)		; set dest address
	move.w	#(SPR16_SIZE*64)+2,BLTSIZE(a6)	; boom.....
	dbf	d7,.loopb		; repeat for each plane.
.exit:	rts


;
; PLOT_SPRITE_MASK
;
; Plot sprite mask used for collision detection.
; Only need to plot masks if they are near (within 16 pixels) to Bombjack.
;
; In:
; 	a1 = Address of screen to send mask to (needs improvement)
; 	d0 = Sprite number to check
; 	d4 = xpos of bombjack (typically)
; 	d5 = ypos of bombjack (typically)
;	d6 = -1 if a bomb mask, 0 if an enemy mask
;
PLOT_SPRITE_MASK:
	
	move.l	d0,-(a7)
	move.l	d1,-(a7)
	move.l	a1,-(a7)
	
	move.w	d0,d7
	
; Get the sprite mask addresses first
	bsr	GET_SPRITE_POINTER	; a0 now has sprite pointer
	tst.w	(a0)			; is Sprite disabled?
	bmi	.exit
	
	move.w	d7,d0

	cmp.w	#(MAX_COLLECT_BOMBS+2),d0
	blt	.exit

	move.l	a0,a6
	
	move.w	(a0),d0			; current sprite number 
	bsr	GET_SPRITE_MASK_POINTERS ; a2=sprite asset, a3=mask offset
	
; Now get sprite attributes
	move.w	d7,d0
	move.l	a6,a0

	move.w	d4,d0			; Arbitrary 
	move.w	d5,d1			

	move.w	d0,d3
	and.w	#$f,d3
	bsr	GET_SPRITE_OFFSETS

; make sure it is an enemy.

	move.w	TS_SPR16_CTL1(a0),d3	; Get control word
	cmp.w	#SPR_TYPE_BOMBJACK,d3	; this is bombjack sprite
	beq	.exit			; so don't plot it.

	bsr	GET_COLLISION_SCREEN

	move.w	TS_SPR16_XPOS(a0),d0	; d0 now has xpos 
	move.w	TS_SPR16_YPOS(a0),d1	; d1 now has ypos 
	bsr	PLOT_CHECK_WINDOW	; see if sprite is in window
	tst.w	d4
	bpl.s	.exit			; not in window so skip.

	move.w	TS_SPR16_XPOS(a0),d0	; d0 now has xpos 
	move.w	TS_SPR16_YPOS(a0),d1	; d1 now has ypos

	move.w	d0,d3			; bomb xpos in d0
	and.w	#$f,d3			; bomb ypos in d1
	lsl.w	#8,d3
	lsl.w	#4,d3			; bits to shift needs to be in upper

	bsr	GET_SPRITE_OFFSETS

; a2=Sprite address (4 SPR16_BITPLANES)
; a3=Mask address plane
; d0=X offset words to add per plane
; d1=Y Offset to add per plane
; d3=Number of bits to rotate.
; d4=Words per plane wide

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
	
.exit:	move.l	(a7)+,a1
	move.l	(a7)+,d1
	move.l	(a7)+,d0
.rts:	rts
	
	
;
; PLOT_SPRITE_ASSET
;
; Draw 16x16 sprite routine using blitter cookie cutter
;
; In:
; 	d0 = Sprite number to draw
;	d2 = -1 to write to post buffer too.
;
PLOT_SPRITE_ASSET:
	bsr	GET_SPRITE_POINTER	; a0 now has sprite pointer
	tst.w	(a0)			; Skip if the sprite is disabled.
	bpl	.next
	rts

.next:
	move.l	a0,a6
	move.w	(a0),d0			; current sprite number 
	bsr	GET_SPRITE_MASK_POINTERS ; a2=sprite asset, a3=mask offset
	move.l	a6,a0

	move.w	TS_SPR16_XPOS(a0),d0	; d0 now has xpos 
	move.w	TS_SPR16_YPOS(a0),d1	; d1 now has ypos 
	move.w	TS_SPR16_CTL1(a0),d3	; Get control word

	moveq	#0,d2

; A little bit cheeky this but use this routing to draw each bomb as well
; fix later
PLOT_BOMB_ASSET:
; here we have to update the post buffer too
	move.w	d0,d3			; adjust for barrel shifter
	and.w	#$f,d3
	lsl.w	#8,d3
	lsl.w	#4,d3
	bsr	GET_SPRITE_OFFSETS
	
; a2=Sprite address (4 SPR16_BITPLANES)
; a3=Mask address plane
; d0=X offset words to add per plane
; d1=Y Offset to add per plane
; d3=Number of bits to rotate.
; d4=Words per plane wide

	lea	LSTPTR_CURRENT_SCREEN,a0	; List of current bitplane pointers
	move.l	a2,a5			; a2 will be changed
	
	lea	CHIPBASE,a6
	bsr	WAIT_FOR_BLITTER
	move.w	d3,d4
	or.w	#$0fca,d4		; We need Cookie Cutter for this.
	move.w	d4,BLTCON0(a6)
	move.w	d3,BLTCON1(a6)	
	move.w	#$ffff,BLTAFWM(a6)	; Only want the first word
	move.w	#$0,BLTALWM(a6)		; Dump the last word
	move.w	#36,BLTAMOD(a6)
	move.w	#36,BLTBMOD(a6)
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTCMOD(a6)	
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTDMOD(a6)

	rept	SPR16_BITPLANES
	move.l	(a0)+,a1		; get next bitplane 1
	add.w	d0,a1			; add X word offset
	add.w	d1,a1			; add Y line offset
	bsr	WAIT_FOR_BLITTER
	move.l	a3,BLTAPTH(a6)		; Load the mask address
	move.l	a2,BLTBPTH(a6)		; Sprite address
	move.l	a1,BLTCPTH(a6)		; Destination background
	move.l	a1,BLTDPTH(a6)
	move.w	#(SPR16_SIZE*64)+2,BLTSIZE(a6)  ; 16*64 + 2
	add.l	#$2000,a2		; next plane - crap code.
	endr

;; this routine writes the sprite also to the third buffer
;; Used to draw static sprites in first couple of frames.
;; if d2 is set to -1.
	tst.w	d2
	bpl	.exit
	
	lea	LSTPTR_POST_SCREEN,a0		; List of current bitplane pointers
	move.l	a5,a2			; a2 was changed due to shit code.

	rept	SPR16_BITPLANES
	move.l	(a0)+,a1		; get next bitplane 1
	add.w	d0,a1			; add X word offset
	add.w	d1,a1			; add Y line offset
	bsr	WAIT_FOR_BLITTER	
	move.l	a3,BLTAPTH(a6)		; Load the mask address
	move.l	a2,BLTBPTH(a6)		; Sprite address
	move.l	a1,BLTCPTH(a6)		; Destination background
	move.l	a1,BLTDPTH(a6)
	move.w	#(SPR16_SIZE*64)+2,BLTSIZE(a6)
	add.l	#$2000,a2		; next plane - crap code.
	endr
.exit:	rts


INIT_SPRITE_FREE_LIST:
	lea	SPRITE_FREE_LIST,a0
	moveq	#MAX_SPRITES-1,d7
.loop:	move.w	#-1,(a0)+
	dbf	d7,.loop
	rts

; d0 = sprite to index to
GET_SPRITE_INDEX:
	and.l	#$ffff,d0
	lea	SPR16_SLOTS(pc),a0
	lsl.w	#2,d0
	move.l	(a0,d0),a0
	move.l	(a0),a0
	rts

; d0 = sprite number
ENABLE_SPRITE:
	move.l	d0,-(a7)
	move.l	a0,-(a7)
	bsr	GET_SPRITE_INDEX	
	clr.b	(a0)
	move.l	(a7)+,a0
	move.l	(a7)+,d0
	rts

; d0 = sprite number
DISABLE_SPRITE:
	move.l	d0,-(a7)
	move.l	a0,-(a7)
	bsr	GET_SPRITE_INDEX	
	move.b	#-1,(a0)
	move.l	(a7)+,a0
	move.l	(a7)+,d0
	rts

;d0 = Sprite number
;a6 = Address of handler	
SET_SPRITE_HANDLER:
	and.l	#$ffff,d0
	lea	SPR16_SLOTS(pc),a0
	lsl.w	#2,d0
	move.l	(a0,d0),a0
	move.l	a6,4(a0)
	rts
	


SAVE_SPRITE_ATTRIBS:
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
	move.l	4(a0),10(a6)		; Sprite Handler
	
	move.l	(a0),a0

	move.w	d1,(a6)			; Sprite number
	move.w	(a0),2(a6)		; Sprite Status
	move.w	2(a0),4(a6)		; XPOS
	move.w	4(a0),6(a6)		; YPOS
	move.w	6(a0),8(a6)		; Sprite Type

	addq.w	#1,d1
	add.l	#16,a6			; next sprite
	dbf	d7,.loop
	rts
	
RESTORE_SPRITE_ATTRIBS:
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
	move.l	10(a6),4(a0)		; Sprite Handler
	
	move.l	(a0),a0

	move.w	2(a6),(a0)		; Sprite Status
	move.w	4(a6),2(a0)		; XPOS
	move.w	6(a6),4(a0)		; YPOS
	move.w	8(a6),6(a0)		; Sprite Type

	addq.w	#1,d1
	add.l	#16,a6			; next sprite
	dbf	d7,.loop
	rts


;
; INIT_SPR16_POINTERS
;
; This routine creates a list of pointers to each 16x16 sprite
; including the sprite mask.  The list is stored at SPR16_POINTERS.
;
; The list is: 
;	[long Sprite Asset Offset Pointer], 
;	[long Sprite Mask Offset Pointer
;
INIT_SPR16_POINTERS:
	lea	SPR16_AM_PTR(pc),a1	
;	lea	SPRPTR_MASKS16,a2		; Sprite mask pointer
;	lea	END,a3
	
	moveq	#SPRITE_ASSETS_SIZE_X/2,d5		; number of sprites in row
	lsl.w	#1,d5			; for 320px this would now be 40
	move.l	d5,d3
	mulu	#SPR16_SIZE,d3		; Bitplane size	(d3=bitplane size)

; d3 now is row size
	mulu	#(SPR16_BITPLANES*SPR16_SIZE),d5	; size to add per row
	moveq	#0,d2
	moveq	#0,d4
	moveq	#SPRITE_ASSETS_SIZE_Y-1,d6	; number of spr16 rows to import
.lp2:
	move.l	SPR16_ASSETS,a0
	lea	SPRPTR_MASKS16,a2
	move.w	#20-1,d7		; Number of sprites in row
	add.l	d2,a0
	add.l	d2,a2
.lp1:
	move.l	a0,(a1)+		; store sprite location
	move.l	a2,(a1)+		; store mask location
	addq.l	#2,a0
	addq.l	#2,a2			; mask
	dbf	d7,.lp1
	add.l	d5,d4			; next row in sprite assets.
	add.l	d3,d2
	dbf	d6,.lp2
	rts

;
; ANIMATE_SPRITES
;	
; Animate all currently pushed sprites that are in the list
;
; This routine calls all of the sprite handlers which in turn
; calls the ANIMATE routine for each sprite.	
;
ANIMATE_SPRITES:
	move.w	SPRITE_COUNT(pc),d7
	cmp.w	#MAX_SPRITES,d7
	ble.s	.skip
	moveq	#MAX_SPRITES,d7
.skip:
	moveq	#0,d0
	
.loop:	move.l	d0,d1
	lsl.l	#2,d1
		
	lea	SPR16_SLOTS,a0
	add.l	d1,a0
	move.l	(a0),a0

	move.l	(a0),a1		; Sprite variables
	move.l	4(a0),a2	; Sprite handler (*** SHOULD LOOK UP 
				; THE SPRITE INDEX AND GET THE HANDLER)

	tst.w	(a1)
	bmi.s	.sprite_disabled
	
	move.l	d0,-(a7)
	move.l	d7,-(a7)
	jsr	(a2)		; Do the sprite handler
	move.l	(a7)+,d7
	move.l	(a7)+,d0

.sprite_disabled:	
	addq.w	#1,d0
	dbf	d7,.loop
	rts

;
; ANIMATE
;
; The sprite handler is called with the sprite to work on in d0
; Then ANIMATE is called from the handler with the animate type in d1
;
; In
; 	d0 = sprite number animate in sprite list (player 1 is 0)
; 	d1 = Type of animation ie. (0 standing, 1 walk left, 2 walk right)
; Out:
;	d6 = -1 = End of sprite loop
;
ANIMATE:	lsl.l	#2,d0			; select sprite
		lsl.l	#2,d1
		moveq	#0,d6

		lea 	SPR16_SLOTS(PC),a0
		add.l	d0,a0
		move.l	(a0),a0
		
		move.l	(a0)+,a4		; a4 now points to spr #
		tst.w	(a4)			; If sprite is not active
		bmi.s	.exit			; then just exit.
		move.l	(a0)+,a5		; a5 now has sprite handler
						; address.
		add.l	d1,a0

		move.l	(a0),a0			; Get the sprite pointer

		move.l	(a0),a1			; work pointer
		move.l	4(a0),a2		; frame index pointer
		move.l	8(a0),a3		; Speed pointer
		
		move.w	(a1),d1			; frame index
		move.w	2(a1),d2		; current speed at
		
		lsl.w	#1,d1
		add.w	d1,a2
		
		move.w	(a2),(a4)		

; need to compare $fffe here for play sprite once.
; if true then we need to disable and pop the sprite from the list.


; Are we at the end of the loop?
		cmp.w	#-1,2(a2)		; end of frame index
		bne.s	.cont
; Yes we are, reset loop counter back to zero.
		clr.w	(a1)			; reset from start		

; Has the speed reached the set speed?
.cont:		cmp.w	(a3),d2			; speed reached?  next frame
		bne.s	.next_frame
		clr.w	2(a1)
		addq.w	#1,(a1)			; SPEED
		
.next_frame:	cmp.w	#-2,2(a2)
		bne.s	.loopdone
		moveq	#-1,d6
		clr.w	(a1)			; reset frame index

.loopdone:	addq.w	#1,2(a1)
		
.exit		rts
	
;
; PUSH_SPRITE
; 
; Adds a sprite in the sprite list
;
; In:
; 	d0 = Sprite type (0, bombjack, 1=MUMMY
; 	d1 = start xpos
; 	d2 = start ypos
; 	d3 = sprite control word to set
; 	a0 = address of handler to assign
;
PUSH_SPRITE:
 	lea	SPR16_SLOTS,a2    	; Pointer to sprite list
	lea	SPRITE_FREE_LIST(pc),a1
	moveq	#0,d4
.spr1:	cmp.w	#-1,(a1)		; Find next spare sprite
	beq	.spare			; In free list.
	addq.w	#1,d4
	addq.w	#2,a1
	bra.s	.spr1
	
.spare:
	move.w	d0,(a1)
	lea	SPRITE_COUNT(pc),a1	; Get current sprite counter
	move.w	d4,(a1)
;	addq.w	#1,(a1)    		; add one to it
;	move.w	(a1),d4    
	
	lea	SPRPTR_STRUCTURES,a3		; Get start of sprite list structure
	move.w	d4,d5			; 
	mulu	#ANIM_DATASIZE,d5    	; d5 = Index to sprite slot 
	lsl.w	#2,d4    		; 
	add.l	d4,a2    		; a2 = Sprite slot pointer now
	add.w	d5,a3 			; a3 now points to sprite structure 
					; in chip ram
	move.l	a3,(a2)			; copy base location to Sprite list

	move.l	a3,d6			; save a3
	add.l	#ANIM_POINTERS,d6    	; Anim pointers list size (max 32)
	move.l	d6,(a3)    		; Store pointer for Sprite Coords
					; section.
	move.l	d6,a4		
	clr.w	(a4)    		; Initialize Sprite number (unused)
	
	move.w	d1,2(a4)    		; Store x pos
	move.w	d2,4(a4)    		; Store y pos
	move.w	d3,6(a4)    		; Store control word 1
	move.l	a0,4(a3)		; Store sprite handler address

	add.l	#8,a3			; Index to buffer pointers
	
; Thats all about we can do with the destination data now
; we now have to get the rest from the specific sprite configuration.
	
	add.l	#ANIM_COORDS,d6		; wtf??? don't add up.  BUG
	
	lea 	SPRITES(pc),a0    	; Get sprite configuration pointer
	lsl.w	#2,d0    		; Index to correct sprite.
	add.l	d0,a0    		; a0 now has correct sprite address
	
	move.l	(a0),a0			; Get the pointer to sprite coords
	addq.l	#8,a0    		; Jump over vars and control handler

; a0 now points to addresses for each animation set.
; eg.  dc.l ANIM_BJ_STAND, ANIM_BJ_WALKLEFT, ANIM_BJ_WALKRIGHT, $ffff
		         		
	moveq	#0,d7
	move.l	a3,a6	 		
	move.l	a0,a5	
.loop:			 
	move.l	(a0)+,a1 		; a1 is now has the animation set addr
	addq.w	#1,d7	 		; count number of animation types
					; for later use.

	move.l	d6,(a3)+		; Store animation type pointer
	
	add.l	#ANIM_SET_SZ,d6		; Point to next animation set
	cmp.w	#-1,(a0)		; Are we at the end of the
					; frame pointers yet?
	bne.s	.loop
	
	subq.w	#1,d7			; d7 now has number of animations
					; per sprite, eg walking left,
					; walking right, standing, jumping.

	move.l	a5,a1			; restore pointers

;--- now we copy each animation set
	
.anim_loop:
	move.l	a6,a3			; restore pointers
	

; --- This is now the start of the Animation sprite loop
	move.l	(a3)+,a4		; eg ANIM_BJ_STANDING in a4
	move.l	a4,d6			; 
	add.l	#12,d6			; d6 now points to ANIM TEMP
	move.l	d6,(a4)
	add.l	#ANIM_TEMP,d6
	move.l	d6,4(a4)		; store Frame set pointer
	add.l	#ANIM_FRAME,d6		;
	move.l	d6,8(a4)		; store Animation speed pointer
;
; a1 now has pointer to Anim_set to be copied (3 pointers)
; a4 now has pointer to Anim_set destination
	move.l	(a4),a3			; copy sprite frame attributes

	move.l	(a1),a0
	move.l	a0,a5
	move.l	(a0),a0	
	move.l	(a0),(a3)

	move.l	(a1),a0
	
	move.l	8(a4),a3
	move.l	8(a0),a0
	move.w	(a0),(a3)
	
	move.l	(a1),a0
	move.l	4(a4),a3
	move.l	4(a0),a0
	
; Now we copy the animation frame set

.loop1:
	move.w	(a0)+,(a3)+		; copy Animation frames set
	cmp.w	#-1,(a0)
	bne	.loop1
	move.w	#-1,(a3)		; must end with -1

	addq.l	#4,a1	
	addq.l	#4,a6
	dbf	d7,.anim_loop
	rts



SPRITE_COUNT:	dc.w	-1		; Holds how many sprites on screen
SPR16_ASSETS:	dc.l	SPRPTR_ASSETS16_BP1,SPRPTR_ASSETS16_BP2,SPRPTR_ASSETS16_BP3,SPRPTR_ASSETS16_BP4,SPRPTR_ASSETS16_BP5
SPR16_AM_PTR:	ds.l	(SPRITE_ASSETS_SIZE_X/2*SPRITE_ASSETS_SIZE_Y)*8

; 0                 2                 4        6       8               10                 14
; Sprite Number(2), Sprite_Status(2), XPOS(2), YPOS(2) Sprite Type(2), Sprite Handler(4), TEMP (2)
SPRITE_ATTRIBUTES_BUFFER:	
	ds.w	MAX_SPRITES*16

	
SPR16_SLOTS:	ds.l	64		; list of sprite slots
	
	
SPRITE_FREE_LIST:
	ds.w	MAX_SPRITES
	

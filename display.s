
PLAYFIELD_SIZE_X	equ	28	; bytes
PLAYFIELD_SIZE_Y	equ	28	; bytes
PLAYFIELD_PLANE_SIZE:	equ	PLAYFIELD_SIZE_X*(PLAYFIELD_SIZE_Y*8)
PLAYFIELD_BITPLANES:	equ	5

SCRPTR_FBUFF_BPL1:	equ	$40000+MEMOFF
SCRPTR_FBUFF_BPL2:	equ	SCRPTR_FBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*1)
SCRPTR_FBUFF_BPL3:	equ	SCRPTR_FBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*2)
SCRPTR_FBUFF_BPL4:	equ	SCRPTR_FBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*3)
SCRPTR_FBUFF_BPL5:	equ	SCRPTR_FBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*4)

SCRPTR_BBUFF_BPL1:	equ	$50000+MEMOFF
SCRPTR_BBUFF_BPL2:	equ	SCRPTR_BBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*1)
SCRPTR_BBUFF_BPL3:	equ	SCRPTR_BBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*2)
SCRPTR_BBUFF_BPL4:	equ	SCRPTR_BBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*3)
SCRPTR_BBUFF_BPL5:	equ	SCRPTR_BBUFF_BPL1+(PLAYFIELD_PLANE_SIZE*4)


;
; INIT_DISPLAY
;
; Initialise screen pointers 
;
INIT_DISPLAY:	
	lea	LSTPTR_CURRENT_SCREEN,a1
	lea	SCRPTR_FBUFF_BPL1,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_FBUFF_BPL2,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_FBUFF_BPL3,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_FBUFF_BPL4,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_FBUFF_BPL5,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_BBUFF_BPL1,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_BBUFF_BPL2,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_BBUFF_BPL3,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_BBUFF_BPL4,a0
	move.l	a0,(a1)+
	bsr	.plane
	lea	SCRPTR_BBUFF_BPL5,a0
	move.l	a0,(a1)+
	bsr	.plane
	
	lea	SPRPTR_MASKS16,a0
	move.l	a0,(a1)+
	bsr 	.plane
	rts	
	
.plane:	move.l	#PLAYFIELD_SIZE_X*224,d7
	lsr.l	#2,d7
.loop:	clr.l	(a0)+
	dbf	d7,.loop
	rts


;
; DBUFF()
;
; Toggle Screen and Display Buffer
;
DBUFF:	lea	SCR_TOGGLE,a0
	tst.w	(a0)
	beq.s	.set_fbuff
	clr.w	(a0)
	bsr	SETDISP_BBUFF		; for restoring the sprite backgrounds
	bsr	SETSCR_FBUFF		
	bra.s	.exit

.set_fbuff:
	move.w	#-1,(a0)
	bsr	SETDISP_FBUFF
	bsr	SETSCR_BBUFF
.exit:	rts
		
	
;
; SETSCR_FBUFF()
;
; Sets the screen pointers to use Front Buffers
;
SETSCR_FBUFF:		
	lea	LSTPTR_CURRENT_SCREEN,a0
	move.l	#SCRPTR_FBUFF_BPL1,(a0)+
	move.l	#SCRPTR_FBUFF_BPL2,(a0)+
	move.l	#SCRPTR_FBUFF_BPL3,(a0)+
	move.l	#SCRPTR_FBUFF_BPL4,(a0)+
	move.l	#SCRPTR_FBUFF_BPL5,(a0)+
	rts

;
; SETSCR_BBUFF
;
; Set the screen pointers to use the Back Buffers
;
SETSCR_BBUFF:		
	lea	LSTPTR_CURRENT_SCREEN,a0
	move.l	#SCRPTR_BBUFF_BPL1,(a0)+
	move.l	#SCRPTR_BBUFF_BPL2,(a0)+
	move.l	#SCRPTR_BBUFF_BPL3,(a0)+
	move.l	#SCRPTR_BBUFF_BPL4,(a0)+
	move.l	#SCRPTR_BBUFF_BPL5,(a0)+
	rts

;
; SETDISP_FBUFF
;
; Set the display pointer to the front buffer	
;
SETDISP_FBUFF:
	lea	COPPER,a0
	add.l	COPPTR_BITPLANES,a0

	move.l	#SCRPTR_FBUFF_BPL1,d0
	move.w	d0,$2(a0)
	swap	d0
	move.w	d0,$6(a0)
	
	move.l	#SCRPTR_FBUFF_BPL2,d0
	move.w	d0,$a(a0)
	swap	d0
	move.w	d0,$e(a0)
	
	move.l	#SCRPTR_FBUFF_BPL3,d0
	move.w	d0,$12(a0)
	swap	d0
	move.w	d0,$16(a0)
	
	move.l	#SCRPTR_FBUFF_BPL4,d0
	move.w	d0,$1a(a0)
	swap	d0
	move.w	d0,$1e(a0)
	
	move.l	#SCRPTR_FBUFF_BPL5,d0
	move.w	d0,$22(a0)
	swap	d0
	move.w	d0,$26(a0)
	rts

;
; SETDISP_BBUFF
;	
; Set the display pointer to the back buffer	
;
SETDISP_BBUFF:
	lea	COPPER,a0
	add.l	COPPTR_BITPLANES,a0

	move.l	#SCRPTR_BBUFF_BPL1,d0
	move.w	d0,$2(a0)
	swap	d0
	move.w	d0,$6(a0)
	
	move.l	#SCRPTR_BBUFF_BPL2,d0
	move.w	d0,$a(a0)
	swap	d0
	move.w	d0,$e(a0)
	
	move.l	#SCRPTR_BBUFF_BPL3,d0
	move.w	d0,$12(a0)
	swap	d0
	move.w	d0,$16(a0)
	
	move.l	#SCRPTR_BBUFF_BPL4,d0
	move.w	d0,$1a(a0)
	swap	d0
	move.w	d0,$1e(a0)
	
	move.l	#SCRPTR_BBUFF_BPL5,d0
	move.w	d0,$22(a0)
	swap	d0
	move.w	d0,$26(a0)
	rts
		
; 
; PRE_BUFFER
;
; Create a buffer for static sprites restore (bombs)
;
PRE_BUFFER:
	lea	LSTPTR_CURRENT_SCREEN,a0
	moveq	#SPR16_BITPLANES-1,d5
	lea	SCRPTR_PRE_SPRITES,a1
	
	lea	LSTPTR_PRE_SCREEN(pc),a3

.loopp:	move.l	(a0)+,a2
	move.l	a1,d0
	move.w	a2,d0
	move.l	d0,a1
	
	move.l	a1,(a3)+
	move.w	#PLAYFIELD_SIZE_Y*8,d7
.loopy:	move.w	#(PLAYFIELD_SIZE_X/2),d6
.loopx:	move.w	(a2)+,(a1)+
	dbf	d6,.loopx
	dbf	d7,.loopy
	
	dbf	d5,.loopp
	rts


; 
; POST_BUFFER
;
; Create a triple buffer for faster background restores.
;
POST_BUFFER:
	lea	LSTPTR_CURRENT_SCREEN,a0
	moveq	#SPR16_BITPLANES-1,d5
	lea	SCRPTR_POST_SPRITES,a1
	
	lea	LSTPTR_POST_SCREEN(pc),a3

.loopp:	move.l	(a0)+,a2
	move.l	a1,d0
	move.w	a2,d0
	move.l	d0,a1
	
	move.l	a1,(a3)+
	move.w	#PLAYFIELD_SIZE_Y*8,d7
.loopy:	move.w	#(PLAYFIELD_SIZE_X/2),d6
.loopx:	move.w	(a2)+,(a1)+
	dbf	d6,.loopx
	dbf	d7,.loopy
	
	dbf	d5,.loopp
	rts

LSTPTR_PRE_SCREEN:	ds.l	6
LSTPTR_POST_SCREEN:	ds.l	6		; Triple buffer plane pointers
LSTPTR_CURRENT_SCREEN:	ds.l	12

; Populate these....
LSTPTR_FRONT_SCREEN:	dc.l	SCRPTR_FBUFF_BPL1
			dc.l	SCRPTR_FBUFF_BPL2
			dc.l	SCRPTR_FBUFF_BPL3
			dc.l	SCRPTR_FBUFF_BPL4
			dc.l	SCRPTR_FBUFF_BPL5

LSTPTR_BACK_SCREEN:	dc.l	SCRPTR_BBUFF_BPL1
			dc.l	SCRPTR_BBUFF_BPL2
			dc.l	SCRPTR_BBUFF_BPL3
			dc.l	SCRPTR_BBUFF_BPL4
			dc.l	SCRPTR_BBUFF_BPL5

SCR_TOGGLE:
	dc.w	0	;  0=Display Front Buffer, Screen Draw Back Buffer
			; -1=Displau Back Buffer, Screen Draw Front Buffer







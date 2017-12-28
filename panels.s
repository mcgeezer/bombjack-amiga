GRADIENT_PAL_COLOUR1:	equ	9
GRADIENT_LENGTH:	equ	7

UPPER_PANEL_SIZE_Y:	equ	16
LOWER_PANEL_SIZE_Y:	equ	16

UPPER_PANEL_SIZE:	equ	PLAYFIELD_SIZE_X*UPPER_PANEL_SIZE_Y
LOWER_PANEL_SIZE:	equ	PLAYFIELD_SIZE_X*LOWER_PANEL_SIZE_Y

SCRPTR_UPPER_PANEL:	equ	$5a000+MEMOFF
SCRPTR_UPPER_PANEL_BP1:	equ	SCRPTR_UPPER_PANEL
SCRPTR_UPPER_PANEL_BP2:	equ	SCRPTR_UPPER_PANEL+(UPPER_PANEL_SIZE*1)
SCRPTR_UPPER_PANEL_BP3:	equ	SCRPTR_UPPER_PANEL+(UPPER_PANEL_SIZE*2)
SCRPTR_UPPER_PANEL_BP4:	equ	SCRPTR_UPPER_PANEL+(UPPER_PANEL_SIZE*3)
SCRPTR_UPPER_PANEL_BP5:	equ	SCRPTR_UPPER_PANEL+(UPPER_PANEL_SIZE*4)

SCRPTR_LOWER_PANEL:	equ	$5b000+MEMOFF
SCRPTR_LOWER_PANEL_BP1:	equ	SCRPTR_LOWER_PANEL
SCRPTR_LOWER_PANEL_BP2:	equ	SCRPTR_LOWER_PANEL+(LOWER_PANEL_SIZE*1)
SCRPTR_LOWER_PANEL_BP3:	equ	SCRPTR_LOWER_PANEL+(LOWER_PANEL_SIZE*2)
SCRPTR_LOWER_PANEL_BP4:	equ	SCRPTR_LOWER_PANEL+(LOWER_PANEL_SIZE*3)

POWERMETER:
	lea	SCRPTR_UPPER_PANEL_BP5,a0
	move.l	a0,a1
	add.l	#64/8,a0
	add.l	#128/8,a1
	
	lea	POWERMETER_MASK,a2
	moveq	#0,d0
	
	move.w	VAR_POWERMETER,d0
	cmp.w	#20,d0			; Power meter points
	bge	.enable
	
.mask:	lsl.w	#3,d0
	add.w	d0,a2
	
	move.l	(a2),d2
	move.l	4(a2),d3
	
	rept	16
	move.l	d2,(a0)			; left hand side
	move.l	d3,(a1)
	
	add.w	#PLAYFIELD_SIZE_X,a0
	add.w	#PLAYFIELD_SIZE_X,a1
	endr
	bra.s	.exit
	
.enable:
	moveq	#7,d0			; Enable the powerball.
	moveq	#0,d1
	bsr	ENABLE_SPRITE
	
	move.w	#21,d0
	bra	.mask
.exit:	rts




DRAW_UPPER_PANEL:
 	lea	TXT_SIDEONE,a0
	lea	LSTPTR_UPPER_PANEL,a1
	moveq	#1,d0
	moveq	#0,d1
	moveq	#0,d6
	bsr	DRAW_TEXT
	
	lea	TXT_SIDETWO,a0
	lea	LSTPTR_UPPER_PANEL,a1
	moveq	#19,d0
	moveq	#0,d1
	moveq	#1,d6
	bsr	DRAW_TEXT
	
	lea	TXT_SCOREONE,a0
	lea	LSTPTR_UPPER_PANEL,a1
	moveq	#1,d0
	moveq	#1,d1
	moveq	#2,d6
	bsr	DRAW_TEXT
	
	lea	TXT_SCORETWO,a0
	lea	LSTPTR_UPPER_PANEL,a1
	moveq	#19,d0
	moveq	#1,d1
	moveq	#3,d6
	bsr	DRAW_TEXT



	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#174,d0				; Gradient Block 1
	move.w	#72,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#0,d6
	bsr	DRAW_PANEL_SPRITE
	
	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#175,d0				; Gradient Block 2
	move.w	#88,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#0,d6
	bsr	DRAW_PANEL_SPRITE
	
	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#176,d0				; Gradient Block 3
	move.w	#104,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#0,d6
	bsr	DRAW_PANEL_SPRITE
	
	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#177,d0				; Gradient Block 4
	move.w	#120,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#0,d6
	bsr	DRAW_PANEL_SPRITE

	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#178,d0				; Gradient Block 5
	move.w	#136,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#0,d6
	bsr	DRAW_PANEL_SPRITE

	
	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#168,d0				; Multiplier sprite
	move.w	#96,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#0,d6
	bsr	DRAW_PANEL_SPRITE

	bsr	DRAW_MULTIPLIER
	
	rts


DRAW_MULTIPLIER:
	moveq	#0,d2
	lea	LSTPTR_UPPER_PANEL,a0
	move.w	#169,d0				; *1 Sprite

	move.w	VAR_BONUS_MULTI,d3
	cmp.w	#4,d3
	bgt.s	.exit
	add.w	d3,d0
	
	move.w	#112,d1				; X Position
	moveq	#0,d2				; Y Position
	moveq	#-1,d6
	bsr	DRAW_PANEL_SPRITE
.exit:	rts
	

DRAW_LOWER_PANEL:
	lea	TXT_ROUND,a0
	lea	LSTPTR_LOWER_PANEL,a1
	moveq	#14,d0
	moveq	#0,d1
	moveq	#2,d6			; Colour number (0-3)
	bsr	DRAW_TEXT
	
	lea	TXT_HISCORE,a0
	lea	LSTPTR_LOWER_PANEL,a1
	moveq	#20,d0
	moveq	#0,d1
	moveq	#1,d6
	bsr	DRAW_TEXT		
	
	lea	TXT_ROUNDNUM,a0
	lea	LSTPTR_LOWER_PANEL,a1
	moveq	#14,d0
	moveq	#1,d1
	moveq	#3,d6
	bsr	DRAW_TEXT
	
	lea	TXT_BIGSCORE,a0
	lea	LSTPTR_LOWER_PANEL,a1
	moveq	#20,d0
	moveq	#1,d1
	moveq	#1,d6
	bsr	DRAW_TEXT


	move.w	BJ_LIVES,d7
	subq.w	#1,d7
	
	lea	LSTPTR_LOWER_PANEL,a0
	moveq	#0,d0				; Bomb Jack sprite
	moveq	#0,d1				; X Position
	moveq	#0,d2				; Y Position
.lives:
	bsr	DRAW_PANEL_SPRITE
	add.w	#16,d1
	dbf	d7,.lives	
	rts
	
; d0 = sprite number
; d1 = x position
; d2 = y position
; d6 = -1 straight copy, 0+ = Or operation
; a0 = panel screen bitplane list pointer
DRAW_PANEL_SPRITE:
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	a0,a5
	bsr	GET_SPRITE_MASK_POINTERS

	move.w	d1,d0
	move.w	d2,d1

	move.w	d0,d3			; bomb xpos in d0
	and.w	#$f,d3			; bomb ypos in d1
	lsl.w	#8,d3
	lsl.w	#4,d3			; bits to shift needs to be in upper
	
	bsr	GET_SPRITE_OFFSETS
; a5 now destination pointer into screen
; a2 now source sprite
; d3 has barrel shift offset for blitter
	
	and.w	#$fffe,d0

	lea	CHIPBASE,a6
	move.l	a5,a0
	
	move.w	#0,BLTCON1(a6)	
	
	tst.w	d6
	bmi.s	.copy_mode
	bpl.s	.or_mode

.copy_mode:
	or.w	#$9F0,d3
	move.w	#$ffff,BLTAFWM(a6)  ; No masking needed
	move.w	#$ffff,BLTALWM(a6)
	move.w	#38,BLTAMOD(a6)
	move.w	#(PLAYFIELD_SIZE_X)-2,BLTDMOD(a6)
	move.w	#(SPR16_SIZE*64)+1,d4
	bra.s	.blit

.or_mode:
	or.w	#$DFC,d3
	move.w	#$ffff,BLTAFWM(a6)  ; No masking needed
	move.w	#$0,BLTALWM(a6)
	move.w	#36,BLTAMOD(a6)
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTDMOD(a6)
	move.w	#(PLAYFIELD_SIZE_X)-4,BLTBMOD(a6)
	move.w	#(SPR16_SIZE*64)+2,d4
	bra.s	.blit
	nop
.blit:
	move.w	d3,BLTCON0(a6)
	
	rept	4
	move.l	(a0)+,a1		; get next bitplane 1
	add.l	d0,a1			; add X word offset
	add.l	d1,a1			; add Y line offset
	bsr	WAIT_FOR_BLITTER
	move.l	a2,BLTAPTH(a6)		
	move.l	a1,BLTBPTH(a6)		; Destination to be or'd
	move.l	a1,BLTDPTH(a6)
	move.w	d4,BLTSIZE(a6)  ; 16*64 + 2
	add.l	#$2000,a2		; next plane - crap code.
	endr
	movem.l	(a7)+,d0-d7/a0-a6
	rts
		


LSTPTR_UPPER_PANEL:	dc.l	SCRPTR_UPPER_PANEL_BP1
			dc.l	SCRPTR_UPPER_PANEL_BP2
			dc.l	SCRPTR_UPPER_PANEL_BP3
			dc.l	SCRPTR_UPPER_PANEL_BP4
			dc.l	SCRPTR_UPPER_PANEL_BP5
			

LSTPTR_LOWER_PANEL:	dc.l	SCRPTR_LOWER_PANEL_BP1
			dc.l	SCRPTR_LOWER_PANEL_BP2
			dc.l	SCRPTR_LOWER_PANEL_BP3
			dc.l	SCRPTR_LOWER_PANEL_BP4

TXT_SIDEONE:	dc.b	"SIDE-ONE",0	
		even
TXT_SIDETWO:	dc.b	"SIDE-TWO",0
		even
TXT_SCOREONE:	dc.b	"       0",0
		even
TXT_SCORETWO:	dc.b	"       0",0
		even		
TXT_ROUND:	dc.b	"ROUND",0
		even
TXT_HISCORE:	dc.b	"HI-SCORE",0
		even
TXT_ROUNDNUM:	dc.b	" -1- ",0
		even
TXT_BIGSCORE:	dc.b	"       0",0
		even

RAINBOW_CYCLE:	dc.w	0
RAINBOW_CYCLE_SPEED:	dc.w	0

VAR_BONUS_MULTI:	dc.w	0
VAR_POWERMETER:	dc.w	0

POWERMETER_MASK:
	dc.l	%00000000111111111111111111111000
	dc.l	%00011111111111111111111100000000
	dc.l	%00000000111111111111111111110000
	dc.l	%00001111111111111111111100000000 
	dc.l	%00000000111111111111111111100000
	dc.l	%00000111111111111111111100000000
	dc.l	%00000000111111111111111111000000
	dc.l	%00000011111111111111111100000000
	dc.l	%00000000111111111111111110000000
	dc.l	%00000001111111111111111100000000
	dc.l	%00000000111111111111111100000000
	dc.l	%00000000111111111111111100000000
	dc.l	%00000000111111111111111000000000
	dc.l	%00000000011111111111111100000000 ;6
	dc.l	%00000000111111111111110000000000
	dc.l	%00000000001111111111111100000000 ;7
	dc.l	%00000000111111111111100000000000 
	dc.l	%00000000000111111111111100000000 ;8
	dc.l	%00000000111111111111000000000000
	dc.l	%00000000000011111111111100000000 ;9
	dc.l	%00000000111111111110000000000000
	dc.l	%00000000000001111111111100000000 ;10
	dc.l	%00000000111111111100000000000000 
	dc.l	%00000000000000111111111100000000 ;11
	dc.l	%00000000111111111000000000000000 
	dc.l	%00000000000000011111111100000000 ;12
	dc.l	%00000000111111110000000000000000  
	dc.l	%00000000000000001111111100000000 ;13
	dc.l	%00000000111111100000000000000000  
	dc.l	%00000000000000000111111100000000 ;14
	dc.l	%00000000111111000000000000000000  
	dc.l	%00000000000000000011111100000000 ;15
	dc.l	%00000000111110000000000000000000   
	dc.l	%00000000000000000001111100000000 ;16
	dc.l	%00000000111100000000000000000000   
	dc.l	%00000000000000000000111100000000 ;17
	dc.l	%00000000111000000000000000000000
	dc.l	%00000000000000000000011100000000 ;18
	dc.l	%00000000110000000000000000000000 
	dc.l	%00000000000000000000001100000000 ;19
	dc.l	%00000000100000000000000000000000 
	dc.l	%00000000000000000000000100000000 ;20
	dc.l	%00000000000000000000000000000000 
	dc.l	%00000000000000000000000000000000 ;21
	even
	







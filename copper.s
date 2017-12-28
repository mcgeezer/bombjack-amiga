COPPER:			equ	$7e000

;
; INIT_COPPER
; 
; Initialize the Copper list
;
INIT_COPPER:
	lea	COPPER,a1
	move.l	a1,d4
	
; Upper Panel (76 bytes)
	move.w	#$180,(a1)+		; Black Background
	move.w	#$0000,(a1)+
	
	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_SIDEONE_COL
	move.w	#$182,(a1)+		; Upper Panel text colour 1
	move.w	#$0f0,(a1)+
	
	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_SIDETWO_COL
	move.w	#$184,(a1)+		; Upper Panel text colour 2
	move.w	#$0ff,(a1)+
	
	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_MULTIPLIER_COL
	move.w	#$186,(a1)+
	move.w	#$00f,(a1)+

 	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_SCOREONE_COL
	move.w	#$188,(a1)+		; Upper Panel text colour 3
	move.w	#$0f0,(a1)+

	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_SCORETWO_COL
	move.w	#$190,(a1)+		; Upper Panel text colour 4
	move.w	#$f0f,(a1)+

	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_GRADIENT_COL	; Upper Panel Gradient 
	move.w	#$192,(a1)+
	move.w	#$777,(a1)+
	move.w	#$194,(a1)+
	move.w	#$888,(a1)+
	move.w	#$196,(a1)+
	move.w	#$999,(a1)+
	move.w	#$198,(a1)+
	move.w	#$aaa,(a1)+
	move.w	#$19a,(a1)+
	move.w	#$bbb,(a1)+
	move.w	#$19c,(a1)+
	move.w	#$ccc,(a1)+	
	move.w	#$19e,(a1)+
	move.w	#$ddd,(a1)+
	
	move.w	#$1a0,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1a2,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1a4,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1a6,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1a8,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1aa,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1ac,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1ae,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1b0,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1b2,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1b4,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1b6,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1b8,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1ba,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1bc,(a1)+
	move.w	#$000,(a1)+
	move.w	#$1be,(a1)+
	move.w	#$000,(a1)+
	
	
	

	move.w	#$0101,(a1)+
	move.w	#$ff00,(a1)+

	move.w	#BPLCON0,(a1)+ 	; 		; This is play area
	move.w	#$5200,(a1)+   	; 		; 4 PLanes here
	move.w	#BPLCON1,(a1)+ 	; 
	move.w	#0,(a1)+  	; 
	move.w	#BPLCON2,(a1)+	; 
	move.w	#0,(a1)+	; 
	move.w	#DIWSTRT,(a1)+	; 
	move.w	#$2091,(a1)+	;  Start at line 32 ($20)
	move.w	#DIWSTOP,(a1)+	; 
	move.w	#$1f71,(a1)+	;  End at line 48 ($30)
	move.w	#DDFSTRT,(a1)+	; 
	move.w	#$003c,(a1)+	; 
	move.w	#DDFSTOP,(a1)+  ; 
	move.w	#$00a4,(a1)+	; 

; reload palette from IFF (64 bytes)

	lea	LSTPTR_UPPER_PANEL,a0
	moveq	#5-1,d7			; number of planes to load
	bsr	INIT_COPPER_BITPLANES

	move.w	#$3001,(a1)+		; wait for line 46
	move.w	#$ff00,(a1)+

; Main play area (12)
	move.w	#BPLCON0,(a1)+ 	; 		; This is play area
	move.w	#$5200,(a1)+   	; 

	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_BITPLANES
	lea	LSTPTR_FRONT_SCREEN,a0
	moveq	#5-1,d7			; number of planes to load
	bsr	INIT_COPPER_BITPLANES

	move.l	a1,d5
	sub.l	d4,d5
	move.l	d5,COPPTR_MAIN_PAL

	lea	SPR16_PAL(pc),a0
	move.w	#$180,d6
	move.w	#31,d7
.pal1:
	move.w	d6,(a1)+
	move.w	(a0)+,(a1)+
	addq.w	#2,d6
	dbf	d7,.pal1	

	move.w	#$180,(a1)+
	move.w	#$000,(a1)+

; 8 words per bitplane

;

; Set SPR16_BITPLANES in copper - these are updated by DBUFF for double buffering	

; Bottom play area (8)			; Wait till bottom area
	move.w	#$ffdf,(a1)+		; Wait for line 255
	move.w	#$fffe,(a1)+

	move.w	#$1007,(a1)+		; Wait Horizontal position
	move.w	#$ff00,(a1)+		; unmask verticla and horizontal
	
	move.w	#BPLCON0,(a1)+ 	; 		; This is play area
	move.w	#$4200,(a1)+   	; 

	lea	LSTPTR_LOWER_PANEL,a0
	moveq	#4-1,d7			; number of planes to load
	bsr	INIT_COPPER_BITPLANES

	move.l	#$fffffffe,(a1)+
	rts

INIT_COPPER_BITPLANES:
	move.w	#BPL0PTL,d2
	move.w	#BPL0PTH,d3
	
.loop:	move.l	(a0)+,d0
	move.w	d2,(a1)+
	move.w	d0,(a1)+
	swap	d0
	move.w	d3,(a1)+
	move.w	d0,(a1)+
	addq.w	#4,d2
	addq.w	#4,d3
	dbf	d7,.loop
	rts

COPPTR_MAIN_PAL:	dc.l	0	; Main game palette start
COPPTR_BITPLANES:	dc.l	0	; Main game bitplanes
COPPTR_SIDEONE_COL:	dc.l	0	; Player 1 'SIDE-ONE'
COPPTR_SIDETWO_COL:	dc.l	0	; Player 2 'SIDE-TWO'
COPPTR_SCOREONE_COL:	dc.l	0	; Player 1 score text
COPPTR_SCORETWO_COL:	dc.l	0	; Player 2 score text
COPPTR_MULTIPLIER_COL:	dc.l	0	; x2, x3, x4 colours
COPPTR_GRADIENT_COL:	dc.l	0	; Mulitplier Gradient
COPPTR_HISCORE_COL:	dc.l	0	; Hiscore text

_OLDCOPPER1:	dc.l	0
_OLDCOPPER2:	dc.l	0






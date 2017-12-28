;
; -= Memory Map =-
;   
; +-----------------------------------------------+
; |$01000-$05000 > Game Code
; |$18000-$1ffff > Scene 1 Bitmap                 |
; |$20000-$27fff > Scene 2 Bitmap                 |
; |$28000-$2ffff > Scene 3 Bitmap                 |
; |$30000-$37fff > Scene 4 Bitmap                 |
; |$38000-$3ffff > Scene 5 Bitmap                 |
; |$40000-$47fff > Screen Buffer 1 Front Buffer   |
; |$48000-$49fff > Tile Collisions                |
; |$4a000-$4bfff > Enemy Collisions               |
; |$4c000-$4dfff > Bomb Collisions                |
; |$4e000-$4ffff > Power Ball Collisions          |
; |$50000-$57fff > Screen Buffer 2 Back Buffer    |
; |$58000-$59fff > Sprite Masks                   |
; |$5a000-$5afff > Upper panel                    |
; |$5b000-$5bfff > Bottom panel                   |
; |$5c000-$5dfff > Bonus Collisions               |
; |$5e000-$5efff > 8x8 Font                       |
; |$60000-$67fff > Screen Buffer 3 Post Sprites   |
; |$68000-$6ffff > Sprite Assets                  |
; |$70000-$77fff > Screen Buffer 4 Pre Sprites    |
; |$78000-$7dfff > Sprite List Structures         |
; |$7e000-$7efff > Copper List                    |
; |$7f000-$7ffff > Stack                          |
; +-----------------------------------------------+

MEMOFF:		equ	$80000
MEMSTART:	equ	MEMOFF
MEMEND:		equ	$100000

	bra	start
	nop

    include hardware.i
    include input.s
    include display.s
    include panels.s
    include sprite.s
    include collision.s
    include copper.s
    include bomb.s
    include powerball.s
    include esb.s    
    include mummy.s    
    include jack.s
    include tile.s
    include enemy.s
    include smiley.s
    include scene.s    
    include text.s
 
PTR_STACK:		equ	$7fffe+MEMOFF


; Sprites by type
; These determine the collision screen that the sprite mask is placed in.
SPR_TYPE_BOMBJACK:	equ	0	; Dummy for BOMBJACK
SPR_TYPE_ENEMY:	equ	1		; Enemies screen
SPR_TYPE_BOMB:	equ	2		; Bombs screen
SPR_TYPE_POWERBALL:	equ 	3	; Powerball screen
SPR_TYPE_SMILEY:	equ	4	; Enemies screen
SPR_TYPE_ESB:	equ	5		; Extra, Bonus, Special Token

; Sprite numbers alloctaed to each type
SPR_BOMBJACK:	equ	0
SPR_MUMMY:	equ	1		; Walking Metal Man
SPR_BOMB:	equ	2
SPR_POWERBALL:	equ	3
SPR_SMILEY:	equ	4
SPR_ESB:	equ	5		; Extra, Special, Bonus tokens
SPR_SPHERE:	equ	6		; Vertical Metal Orb
SPR_BIRD:	equ	7		; Bird
SPR_ORB:	equ	8		; Horizontal Black Orb
SPR_UFO:	equ	9		; UFO
SPR_HORN:	equ	10		; Moves diagonal
SPR_CLUB:	equ	11		; floats vertical and horizontal
CENTRE:		equ	((PLAYFIELD_SIZE_X*8)/2)-9

DEBUG:		equ	0	; Don't shut down system if true
				; useful for debugging.

start:	bsr	CLEAR_MEM		; Initialise Memory
	
	move.w	#ESB_BONUS,ESB_TOKEN
	
	lea	OLD_STACK(pc),a0
	move.l	a7,(a0)
	lea	PTR_STACK,a7

	bsr	INIT_DISPLAY		; Clear screen SPR16_BITPLANES
	
	lea	SPR16_IFF(pc),a0	; Pointer to IFF image
	lea	SPR16_PAL(pc),a6	; 
	bsr	LOAD_SPRITE16_ASSETS	; Draw image to front screen buffer

	bsr	INIT_SPR16_POINTERS	; Build sprite mask pointer

	lea	SPR16_PAL(pc),a0	; Place to hold our palette
	bsr	INIT_COPPER		; for copper list

	bsr	PRE_BUFFER		; Create pre sprites buffer
	bsr	POST_BUFFER		; Create post sprites buffer
					; after bombs are drawn.
					
	bsr	INIT_YTAB		; Build a Y Position table

	lea	EGYPT_IFF,a0
	bsr	LOAD_SCENE

	lea	TILE_COLOURS_ORANGE(pc),a0
	lea	TILE_COLOURS_EGYPT,a1
	bsr	SET_TILE_COLOURS
	
	lea	LEVEL_1_TILES(pc),a0
	bsr	LOAD_TILES	
	

	nop
	nop
	nop
	bsr	INIT_SPRITE_FREE_LIST
	bsr	INIT_SPRITES		; Configure all sprites
	

;	bsr	SAVE_SPRITE_ATTRIBS
;	bsr	CHANGE_ENEMIES
	
;	bsr	RESTORE_SPRITE_ATTRIBS

	lea	LEVEL_1_BOMBS(pc),a5
	bsr	DRAW_BOMBS		; write to front buffer
	bsr	DBUFF
	
	lea	LEVEL_1_BOMBS(pc),a5
	bsr	DRAW_BOMBS		; write to back buffer
	bsr	DBUFF
	
;	moveq	#LIT_BOMB,d1
;	bsr	LIGHT_BOMB

	moveq	#1,d0			; Disable bomb lit sprite
	bsr	DISABLE_SPRITE

	moveq	#MAX_COLLECT_BOMBS-1,d7

	moveq	#2,d0			; Disable detonate bomb sprite
.collect:	
	bsr	DISABLE_SPRITE
	addq.w	#1,d0
	dbf	d7,.collect

	moveq	#8,d0			; Disable smiley face
	bsr	DISABLE_SPRITE		

	moveq	#9,d0
	bsr	DISABLE_SPRITE		; Disable ESB
	nop
	nop
	nop

	move.w	#$777,$dff200
	move.w	#$999,$dff202
	move.w	#$aaa,$dff204
	move.w	#$ccc,$dff206
	
	move.l	#MAX_COLLECT_FREELIST,$80010

	moveq	#0,d0
	move.l	#HDL_BOMBJACK,a6
	bsr	SET_SPRITE_HANDLER


	bsr	DRAW_UPPER_PANEL
	bsr	DRAW_LOWER_PANEL

	moveq	#7,d0
	bsr	DISABLE_SPRITE		; Disable Powerball

	bsr	ANIMATE_SPRITES
		
	moveq	#1,d0
	cmp.w	#DEBUG,d0
	beq	MAIN_LOOP
	
	lea 	CHIPBASE,a0
	
; System Shutdown 
	move.w	DMACONR(a0),d0		
	or.w #$8000,d0
	move.w d0,_DMACON
	
	move.w	INTENAR(a0),d0
	or.w	#$8000,d0
	move.w	d0,_INTENA

	move.w	INTREQR(a0),d0
	or.w	#$8000,d0
	move.w	d0,_INTREQ
	
	move.w	ADKCONR(a0),d0
	or.w	#$8000,d0
	move.w	d0,_ADKCON

; Store existing Copper pointers	
	move.l	$4,a6
	move.l	#gfxname,a1
	moveq	#0,d0
	jsr	-552(a6)
	move.l	d0,gfxbase
	move.l	d0,a6
	move.l	34(a6),_OLDVIEW
	move.l	$26(a6),_OLDCOPPER1
	move.l	$32(a6),_OLDCOPPER2

	move.l	#0,a1
	jsr 	LOADVIEW(a6)
	jsr	WAITTOF(a6)
	jsr	WAITTOF(a6)

; Disable OS	
	move.l	$4,a6
	jsr	FORBID(a6)	; FORBID	

; Disable Interupts
	lea	CHIPBASE,a0
	move.w	#%0111111111111111,DMACON(a0)	; Disable DMA
	move.w	#$7fff,INTENA(a0)

; Set up bit planes
	move.l	#SCRPTR_FBUFF_BPL1,BPL0PTH(a0)
	move.l	#SCRPTR_FBUFF_BPL2,BPL1PTH(a0)
	move.l	#SCRPTR_FBUFF_BPL3,BPL2PTH(a0)
	move.l	#SCRPTR_FBUFF_BPL4,BPL3PTH(a0)
	move.l	#SCRPTR_FBUFF_BPL5,BPL4PTH(a0)

; Insert Copper
	move.l	#COPPER,COP1LCH(a0)
	move.l	#COPPER,COP2LCH(a0)

; -- Set up display

;	move.w	#$5200,BPLCON0(a0)		; # SPR16_BITPLANES
	
;	move.w	#$0000,BPLCON1(a0)
;	move.w	#$0000,BPLCON2(a0)
;	move.w	#$0000,BPL1MOD(a0)
;	move.w	#$0000,BPL2MOD(a0)
	
;	move.w	#$2c91,DIWSTRT(a0)	; 2c = vertical start, 81=hstart
;	move.w	#$0c71,DIWSTOP(a0)	; THIS OK NOW
	
;	move.w	#$003c,DDFSTRT(a0)
;	move.w	#$00a4,DDFSTOP(a0)

	move.w	#%1000001111000000,DMACON(a0) ; Enable BPL and COP

	bsr	DBUFF

	move.w	#$777,$dff1a0
	move.w	#$888,$dff1a2
	move.w	#$999,$dff1a4
	move.w	#$aaa,$dff1a6
	move.w	#$770,$dff1a8
	move.w	#$880,$dff1aa
	move.w	#$990,$dff1ac
	move.w	#$aa0,$dff1ae

	move.w	#$770,$dff1b0
	move.w	#$880,$dff1b2
	move.w	#$990,$dff1b4
	move.w	#$aa0,$dff1b6
	move.w	#$770,$dff1b8
	move.w	#$880,$dff1ba
	move.w	#$990,$dff1bc
	
;
; - This is the main game loop
;
MAIN_LOOP:
	move.w	#$000,$dff180

	bsr	ENEMY_CYLON
	bsr	ESB_CYLON
	bsr	POWERBALL_COLOUR_CYCLE
	bsr	POWERMETER
	bsr	DRAW_MULTIPLIER

	lea	LEV1FORM(pc),a0
	bsr	LOAD_ENEMIES
	
;	move.w	#$000,$dff180
	bsr	SAVE_ALL_SPRITES
;	move.w	#$007,$dff180
	bsr	PLOT_ALL_SPRITES

;	move.w	#$070,$dff180
	bsr	ANIMATE_SPRITES
;	move.w	#$08f,$dff180

		
WAIT_VB:
	lea	CHIPBASE,a0	
	move.l	VPOSR(a0),d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne	WAIT_VB

	bsr	DBUFF
;	move.w	#$770,$dff180
	bsr	RESTORE_ALL_SPRITES
	addq.w	#1,FRAME_COUNTER

;	move.w	#$707,$dff180
;	move.w	#$000,$dff180

	btst	#6,CIAAPRA		; Left mouse pressed?
	beq.s	EXIT

	btst	#7,CIAAPRA		; Fire button to trigger the
	bne.	.main1			; ESB appear event (test only).
	moveq	#9,d0			
	bsr	ENABLE_SPRITE

.main1:
	bra	MAIN_LOOP
	
EXIT:	moveq	#1,d0
	cmp.w	#DEBUG,d0
	beq	.return

; Restore interupts
	lea	CHIPBASE,a0
	move.w	#$7fff,DMACON(a0)
	move.w	_DMACON,DMACON(a0)
	move.w	#$7fff,INTENA(a0)
	move.w	_INTENA,INTENA(a0)
	move.w	#$7fff,INTREQ(a0)
	move.w	_INTREQ,INTREQ(a0)
	move.w	#$7fff,ADKCON(a0)
	move.w	_ADKCON,ADKCON(a0)
	
; Restore copper
	move.l	_OLDCOPPER1,COP1LCH(a0)
	move.l	_OLDCOPPER2,COP2LCH(a0)
	move.l	gfxbase,a6
	move.l	_OLDVIEW,a1
	jsr	LOADVIEW(a6)
	jsr	WAITTOF(a6)
	jsr	WAITTOF(a6)
	
; Restore OS
	move.l	$4,a6
	jsr	FORBID(a6)
	
.return	lea	OLD_STACK(pc),a0
	move.l	(a0),a7
	moveq	#0,d0
	rts

; 
; Clear memory with zeros
;
CLEAR_MEM:
	lea	MEMSTART,a0
	lea	MEMEND,a1
.loop:	clr.l	(a0)+
	cmp.l	a0,a1
	bgt.s	.loop
	rts




;
; A simple routine to build a Y position table
; to save on using long multiply instructions.
;
INIT_YTAB:
	lea	TAB_Y(pc),a0
	move.l	#240,d7
	moveq	#0,d0
.loop	move.w	d0,(a0)+
	add.w	#(PLAYFIELD_SIZE_X),d0
	dbf	d7,.loop
	rts


;
; Wait for the blitter to free up
;
WAIT_FOR_BLITTER:
	lea	CHIPBASE,a6
.wait:	btst 	#6,DMACONR(a6)
	bne.s	.wait
	rts

; a0 = pointer to iff
LOAD_SCENE:
	move.l	a0,-(a7)
	lea	LSTPTR_CURRENT_SCREEN(pc),a2
	bsr	DISPLAY_SCENE
	bsr	DBUFF
	move.l	(a7)+,a0
	
	move.l	a0,-(a7)
	lea	LSTPTR_CURRENT_SCREEN(pc),a2
	bsr	DISPLAY_SCENE
	bsr	DBUFF
	move.l	(a7)+,a0
	
	move.l	a0,-(a7)
	lea	LSTPTR_POST_SCREEN(pc),a2
	bsr	DISPLAY_SCENE
	move.l	(a7)+,a0

	move.l	a0,-(a7)
	lea	LSTPTR_PRE_SCREEN(pc),a2
	bsr	DISPLAY_SCENE
	move.l	(a7)+,a0
	rts

; a0 = Pointer to Level tiles
LOAD_TILES:
	move.l	a0,-(a7)
	lea	LSTPTR_POST_SCREEN(pc),a2
	moveq	#0,d3
	bsr	DRAW_8X8_TILES
	move.l	(a7)+,a0

	move.l	a0,-(a7)
	lea	SCRPTR_TILE_COLLISIONS,a2
	moveq	#-1,d3			; Set this because it's a mask screen
	bsr	DRAW_8X8_TILES
	move.l	(a7)+,a0

	move.l	a0,-(a7)
	lea	LSTPTR_CURRENT_SCREEN(pc),a2
	moveq	#0,d3			; Set this because it's a mask screen
	bsr	DRAW_8X8_TILES
	move.l	(a7)+,a0
	
	move.l	a0,-(a7)
	bsr	DBUFF
	move.l	(a7)+,a0
	
	move.l	a0,-(a7)
	lea	LSTPTR_CURRENT_SCREEN(pc),a2
	moveq	#0,d3			; Set this because it's a mask screen
	bsr	DRAW_8X8_TILES
	bsr	DBUFF
	move.l	(a7)+,a0
	rts
	





HDL_DUMMY:	rts

;
; Structure is as follows:
;
; sprite num (word), xpos (word), ypos (word), 
; control word (word), handler address (long)
;
; Perhaps need a start frame number here.
; Control word is
; $1000 = Sprite is an enemy
; $2000 = Sprite is a bomb
; $0    = Sprite is bombjack
SPR16_ATTR:
;1
;103x103 is centre
	dc.w	SPR_BOMBJACK,80,60,SPR_TYPE_BOMBJACK	; #0 is Bombjack
	dc.l	HDL_BOMBJACK

	dc.w	SPR_BOMB,0,0,SPR_TYPE_BOMB		; #1 is Lit bomb
	dc.l	HDL_BOMBS				; Don't plot mask

	dc.w	SPR_BOMB,8,8,SPR_TYPE_BOMB		; #2 is collect bomb
	dc.l	HDL_COLLECT_BOMBS			; Don't plot mask
	
	dc.w	SPR_BOMB,8,8,SPR_TYPE_BOMB		; #3 is collect bomb
	dc.l	HDL_COLLECT_BOMBS			; Don't plot mask
	
	dc.w	SPR_BOMB,8,8,SPR_TYPE_BOMB		; #4 is collect bomb
	dc.l	HDL_COLLECT_BOMBS			; Don't plot mask

	dc.w	SPR_BOMB,8,8,SPR_TYPE_BOMB		; #4 is collect bomb
	dc.l	HDL_COLLECT_BOMBS			; Don't plot mask

	dc.w	SPR_BOMB,8,8,SPR_TYPE_BOMB		; #4 is collect bomb
	dc.l	HDL_COLLECT_BOMBS			; Don't plot mask

	dc.w	SPR_POWERBALL,103,103,SPR_TYPE_POWERBALL	; 
	dc.l	HDL_POWERBALL				;

	dc.w	SPR_SMILEY,160,160,SPR_TYPE_SMILEY
	dc.l	HDL_SMILEY

	dc.w	SPR_ESB,144,16,SPR_TYPE_ESB		; 9
	dc.l	HDL_ESB

	dc.w	-1



; this is a dynamically generated list
; it contains sprites that are on screen.

; THIS IS THE SPRITE CONFIGURATION.
SPRITES:	dc.l	PLY1_SPRITES		; controlled by joystick
		dc.l	ENY_MUMMY
		dc.l	BOMB_SPRITES
		dc.l	POWERBALL
		dc.l	SMILEY
		dc.l	ESB_SPRITES

;								      X
;		0 0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  2  2  2  2  2  2  2  2
;		0 1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7
LEVEL_1_TILES:	
	dc.b	2,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,10 ;0
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;1
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;2
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,$fe,00,00,00,00,00,00,00,00,00,07 ;3
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;4
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;5
	dc.b	3,00,00,00,00,00,00,$ff,00,00,00,00,00,00,00,01,01,01,01,01,01,01,00,00,00,00,00,07 ;6
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;7
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;8
	dc.b	3,00,00,00,00,00,01,01,01,01,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;9
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;10
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;11
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;12
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;13
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;14
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;15
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;16
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;17
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,01,01,01,01,01,01,00,00,00,00,00,00,00,00,00,07 ;18
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;19
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;20
	dc.b	3,00,00,01,01,01,01,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;21
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;22
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;23
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,01,01,01,01,01,01,01,01,01,00,00,07 ;24
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;25
	dc.b	3,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07 ;26
	dc.b	6,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,04,08 ;27
	even

;								     
;		0 0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  2  2  2  2  2  2  2  2
;		0 1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7
LEVEL_1_BOMBS:
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;0
	dc.b	0,00,00,00,13,00,00,14,00,00,15,00,00,00,00,00,00,00,00,24,00,00,23,00,00,22,00,00 ;1
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;2
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;3
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;4
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;5
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;6
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,01,00,00,02,00,00,03,00,00,04,00,00,00,00,00 ;7
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;8
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;9
	dc.b	0,09,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,05,00,00 ;10
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;11
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;12
	dc.b	0,10,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,06,00,00 ;13
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;14
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;15
	dc.b	0,11,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,07,00,00 ;16
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;17
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;18
	dc.b	0,12,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,08,00,00 ;19
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;20
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;21
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,18,00,00,17,00,00,16,00,00,00,00,00 ;22
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;23
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;24
	dc.b	0,00,00,00,21,00,00,20,00,00,19,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;25
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;26
	dc.b	0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;27
	even

; Enemy formation for level 1
; enemy number (word)
; Frame number (word)
; Sprite type (see constants)
; Position (word) ($ff=left position, $0=right position)
; Speed (word)
; Attribute 1 (number of turns for mummy must be loaded in the first
;		record - regardless of sprite type)
;		Set all others to $ffff
; Attribute 2 (Enemy type to transform to)

; (Max 10) Terminal with -1

LEV1FORM:
	dc.w	0,200,SPR_MUMMY,-1,2,2,SPR_ORB,0
	dc.w	1,300,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	2,400,SPR_MUMMY,-1,2,$ffff,SPR_ORB,0
	dc.w	3,500,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	4,600,SPR_MUMMY,-1,2,$ffff,SPR_ORB,0
	dc.w	5,700,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	6,800,SPR_MUMMY,-1,2,$ffff,SPR_ORB,0
	dc.w	7,900,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	8,1000,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	9,1100,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	10,1200,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.w	11,1300,SPR_MUMMY,00,2,$ffff,SPR_ORB,0
	dc.l	-1

OLD_STACK:	dc.l	0

; 
FRAME_COUNTER:	dc.w	0

gfxname:	dc.b	"graphics.library",0
		even

gfxbase:	dc.l	0

_ADKCON:	dc.w	0
_INTENA:	dc.w 	0
_DMACON:	dc.w	0
_INTREQ:	dc.w	0

_OLDVIEW:	dc.l	0



; List of sprite handlers
SPRITE_HANDLERS:	dc.l	SPR_BOMBJACK
			dc.l	HDL_BOMBJACK
			dc.l	SPR_MUMMY
			dc.l	HDL_MUMMY
			dc.l	SPR_BOMB
			dc.l	HDL_COLLECT_BOMBS
			dc.l	SPR_POWERBALL
			dc.l	HDL_POWERBALL
			dc.l	SPR_SMILEY
			dc.l	HDL_SMILEY
			dc.l	SPR_ESB
			dc.l	HDL_ESB
			dc.l	SPR_SPHERE
			dc.l	HDL_DUMMY
			dc.l	SPR_BIRD
			dc.l	HDL_DUMMY
			dc.l	SPR_BIRD
			dc.l	HDL_DUMMY
			dc.l	SPR_ORB
			dc.l	HDL_DUMMY
			dc.l	SPR_UFO
			dc.l	HDL_DUMMY
			dc.l	SPR_HORN
			dc.l	HDL_DUMMY
			dc.l	SPR_CLUB
			dc.l	HDL_DUMMY

; Table of Y positions
TAB_Y:	ds.w	256		; index of y positions
	even



; spr number, current status, turns remaining,
; current status 0=walking left,1=walking right, 2=falling, 3=transforming
; 0.w = sprite number
; 2.w = metal man status (see above)
; 4.w = number of turns in direction remaining
; 6.w = falling index
; 8.w = speed setting
; 10.w = speed index
; 12.w = unused
; 14.w = unused

SPEEDINDEX:	dc.l	SPEEDTAB1,SPEEDTAB2,SPEEDTAB3,SPEEDTAB4
		dc.l	SPEEDTAB5,SPEEDTAB6,SPEEDTAB7,SPEEDTAB8
		
SPEEDTAB1:	dc.b	3,-1
		even
SPEEDTAB2:	dc.b	2,-1
		even
SPEEDTAB3:	dc.b	1,-1
		even
SPEEDTAB4:	dc.b	1,0,-1
		even
SPEEDTAB5:	dc.b	1,0,0,-1
		even
SPEEDTAB6:	dc.b	1,0,0,0,-1
		even
SPEEDTAB7:	dc.b	1,0,0,0,0,-1
		even
SPEEDTAB8:	dc.b	1,0,0,0,0,0,-1
		even

; fall table 
GRAVITY:
	incbin	sinetab.dat
	even

SPR16_PAL:	ds.w	32
		even
SPR16_IFF:	incbin	"assets_G16x16.iff"
		even

FONT_ASSET:	incbin	"bjfont_8x8.iff"
		even

EGYPT_IFF:	incbin	"CAIRO.iff"
		even
	

END:		dc.b	"XXXXXXXXXXXXXX"
		even

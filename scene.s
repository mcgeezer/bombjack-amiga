
;
; DISPLAY_SCENE
; 
; In:
; 	a0 = Pointer to uncompressed .IFF file
;	
DISPLAY_SCENE:
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
	move.b	(a0)+,d0
	move.b	(a0)+,d0
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
	
	move.l	a2,a5

.copy:	move.w	d6,d1
	move.l	a5,a2
;	lea	LSTPTR_CURRENT_SCREEN,a2
	
; next line
	mulu	d4,d1
	lsl.w	#1,d1
	move.w	d0,d3		; set number of planes

.copybp:
	move.l	(a2)+,a1	; move in screen address
	add.l	d1,a1
	
	move.l	d4,d2
	subq.l	#1,d2

.lp:	move.w	(a0)+,d7	; copy in word from sprite
	move.w	d7,(a1)+	; copy word to screen plane <DISPLAY_BG>

	dbf	d2,.lp
	dbf	d3,.copybp
	
	addq.l	#1,d6		; next line
	dbf 	d5,.copy

.return:
	rts

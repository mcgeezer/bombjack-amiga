; Inputs 

; Joystick Return codes
JOY1_NO_MOVE:	equ	0
JOY1_UP:	equ	4
JOY1_DOWN:	equ	8
JOY1_LEFT:	equ	2
JOY1_RIGHT:	equ	1
JOY1_UP_LEFT:	equ	5
JOY1_UP_RIGHT:	equ	6
JOY1_DOWN_LEFT:	equ	9
JOY1_DOWN_RIGHT	equ	10
JOY1_FIRE:	equ	3

;
; JOYDETECT
;
; Joystick detect routine in port 1 	
;
; Out:
;	d3=Joystick direction code (see Constants)
;
JOYDETECT:	move.l	d0,-(a7)
		lea	$dff000,a6
		move.w	JOY1DAT(a6),d0
		moveq	#0,d3
		
		move.w	d0,d1			; check joystick down
		move.w	d0,d2
		lsr.w	#1,d2
		and.w	#1,d1
		and.w	#1,d2
		eor.w	d1,d2
		cmp.w	#1,d2
		beq.s	.down			
		
		move.w	d0,d1			; check joystick up
		lsr.w	#8,d1
		move.w	d1,d2
		lsr.w	#1,d2
		and.w	#1,d1
		and.w	#1,d2
		eor.w	d1,d2
		cmp.w	#1,d2
		beq.s	.up
		
.leftright:	btst	#1,d0
		bne.s	.left
		btst	#9,d0
		bne.s	.right
		
.standing:	clr.w	d1		; no movement
		bra.s	.exit
.left:		addq.w	#JOY1_LEFT,d3	; left = 2		
		bra.s	.exit
.right:		addq.w	#JOY1_RIGHT,d3	; right = 1
		bra.s	.exit
.up:		moveq	#JOY1_UP,d3	; up + right = 5	up=4
		bra.s	.leftright	; up + left  = 7
.down:		moveq	#JOY1_DOWN,d3	; down + right = 9	down=8
		bra.s	.leftright	; down + left  = 10
		nop
.exit:		move.l	(a7)+,d0
		rts






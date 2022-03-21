EXPTBL		equ	0fcc1h	; [4] MAIN ROM slot and expanded slot table

global		get_exptbl

; get_exptbl - Read the EXPTBL entry for a slot
; Input:	A	Slot number (0-3)
; Output:	A	EXPTBL entry for that slot
; 		C	Original value of A when entering this routine
; Modifies:	AF, HL, BC
;
get_exptbl:	ld	hl,EXPTBL
		ld	b,0
		ld	c,a
		add	hl,bc
		ld	a,(hl)
		ret


SLTTBL		equ	0fcc5h	; [4] Copy of expanded slot selection registers

global		get_slttbl

; get_slttbl - Read the SLTTBL entry for a slot
; Input:	A	Slot number (0-3)
; Output:	A	Copy of the expanded slot selection register for that
;			slot
;		C	Original value of A at entry to this routine
; Modifies:	AF, HL, BC
;
get_slttbl:	ld	hl,SLTTBL
		ld	b,0
		ld	c,a
		add	hl,bc
		ld	a,(hl)
		ret




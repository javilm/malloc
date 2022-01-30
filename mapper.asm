; mapper.as : Mapper support routines

		; Routines
		global	mapper_init		; Initialize the routines
		global	mapper_get_pslot	; Get main mapper slot address			global	mapper_get_table	; Get the address of the mapper
						; variables table

		; Copy of the jump table to MSX-DOS2 mapper support routines
		global	ALL_SEG
		global	FRE_SEG
		global	RD_SEG
		global	WR_SEG
		global	CAL_SEG
		global	CALLS
		global	PUT_PH
		global	GET_PH
		global	PUT_P0
		global	GET_P0
		global	PUT_P1
		global	GET_P1
		global	PUT_P2
		global	GET_P2
		global	PUT_P3
		global	GET_P3

		.z80

HOKVLD		equ	0fb20h
EXTBIO		equ	0ffcah

		cseg

mapper_init:	; Check for extended BIOS supoprt
		ld	a,(HOKVLD)
		and	000000001b
		jr	nz,map_init.1	; Z:  No extended BIOS detected
					; NZ: Extended BIOS detected
		
		; Return with C (error: no extended BIOS)
		scf
		ret

		; NZ
map_init.1:	; Get address of the mapper variables table via a call to
		; the extended BIOS
		xor	a		; A=0
		ld	de,00401h	; D=4, E=1
		call	EXTBIO
		ld	(pri_mapp_slt),a
		ld	(p_mapper_tbl),hl

		; Get the address of the mapper support routines and copy
		; the jump table
		xor	a		; A=0
		ld	de,00402h	; D=4, E=2
		call	EXTBIO
		; HL now contains the address of the jump table
		ld	de,ALL_SEG
		ld	bc,16*3
		ldir

		; Return with NC (no error)
		scf
		ccf

		ret

; map_get_pslot - Returns the slot address of the primary memory mapper.
; Input:	(none)
; Output:	A	Slot address of the primary mapper
; Notes:	Mapper support needs to be initialized by calling map_init.
;
mapper_get_pslot:
		ld	a,(pri_mapp_slt)
		ret

; map_get_table - Returns the address of the mapper variables table.
; Input:	(none)
; Output:	HL	Address of the mapper variables table.
; Notes:	Mapper support needs to be initialized by calling map_init.
;
mapper_get_table:
		ld	hl,(p_mapper_tbl)
		ret

; Copy of the jump table to the mapper support routines
ALL_SEG:	ret
		defs	2
FRE_SEG:	ret
		defs	2
RD_SEG:		ret
		defs	2
WR_SEG:		ret
		defs	2
CAL_SEG:	ret
		defs	2
CALLS:		ret
		defs	2
PUT_PH:		ret
		defs	2
GET_PH:		ret
		defs	2
PUT_P0:		ret
		defs	2
GET_P0:		ret
		defs	2
PUT_P1:		ret
		defs	2
GET_P1:		ret
		defs	2
PUT_P2:		ret
		defs	2
GET_P2:		ret
		defs	2
PUT_P3:		ret
		defs	2
GET_P3:		ret
		defs	2

		dseg

pri_mapp_slt:	defs	1	; Slot address of the primary mapper
p_mapper_tbl:	defs	2	; Pointer to the mapper variables table

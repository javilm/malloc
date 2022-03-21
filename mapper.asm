; MAPPER.ASM - Mapper support routines

; Include MSX-DOS2 support for slot and memory segment management
include	msxdos2.inc

; Routines
global	map_init	; Initialize the routines
global	map_g_pslot	; Get main mapper slot address
global	map_g_table	; Get the address of the mapper variables table
global	map_p2		; Map the segment of a mapped pointer into
			; the CPU's page 2
global	map_fill	; Fill the slot address and segment number in a partial
			; mpointer

; Externals
external get_exptbl	; Read the EXPTBL entry for a slot
external get_slttbl	; Read the SLTTBL entry for a slot

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
EXPTBL		equ	0fcc1h	; [4] MAIN ROM slot and expanded slot table
SLTTBL		equ	0fcc5h	; [4] Copy of expanded slot selection registers
EXTBIO		equ	0ffcah

; MAIN ROM routines
RSLREG		equ	00138h	; Read slot selection register

; MACRO: Execute a MAIN ROM routine (destroys IX and IX)
; See MSX Datapack Volume 2, page 15
mainrom		macro	address
		ld	iy,(EXPTBL-1)	; Slot address of MAIN ROM in IY MSB
		ld	ix,address	; Address to call in the MAIN ROM			call	CALSLT
		endm

		cseg

map_init:	; Check for extended BIOS supoprt
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

; map_g_pslot - Returns the slot address of the primary memory mapper.
; Input:	(none)
; Output:	A	Slot address of the primary mapper
; Notes:	Mapper support needs to be initialized by calling map_init.
;
map_g_pslot:
		ld	a,(pri_mapp_slt)
		ret

; map_g_table - Returns the address of the mapper variables table.
; Input:	(none)
; Output:	HL	Address of the mapper variables table.
; Notes:	Mapper support needs to be initialized by calling map_init.
;
map_g_table:
		ld	hl,(p_mapper_tbl)
		ret

; map_p2 - Map into the CPU's page 2 the memory mapper segment pointed to
; by a mapped pointer.
; Input:	HL	Pointer to the mapped pointer
; Output:	HL	Address portion of the mapped pointer, adjusted to
;			point to active memory in the CPU address space
; Modifies:	All

; 4-byte buffer to store a copy of the mapped pointer before switching slots
; and mapper segments, because it will disappear from the CPU address space if
; it is in the segment we are swithing. We reserve this space just before the
; routine in order ensure that the copy is always in page 0.
map_mptr:	defs	4 

map_p2:		; Make a copy of the mapped pointer
		; HL = pointer to the mapped pointer
		ld	de,map_mptr
		ld	bc,4
		ldir

		; Use IX to access elements of the mapped pointer
		ld	ix,map_mptr

		; Set high bits of HL to select page 2 (low 14 bits undefined)
		ld	a,010000000b
		ld	h,a		; HL: set CPU page 2
		ld	a,(ix+0)	; A: Slot address
		call	ENASLT

		; Select the segment
		ld	a,(ix+1)
		call	PUT_P2

		; Patch the address offset in the mapper pointer
		; to point to an address in page 2
		ld	a,(ix+3)
		and	000111111b	; Set two highest bits to 10
		or	010000000b
		ld	(ix+3),a

		; Load the address portion of the mapped pointer into HL
		ld	l,(ix+2)
		ld	h,(ix+3)

		ret

; map_fill - Takes an incomplete mpointer containing only an address,
; and fills the slot address and mapper segment for the currently active page
; in the CPU address space.
; Input:	IX	Pointer to the partial mpointer
; Output:	Slot address and segment number filled in the mpointer
;		structure
; Modifies:	A

map_fill:	; Compute the segment number for the address' page
		ld	a,(ix+3)
		and	011000000b
		ld	h,a
 		call	GET_PH
		ld	(ix+1),a

		; Pre-read the primary slot selection register and save the
		; value in B
;		push	ix	; mainrom overwrites both IX and IY
;		mainrom	RSLREG
		in	a,(0a8h)
		ld	b,a	; B = output from RSLREG
;		pop	ix

		; Compute the slot address for the address' page
		; First identify what CPU memory page the mpointer refers to
		ld	a,(ix+3)
		and	011000000b
		jr	z,map_fill_f0	; Address is in page 0
		cp	001000000b
		jr	z,map_fill_f1	; Address is in page 1
		cp	010000000b
		jr	z,map_fill_f2	; Address is in page 2
		; else address is in page 3

map_fill_f3:	; the mpointer is in page 3
		ld	a,b		; A = output from RSLREG
		and	011000000b

		; xx000000 -> 000000xx
		rlca
		rlca

		; Check whether the slot is expanded
		call	get_exptbl	; Input: A = slot number
		and	010000000b
		or	c		; C contains the previous value of A

		; Save partial slot address
		ld	(ix+0),a

		; Return if the slot is NOT expanded, else continue and compute
 		; the expanded slot number
		and	010000000b
		ret	z

		; Slot is expanded, compute the expanded slot number

		; Get the main slot number from the partial slot address
		ld	a,(ix+0)
		and	000000011b

		; Read the SLTTBL entry for this slot, keep value for page 3
		call	get_slttbl	; Input: A = slot number
		and	011000000b
		; Move expanded slot number to positions 4,3
		rlca
		rlca
		rlca
		rlca

		; OR the value with the current value of the slot address
		; byte and store the result
		or	(ix+0)
		ld	(ix+0),a

		ret

map_fill_f2:	; the mpointer is in page 2
		ld	a,b
		and	000110000b

		; 00xx0000 -> 000000xx
		rrca
		rrca
		rrca
		rrca

		; Check whether the slot is expanded
		call	get_exptbl
		and	010000000b
		or	c		; C was returned by get_exptbl

		; Save partial slot address (x000??pp)
		ld	(ix+0),a

		; If the slot was NOT expanded then we're done
		and	010000000b
		ret	z

		; The slot is expanded, compute expanded slot number
		ld	a,(ix+0)
		and	000000011b
		call	get_slttbl
		and	000110000b
		rrca	; 00xx0000 -> 0000xx00
		rrca

		; OR with the current value of the partial slot address
		; and save the result
		or	(ix+0)
		ld	(ix+0),a

		ret

map_fill_f1:	; the mpointer is in page 1
		ld	a,b
		and	000001100b

		; 0000xx00 -> 000000xx
		rrca
		rrca

		call	get_exptbl
		and	010000000b
		or	c

		ld	(ix+0),a	; x000??pp

		and	010000000b
		ret	z

		; Compute expanded slot number
		ld	a,(ix+0)
		and	000000011b
		call	get_slttbl
		and	000001100b
		; No need to shift, bits already in the right location
		or	(ix+0)
		ld	(ix+0),a

		ret

map_fill_f0:	; the mpointer is in page 0
		ld	a,b
		and	000000011b
		; No need to shift, bits in A are already in the position
		; required
		call	get_exptbl
		and	010000000b
		or	c
		ld	(ix+0),a	; x000??pp
		and	010000000b
		ret	z
		; Compute expanded slot number
		ld	a,(ix+0)
		and	000000011b
		call	get_slttbl
		and	000000011b
		; 000000xx -> 0000xx00
		rlca
		rlca
		or	(ix+0)
		ld	(ix+0),a

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

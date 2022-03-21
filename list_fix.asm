; LIST_FIX.ASM - Single-linked list implementation for elements of the same
; size

; The list structure requires 16 bytes in memory, plus 4+elem_size bytes
; per element.
;
; The struct has these fields:
;
; Name		Size		Description
; ====		====		===========
; length	2 bytes 	Number of elements in the list
; elem_size	2 bytes 	Size of the elements in the list
; ptr_first	4 bytes 	Mapped pointer to the first element
; ptr_last	4 bytes 	Mapped pointer to the last element
; ptr_next	4 bytes 	Mapped pointer to the next element

; Include mapper support
include		mapper.inc

STRUCT_SIZE	equ	16	; List struct size

	; Public routines
	public	flist_alloc	; Allocate and initialize a list structure
	public	flist_first	; Get pointer to first element
	public	flist_next	; Get pointer to next element and move next
				; pointer
	public	flist_last	; Get pointer to last element
	public	flist_rewind	; Rewind the list
	public	flist_length	; Return the number of elements
 	public	flist_add	; Add an element
	public	flist_delete	; Delete an element
	public	flist_get	; Get an element
	public	flist_swap	; Swap two elements
	public	flist_insert	; Insert an element
	public	flist_replace	; Replace an element

		.z80

		cseg

; flist_alloc - Allocate and initialize a list structure.
; Input:	HL	Pointer to a mapped pointer to a 16-byte area for the
;			list struct
;		BC	Size of the list elements, in bytes
; Output:	DE	Pointer to an mpointer to the list structure
; Modifies:	AB, HL, BC, DE
;
flist_init:	; Map the mapped pointer's segment into RAM and load the
		; patched pointer in HL
		;call	map_mptr_p2

		; XXX TO BE IMPLEMENTED

		ret

; Input:	HL	Pointer to a 16-byte area for the list struct
;		BC	Size of single list elements, in bytes
; Output:	List struct zeroed, and elem_size field set
; Modifies:	AF, HL, BC, DE
;
;flist_init:	; Zero the area holding the list struct
;		push	hl
;		push	bc
;		xor	a
;		ld	(hl),a
;		ld	d,h
;		ld	e,l
;		inc	de
;		ld	bc,STRUCT_SIZE-1
;		ldir
;		pop	bc
;		pop	hl

;		; Set the element size
;		ld	(hl),c
;		inc	hl
;		ld	(hl),b

;		ret

; flist_first - Return pointer to the first element in the list
; Input:	HL	Mapped pointer to the list structure
; Output:	DE	

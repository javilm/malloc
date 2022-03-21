; malloc.asm - Manage free/allocated memory.

; This routine maintains a list of free memory blocks in the system's memory
; mappers. To do so, it requests memory from the operating system when
; requested by the calling application, and frees that memory when the calling
; application indicates that it no longer requires that memory.
;
; All requests to the operating system are in 16KB increments because MSX-DOS2
; only allows allocating and freeing 16KB segments in the memory mapper.
;
; Internally, this routine maintains two lists of memory blocks: a list of free
; blocks in each of the segments requested to the operating system, and a list
; of used blocks in those same segments. This routine starts with both lists
; empty, and it requests and frees segments on the fly when they are needed or
; when they're not in use anymore.

		include	mapper.inc	; Mapper support routines
		include	msxdos2.inc	; MSX-DOS2 support

		; Public routines
		public	malloc		; Allocates BC bytes
		public	malloc_init	; Initialize malloc routines
		public	mfree		; Frees the allocation pointed by IX

		; External symbols
		external runend		; Address immediately after the end
					; of this program
		external get_slttbl	; Read the SLTTBL entry for a slot
		external get_exptbl	; Read the EXPTBL entry for a slot

		.z80

; System variables
EXPTBL		equ	0fcc1h	; [4] MAIN ROM slot and expanded slot table
SLTTBL		equ	0fcc5h	; [4] Copy of expanded slot selection registers

; Use the command line buffer in the system scratch area as a temporary space
; to build mapped pointers.
;
; Format of a mapped pointer:
;
; Byte 0: Slot address of the memory mapper
; Byte 1: Segment number inside the memory mapper
; Bytes 2-3: Memory address relative to the start of the segment (0-3fffh)
;
mpointer	equ	00080h

; ***********************
; *** PUBLIC ROUTINES ***
; ***********************

; malloc - Allocate a block of size BC (up to 14 bits)
;
; Input:	BC	Number of bytes requested by the application
; Output:	IX	Pointer to mapped pointer to the memory, if allocated
;		A	0 if allocation successful
;			1 if the allocation failed. In this case, IX
;			doesn't hold meaningful value.
; Modifies:	AF, BC, HL
;
		cseg

malloc:		ret

; mfree - Free a memory block pointed by IX
;
		cseg

mfree:		ret

; malloc_init - Initialize malloc routines
;
; This routine computes how much space is available between the end of the 
; program (defined by the runend symbol in the runtime) and the top of the TPA.
; The top of the TPA is the memory address immediately below the start of the 
; resident part of MSXDOS(2).SYS, which is pointed by memory address 00006h
; (the entry point to BDOS). See MSX Datapack Vol. 1, page 400.

		cseg

malloc_init:	call	save_newtpa	; Compute new TPA value
		call	init_free	; Initialize the list of free blocks
		call	init_used	; Initialize the list of used blocks

		; Step 1: Is runend below 04000h?
		ld	hl,runend-1
		ld	de,04000h
		or	a		; Prepare 16-bit substraction/compare
		sbc	hl,de		; NC: HL >= DE; C: HL < DE
		jp	c,malloc_init_p0 ; The program ends in page 0

		; Step 2: Is runend below 08000h?
		ld	hl,runend-1
		ld	de,08000h
		or	a
		sbc	hl,de
		jp	c,malloc_init_p1 ; The program ends in page 1

		; Step 3: Is runend below 0c000h?
		ld	hl,runend-1
		ld	de,0c000h
		or	a
		sbc	hl,de
		jp	c,malloc_init_p2 ; The program ends in page 2

		; If we reach this point, the program ends in page 3
		jp	malloc_init_p3

		dseg

newtpa:		defs	2	; Top of the TPA minus STACKBUF bytes to let
				; the stack grow


; ************************
; *** SUPPORT ROUTINES ***
; ************************

; save_newtpa - Save the address of the TPA - 1 - STACKBUF

		cseg

STACKBUF	equ	1024	; Leave STACKBUF bytes between the top of the
				; TPA and the end of the highest free memory
				; block, in order to allow the stack to grow.

save_newtpa:	; Read the pointer to BDOS and decrease by one memory address
		; in order to point to the end of the TPA, and not to the start
		; of the resident part of MSXDOS(2).SYS
		ld	hl,(BDOS+1)
		dec	hl

		; Load the STACKBUF constant in DE for the substraction
		ld	de,STACKBUF

		; Ensure the carry flag is not set
		or	a

		; Compute and store the new TPA value
		sbc	hl,de
		ld	(newtpa),hl

		ret

; init_free - Initialize the list of free blocks

		cseg

init_free:	ret

; init_used - Initialize the list of used blocks

		cseg

init_used:	ret

; malloc_init_p[0123] - Add memory blocks in pages 0-3 to the list of free
; blocks

malloc_init_p0:	call	make_entry_p0
		; call	add_free	; XXX this needs to be implemented

		; Prepare the next block
		ld	hl,16384
malloc_init_p1:	call	make_entry_p1
		; call	add_free	; XXX to be implemented

		; Prepare the next block
		ld	hl,16384
malloc_init_p2:	call	make_entry_p2
		; call	add_free	; XXX to be implemented

		; Prepare the next block
malloc_init_p3:	; XXX Here we need to find the size of the final block
		; and leave the value in HL before calling make_entry_p3
		call	make_entry_p3
		; call	add_free	; XXX to be implemented

		ret

; make_entry_p[0123] - Construct a list entry describing a block of free memory
; in pages 0, 1, 2 or 3. The entry consists in a mapped pointer to the start of
; the memory block, followed by the size of the memory block:
;
; Byte 0   : Slot address of the mapper
; Byte 1   : Segment number inside the mapper
; Bytes 2-3: Memory offset to the start of the block
; Bytes 4-5: Size of the memory block
;
; This entry will be fed to the list management routine to add to the list.

; Each one of these routines performs the same computation, for each of the
; different pages of the CPU address space. The process is as follows:
;
; 1) Get the slot address of the mapper in page X by calling the MAIN ROM
;    routine RSLREG.
; 2) Visit the EXPTBL entry for the slot to check whether it is expanded. At
;    this point we can OR bit 7 of the EXPTBL entry and the primary slot number
;    and store this value in byte 0 of the entry.
; 3) If bit 7 of the slot address is 1, then the slot is expanded and we need
;    to visit SLTTBL to compute the expanded slot number for that page, then
;    OR this value on the expanded slot bits of the entry.

; Input:	HL	Contains the size of the free memory block in the page

make_entry_p0:	; 1) Save the block size
		ld	(mpointer+4),hl

		; 2) Save the slot address for page 0
		call	save_sltadd_p0

		; 3) Save the memory mapper segment number for page 0
		xor	a
		call	get_segment	; Get the mapper segment for page 0
		ld	(mpointer+1),a

		; 4) Save the offset to the start of the block (runend)
		ld	hl,runend
		ld	(mpointer+2),a

		ret

make_entry_p1:	ld	(mpointer+4),hl		; Save the block size
		call	save_sltadd_p1		; Save the slot address

		; 3) Save the memory mapper segment number for page 1
		ld	a,1
		call	get_segment
		ld	(mpointer+1),a

		; 4) Save the offset to the start of the block (runend). Need
		; to ensure that the top two bits of the address will be 0 so
		; the offset will point to the relative address inside the
		; mapper segment, not the absolute address inside the mapped
		; CPU address space.
		ld	hl,runend
		ld	a,h
		and	000111111b
		ld	h,a
		ld	(mpointer+2),a

		ret

make_entry_p2:	ld	(mpointer+4),hl		; Save the block size
		call	save_sltadd_p2		; Save the slot address

		; 3) Save the memory mapper segment number for page 2
		ld	a,2
		call	get_segment
		ld	(mpointer+1),a

		; 4) Save the offset to the start of the block (runend). Ensure
		; that the two most significant bits of the 16-bit address are 
		; set to 0.
		ld	hl,runend
		ld	a,h
		and	000111111b
		ld	h,a
		ld	(mpointer+2),a

		ret
		
make_entry_p3:	ld	(mpointer+4),hl	; Save the block size
		call	save_sltadd_p3	; Save the slot address

		ld	a,3		; Save the mapper segment number
		call	get_segment
		ld	(mpointer+1),a

		ld	hl,runend	; Save the offset to the block start
		ld	a,h
		and	000111111b
		ld	h,a
		ld	(mpointer+2),a

		ret

; save_sltadd_p[0123] - Get the slot address for the mapper segment active in
; pages 0-3 and save it to (mpointer).
; Note that each page will use a slightly different code because the
; bits for each page are in different positions. Rather than use a single
; routine behaving differently depending on the page number, it's simpler and
; similar in size to write four different routines.
;
; Input:	none
; Output:	The first byte of the mpointer entry is populated with the
;		slot address for the page.

save_sltadd_p0:	; Read main slot selection register and keep value for page 0
		in	a,(0a8h)
		and	000000011b

		; Check whether the slot is expanded
		call	get_exptbl
		and	010000000b	; Keep only bit 7
		or	c		; OR the primary slot in bits 0-1

		; Save the partial slot address. If the slot is not expanded
		; then this value is already correct and no more processing is
		; needed
		ld	(mpointer),a

		; Return if the slot is not expanded, else continue and
		; compute the expanded slot number.
		and	010000000b
		ret	z

		; Compute the expanded slot number for page 0

		; Get the main slot number from the partial slot address
		ld	a,(mpointer)
		and	000000011b

		; Read the entry in SLTTBL for this slot
		call	get_slttbl

		; Keep only the expanded slot number of page 0
		and	000000011b

		; Shift the value to the position of the expanded slot number
		; in the slot address byte
		sla	a
		sla	a

		; OR the value with the current value of the slot address byte
		; and store the result
		ld	hl,mpointer
		or	(hl)
		ld	(hl),a

		ret

save_sltadd_p1:	; Read main slot selection register and keep value for page 1
		in	a,(0a8h)
		and	000001100b
		rrca
		rrca

		; Check whether the slot is expanded
		call	get_exptbl
		and	010000000b
		or	c

		; Save the partial slot address.
		ld	(mpointer),a

		; Return if the slot is not expanded, else continue and
		; compute the expanded slot number.
		and	010000000b
		ret	z

		; Compute the expanded slot number for page 1

		; Get the main slot number from the partial slot address
		ld	a,(mpointer)
		and	000000011b

		; Read the entry in SLTTBL for this slot and keep the entry
		; for page 1
		call	get_slttbl
		and	000001100b

		; OR the value with the current value of the slot address byte
		; and store the result
		ld	hl,mpointer
		or	(hl)
		ld	(hl),a

		ret

save_sltadd_p2:	; Read main slot selection register and keep value for page 2
		in	a,(0a8h)
		and	000110000b
		rrca
		rrca
		rrca
		rrca

		; Check whether the slot is expanded
		call	get_exptbl
		and	010000000b
		or	c

		; Save the partial slot address
		ld	(mpointer),a

		; Return if the slot is expanded, else continue
		and	010000000b
		ret	z

		; Compute expanded slot number for page 2

		; Get the main slot number from the partial slot address
		ld	a,(mpointer)
		and	000000011b

		; Read the entry in SLTTBL for this slot and keep the entry
		; for page 2
		call	get_slttbl
		and	000110000b
		rlca			; Ensure the expanded slot number is in
		rlca			; bits 3-4

		; OR the value with the current value of the slot address byte
		; and store the result
		ld	hl,mpointer
		or	(hl)
		ld	(hl),a

		ret

save_sltadd_p3:	; Read main slot selection register and keep value for page 3
		in	a,(0a8h)
		and	011000000b
		rlca
		rlca

		; Check whether the slot is expanded
		call	get_exptbl
		and	010000000b
		or	c

		; Save the partial slot address
		ld	(mpointer),a

		; Return if the slot is expanded, else continue
		and	010000000b
		ret	z

		; Compute expanded slot number for page 3

		; Get the main slot number from the partial slot address
		ld	a,(mpointer)
		and	000000011b

		; Read the entry in SLTTBL for this slot and keep the data for
		; page 3
		call	get_slttbl
		and	011000000b
		; Ensure the expanded slot number is in bits 3-4
		rlca
		rlca
		rlca
		rlca

		; OR the value with the current value of the slot address byte
		; and store the result
		ld	hl,mpointer
		or	(hl)
		ld	(hl),a

		ret

; get_segment - Get the active memory mapper segment for pages 0-3
; Input:	A	CPU memory page number (0-3)
; Output:	A	Memory mapper segment number for that page (0-255)
; Modifies:	AF, HL, BC
;
get_segment:	and	000000011b	; Ensure that A is 0-3
		rrca			; Shift A so the page number is
		rrca			; in bits 6-7
		ld	h,a
		call	GET_PH
		ret
	ld	hl,mpointer
		or	(hl)
		ld	(hl),a

		ret

; get_segment - Get the active memory mapper segment for pages 0-3
; Input:	A	CPU memory page number (0-3)
; Output:	A	Memory mapper segment number for that page (0-255)
; Modifies:	AF, HL, BC
;
get_segment:	and	000000011b	; Ensure that A is 0-3
		rrca			; Shift A so the page number is
		rrca			; in bits 6-7
		ld	h,a
		call	GET_PH
		ret
	C	Original value of A when this routine was called
; Modifies:	AF, HL, BC
;
get_exptbl:	ld	hl,EXPTBL
		ld	b,0
		ld	c,a
		add	hl,bc
		ld	a,(hl)
		ret

A	Slot number (0-3)
; Output:	A	Copy of the expanded slot selection register for that
;			slot
;		C	Original value of A when this routine was called
; Modifies:	AF, HL, BC
;
get_slttbl:	ld	hl,SLTTBL
		ld	b,0
		ld	c,a
		add	hl,bc
		ld	a,(hl)
		ret
build the
				; mapped pointer
temporary space to build the
				; mapped pointer
ped pointer

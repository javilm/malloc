; Mapper support
external	map_init	; Initialize the mapper routines
external	map_g_pslot	; Get primary mapper slot address
external	map_g_table	; Get address of mapper variables table
external	map_p2		; Map the segment of a mapped pointer in
				; the CPU's page 2
external	map_fill	; Fill the slot address and segment number in
				; a partial mpointer

; Copy of the MSX-DOS2 mapper support routines
external	ALL_SEG
external	FRE_SEG
external	RD_SEG
external	WR_SEG
external	CAL_SEG
external	CALLS
external	PUT_PH
external	GET_PH
external	PUT_P0
external	GET_P0
external	PUT_P1
external	GET_P1
external	PUT_P2
external	GET_P2
external	PUT_P3
external	GET_P3

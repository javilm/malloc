; MSXDOS(2).SYS entry point
BDOS		equ	00005h

; MSX-DOS2 inter-slot calls
RDSLT		equ	0000ch	; Read address from specified slot
WRSLT		equ	00014h	; Write value to address in specified slot
CALSLT		equ	0001ch	; Call address in the specified slot
ENASLT		equ	00024h	; Enable the specified slot
CALLF		equ	00030h	; Call address in the specified slot

; MACRO: Execute an MSX-DOS(2) function call
system		macro	func
		ld	c,func
		call	BDOS
		endm

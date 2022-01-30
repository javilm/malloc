; RUNSTART.ASM[REL]

; This code is assembled as a relocatable library and linked at the beginning
; of the program using it. It works with the companion file RUNEND.ASM[REL],
; which has to be linked at the end of the binary.

; Together, these perform initialization tasks for the memory allocator code
; and then jump to the program's entry point, defined as the "main" global
; symbol.

		.z80

		org	00100h

		external runend		; Address of the end of the program
		external mapper_init	; Mapper support initialization
		external malloc_init	; Initialize malloc
		external main		; Entry point to the program

		cseg

runstart:	call	mapper_init	; Initialize the mapper support
		call	malloc_init	; Initialize the malloc routine
		jp	main

		defb	"Runtime v0.1/20220126",13,10


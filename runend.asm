; RUNEND.ASM[REL]

; This code has to be assembled as a relocatable library and linked at the end
; of the binary using this runtime. It marks the first address after the
; application's code, and it's used by the memory allocation routines.

		.z80

		cseg

		global	runend

runend:

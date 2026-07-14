section .text
global print_dec

print_dec:
	;save all those registers first
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi

	lea		edi, [dec_buffer + 11]	;edi points to end of the buffer
	mov		byte[edi], 0			;write \0 at end of buffer
	dec		edi						;decrease by 1
	test	eax, eax				;check if zero
	jnz		.convert				;non-zero, else handle zero

	mov		byte[edi], '0'	;0
	mov		esi, edi		;copy edi into my esi
	call	terminal_putstr	;write esi content on the screen
	jmp		.done			;finished

.convert:
	mov		ebx, 10

.loop:
	xor		edx, edx	;
	div		ebx			;divide ebx
	add		dl, '0'
	mov		[edi], dl
	dec		edi

	test	eax, eax	;contains quotient, continue until this is 0
	jnz		.loop		;loop again if non-zero

	inc		edi
	mov		esi, edi		;gets it ready to be written on terminal
	call	terminal_putstr	;writes string in esi

.done:
	pop		esi
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	ret
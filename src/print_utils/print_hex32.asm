section .text
global print_hex32

print_hex32:
	;save registers first
	push	ebx
	push	ecx
	push	edx
	push	eax

	;print "0x"
	mov		al, '0'
	call	terminal_putchar
	mov		al, 'x'
	call	terminal_putchar

	pop		edx		;restore original value into edx
	mov		ecx, 8	;print 8 nibbles, highest first

.hex_loop:
	mov		eax, edx			;load edx into my eax
	shr		eax, 28				;shift 28 bits to the right to get the highest nibble of edx
	call	print_hex_digit		;convert nibble to ascii
	call	terminal_putchar	;print it
	shl		edx, 4				;shift edx 4 bits to the left, so next nibble becomes highest
	loop	.hex_loop			;loop

	;restore registers
	pop		edx
	pop		ecx
	pop		ebx
	ret

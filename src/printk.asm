section .text
global printk

printk:
	push	ebp
	mov		ebp, esp
	push	ebx			;callee-saved
	push	esi			;callee-saved

	mov		esi, [ebp+8]	;load format string pointer into esi
	lea		ebx, [ebp+12]	;ebx = pointer to first variadic arg on the stack

.next:
	lodsb				;al = *esi++
	test	al, al		;on null terminator
	jz		.done
	cmp		al, '%'		;format specifier
	je		.format
	call	terminal_putchar
	jmp		.next

.format:
	lodsb				;al = char after '%'
	cmp		al, 'c'
	je		.char
	cmp		al, 's'
	je		.str
	cmp		al, 'd'
	je		.dec
	cmp		al, 'x'
	je		.hex
	call	terminal_putchar	;unknown specifier, just print the character
	jmp		.next

.char:
	mov		al, [ebx]	;char arg
	add		ebx, 4		;advance arg pointer to next arg
	call	terminal_putchar
	jmp		.next

.str:
	push	esi			;save format string ptr (terminal_putstr uses lodsb = esi)
	mov		esi, [ebx]	;string arg pointer
	add		ebx, 4		;advance arg pointer
	call	terminal_putstr
	pop		esi			;restore format string ptr
	jmp		.next

.dec:
	mov		eax, [ebx]	;int arg (eax) for print_dec
	add		ebx, 4
	call	print_dec
	jmp		.next

.hex:
	mov		eax, [ebx]	;int arg (eax) for print_hex32
	add		ebx, 4
	call	print_hex32
	jmp		.next

.done:
	pop		esi
	pop		ebx
	pop		ebp
	ret
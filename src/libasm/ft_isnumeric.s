global	ft_isnumeric

section .text
ft_isnumeric:
	; edi = int c

	mov		eax, 0
	cmp		edi, '0'
	jl		.false
	cmp		edi, '9'
	jle		.true
	jmp		.false

.false:
	ret

.true:
	mov		eax, 1
	ret

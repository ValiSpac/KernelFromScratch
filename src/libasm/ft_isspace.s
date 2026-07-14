global	ft_isspace

section .text
ft_isspace:
	; edi = int c

	mov		eax, 0
	cmp		edi, ' '
	je		.true 
	cmp		edi, 9
	jl		.false
	cmp		edi, 13
	jle		.true
	jmp		.false

.false:
	ret

.true:
	mov		eax, 1
	ret

global	ft_isalpha

section .text
ft_isalpha:
	; edi = int c

	mov		eax, 0
	cmp		edi, 'a'
	jl		.check_upper
	cmp		edi, 'z'
	jle		.true

.check_upper:
	cmp		edi, 'A'
	jl		.false
	cmp		edi, 'Z'
	jle		.true
	jmp		.false

.false:
	ret

.true:
	mov		eax, 1
	ret

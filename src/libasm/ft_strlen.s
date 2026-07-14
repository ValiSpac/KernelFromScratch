global	ft_strlen

section .text
ft_strlen:
	;edi	= const char *s
	xor		eax, eax

.loop:
	cmp		byte[edi + eax], 0
	je		.done
	inc		eax
	jmp		.loop

.done:
	ret

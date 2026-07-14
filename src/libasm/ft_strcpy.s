global	ft_strcpy

section	.text
ft_strcpy:
	;edi	= char *dst
	;esi	= const char *src
	xor		ecx, ecx
	mov		eax, edi

.loop:
	mov		dl, byte[esi + ecx]
	mov		byte[edi + ecx], dl
	cmp		dl, 0
	je		.done
	inc		ecx
	jmp		.loop

.done:
	ret

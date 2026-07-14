global	ft_strcmp

section	.text
ft_strcmp:
	push	ebp
	mov		ebp, esp
	push	esi
	push	edi			 ; CALLING CONVENTION so we dont have to reset regs after each run

	mov	 edi, [ebp + 8]
	mov	 esi, [ebp + 12]
	xor		ecx, ecx

.loop:
	movzx	eax, byte[edi + ecx]
	movzx	edx, byte[esi + ecx]
	cmp		eax, edx
	jne		.done
	test	al, al ; checks if we hit \0
	je		.done
	inc		ecx
	jmp		.loop

.done:
	sub		eax, edx
	pop		edi
	pop		esi
	pop		ebp
	ret

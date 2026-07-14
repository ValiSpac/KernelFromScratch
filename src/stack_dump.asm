%define	MAX_FRAMES	32
%define	RAW_WORDS	8

section	.text
global	stack_dump

stack_dump:
	push		ebx	;save ebx register
	push		esi	;save esi register
	push		edi	;save edi register
	push		edx	;save edx register
	push		ecx	;save ecx register

	mov			ebx, ebp	;move the stack pointer into ebx
	mov			esi, esp	;move the base pointer into esi

	push		ebx	;capture ebp
	push		esi	;capture esp

	push dword	msg_stkdmp_stk	;push string into stack

	call		printk	;print the stack string
	add			esp, 12	;clear the elements from the stack

	xor		ecx, ecx	;set to 0 for frameloop
	xor		edi, edi	;set to 0 for rawloop

.frame_loop:
	cmp		ecx, MAX_FRAMES	;stop on MAX_FRAMES dword
	jae		.done

	test	ebx, ebx	;if base pointer is null
	jz		.done

	test	ebx, 3		;if ebp_cur not 4bit aligned
	jnz		.done

	cmp		edi, 0			;compare safecheck result
	je		.print_frame	;start print for curr frame

	cmp		ebx, edi	;if our inc falls back to a previous frame
	jbe		.done

.print_frame:
	mov		edx, [ebx]		;prev
	mov		esi, [ebx + 4]	;ret

	push	edi			;capture prev
	push	esi			;capture ret
	push	ebx			;capture curr
	push	ecx	;push frame count

	push dword	msg_stkdmp_frm

	call	printk	;print my frame line
	add		esp, 20	;clear the elements from the stack

	xor		esi, esi	;raw word index

.raw_loop:
	cmp		esi, RAW_WORDS	;reach end of frame
	jae		.next

	push	dword [ebx + esi*4]	;capture esp+j*4
	push	esi					;push counter

	push dword	msg_stkdmp_raw

	call		printk	;print my raw line
	add			esp, 12	;clear the elements from the stack

	inc		esi			;increase counter
	jmp		.raw_loop	;keep looping

.next:
	mov		edi, ebx	;old ebp becomes prev
	mov		ebx, [ebx]	;follow frame chain
	inc		ecx			;increase counter
	jmp		.frame_loop	;keep looping

.done:
	pop		ecx	;recover ecx reg
	pop		edx	;recover edx register
	pop		edi	;recover edi reg
	pop		esi	;recover esi reg
	pop		ebx	;recover ebx reg
	ret

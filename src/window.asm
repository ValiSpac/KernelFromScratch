section .text
global window_switch
global save_screen
global load_screen

window_switch:
	push	ebx
	movzx	ebx, al		;save target screen index across calls

	call	save_screen	;save VGA buffer and cursor for [curr_screen]

	mov		dword[curr_screen], ebx	;update to new screen
	mov		eax, ebx				;put screen index in eax for load_screen
	call	load_screen				;load new screen buffer to VGA and restore cursor

	movzx	eax, byte[screen_colors + ebx]
	test	al, al	;0 = fall back to default
	jnz		.apply_color
	mov		al, VGA_DEFAULT_COLOR

.apply_color:
	call	terminal_set_color

	pop		ebx
	ret


save_screen:
	push	esi
	push	edi
	push	ecx
	push	eax

	mov		eax, [curr_screen]	;buffer_addr = screen0_buffer + curr_screen * VGA_CELLS * 2
	imul	eax, VGA_CELLS * 2	;byte offset into the buffer array
	add		eax, screen0_buffer	;absolute address of this screen's buffer
	mov		edi, eax			;edi = destination (screen buffer)
	mov		esi, VGA_ADDRESS	;esi = source (live VGA framebuffer)
	mov		ecx, VGA_CELLS		;number of words
	cld							;ensure forward direction (DF=0)
	rep		movsw				;copy ecx words [esi] => [edi]

	mov		ecx, [curr_screen]
	mov		eax, [cursor_row]			;current live row
	mov		[screen_row + ecx*4], eax	;save into this screen's slot
	mov		eax, [cursor_col]			;current live col
	mov		[screen_col + ecx*4], eax	;save into this screen's slot

	pop		eax
	pop		ecx
	pop		edi
	pop		esi
	ret


load_screen:
	push	esi
	push	edi
	push	ecx

	imul	eax, VGA_CELLS * 2	;buffer_addr = screen0_buffer + eax * VGA_CELLS * 2
	add		eax, screen0_buffer
	mov		esi, eax			;esi = source (screen buffer)
	mov		edi, VGA_ADDRESS	;edi = destination (live VGA framebuffer)
	mov		ecx, VGA_CELLS
	cld
	rep		movsw				;blit buffer into VGA

	mov		ecx, [curr_screen]
	mov		eax, [screen_row + ecx*4]
	mov		[cursor_row], eax
	mov		eax, [screen_col + ecx*4]
	mov		[cursor_col], eax

	call	update_cursor		;sync hardware cursor after screen switch

	pop		ecx
	pop		edi
	pop		esi
	ret

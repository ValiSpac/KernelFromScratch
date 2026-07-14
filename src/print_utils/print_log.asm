section .text
global print_info
global print_ok
global print_err

print_info:
	push	esi							;save esi register
	mov		al,	VGA_COLOR_LIGHT_CYAN	;foreground colour
	mov		ah,	VGA_COLOR_BLACK			;background colour
	call	vga_make_color				;create colour
	call	terminal_set_color			;use colour
	mov		esi, prefix_info			;load prefix for this level of log
	call	terminal_putstr				;write prefix
	call	terminal_set_color_default	;default colour for the message
	pop		esi							;load existing data
	call	terminal_putstr				;write the data
	mov		al, 10						;load '\n'
	call	terminal_putchar			;write the newline
	ret


print_ok:
	push	esi							;save esi register
	mov		al,	VGA_COLOR_LIGHT_GREEN	;foreground colour
	mov		ah,	VGA_COLOR_BLACK			;background colour
	call	vga_make_color				;create colour
	call	terminal_set_color			;use colour
	mov		esi, prefix_ok				;load prefix for this level of log
	call	terminal_putstr				;write prefix
	call	terminal_set_color_default	;default colour for the message
	pop		esi							;load existing data
	call	terminal_putstr				;write the data
	mov		al, 10						;load '\n'
	call	terminal_putchar			;write the newline
	ret


print_err:
	push	esi							;save esi register
	mov		al,	VGA_COLOR_LIGHT_RED		;foreground colour
	mov		ah,	VGA_COLOR_BLACK			;background colour
	call	vga_make_color				;create colour
	call	terminal_set_color			;use colour
	mov		esi, prefix_err				;load prefix for this level of log
	call	terminal_putstr				;write prefix
	call	terminal_set_color_default	;default colour for the message
	pop		esi							;load existing data
	call	terminal_putstr				;write the data
	mov		al, 10						;load '\n'
	call	terminal_putchar			;write the newline
	ret

section .text
global terminal_clear
global terminal_putstr
global terminal_putchar
global terminal_scroll
global update_cursor


terminal_clear:
	mov		edi, VGA_ADDRESS		;moves edi back to the start of the vga address
	mov		al, ' '					;uses space ascii as lowerbits to clear
	mov		ah, [screen_color]		;use default terminal colattr for backgroundcolour

	mov		ecx, VGA_WIDTH * VGA_HEIGHT	;compute how many cells total are in the [COLS*ROWS] of the terminal

.clear_loop:
	mov		[edi], ax	;write the 16bit vga cell
	add		edi, 2		;advance to next cell
	loop	.clear_loop	;loops

	mov dword	[cursor_row], 0	;resets cursor position to top
	mov dword	[cursor_col], 0	;resets cursor position to left
	call		update_cursor	;sync hardware cursor
	ret


terminal_putstr:
.next_char:
	lodsb	;loads one byte from esi
	test	al, al	;if al == 0 then we reached the end (\0)
	jz		.done

	call	terminal_putchar	;prints 1 character
	jmp		.next_char			;go to next character

.done:
	ret


terminal_putchar:
	push	esi		;retain esi and edi reg in case of scroll for printk
	push	edi
	cmp		al, 10		;special case for '\n'
	je		.newline
	cmp		al, 8		;special case for backspace
	je		.backspace

	push	eax					;save character (al) before address calculation

	mov		eax, [cursor_row]	;load current row number
	imul	eax, VGA_WIDTH		;in place mult with maxwidth
	add		eax, [cursor_col]	;add column to get specific cell position
	shl		eax, 1				;position = index * 2 (each VGA cell is 2 bytes)
	add		eax, VGA_ADDRESS	;add base VGA address
	mov		edi, eax			;store computed address in edi

	pop		eax					;restore character in al
	mov		ah, [screen_color]	;use current colattr
	mov		[edi], ax			;write cell to video memory

	inc dword	[cursor_col]	;move next col

	mov		eax, [cursor_col]	;load current col position
	cmp		eax, VGA_WIDTH		;compare with max width
	jl		.check_scroll		;if lower check scroll, else .newline

.newline:
	mov dword	[cursor_col], 0	;move cursor back to left
	inc dword	[cursor_row]	;go to next row

.check_scroll:
	mov		eax, [cursor_row]	;load current row
	cmp		eax, VGA_HEIGHT		;compare with max height
	jl		.done				;if lower then we dont scroll

	call	terminal_scroll		;else scrollup one line
	mov		dword [cursor_row], VGA_HEIGHT - 1 ;set ROW in putchar
	;cursor_col is already 0 from the .newline
	jmp		.done

.done:
	call	update_cursor		;sync hardware cursor
	pop		edi	;restore esi and edi reg in case of scroll for printk
	pop		esi
	ret


.backspace:
	mov		eax, [cursor_col]	;load current column
	test	eax, eax			;check if col == 0
	jz		.done		;if at start of line, stop

	dec dword	[cursor_col]	;move cursor back one column
	jmp		.erase_char			;erase the character at the new position

.back_prev_row:
	mov		eax, [cursor_row]	;load current row
	test	eax, eax			;check if row == 0
	jz		.done				;already at top-left, nothing to do

	dec dword	[cursor_row]				;move up one row
	mov dword	[cursor_col], VGA_WIDTH - 1	;move to end of previous row

.erase_char:
	mov		eax, [cursor_row]
	imul	eax, VGA_WIDTH
	add		eax, [cursor_col]
	shl		eax, 1
	add		eax, VGA_ADDRESS
	mov		edi, eax

	mov		ah, [screen_color]
	mov		al, ' '				;replace with space
	mov		[edi], ax
	jmp		.done				;update cursor and return


terminal_scroll:
	push	esi
	push	edi
	mov		esi, VGA_ADDRESS + (VGA_WIDTH * 2)	;row 1
	mov		edi, VGA_ADDRESS					;row 0
	mov		ecx, VGA_WIDTH * (VGA_HEIGHT - 1)	;compute cells to copy

.copy_loop:
	mov		ax, [esi]	;copy 16bit vga cell
	mov		[edi], ax	;place that into the edi
	add		esi, 2		;increment esi to next cell
	add		edi, 2		;increment edi to next cell
	loop	.copy_loop	;loop until done

	mov		al, ' '				;load space in lower bits
	mov		ah, [screen_color]	;load default colattr into higher bits
	mov		ecx, VGA_WIDTH

.clear_last_row:
	mov		[edi], ax		;current char in edi cell
	add		edi, 2			;increment edi to next cell
	loop	.clear_last_row	;loop until entire row cleared
	pop		edi
	pop		esi
;	mov dword	[cursor_row], VGA_HEIGHT - 1	;moves cursor to final row
;	mov dword	[cursor_col], 0					;move cursor to beginning of col
	ret


update_cursor:
	;save registers
	push	eax
	push	ebx
	push	edx

	mov		eax, [cursor_row]	;compute linear position (curr row * width + col)
	imul	eax, VGA_WIDTH		;inplace mult
	add		eax, [cursor_col]	;add col
	mov		ebx, eax			;move cursor position in ebx

	mov		dx, 0x3D4			;VGA index register
	mov		al, 0x0E			;select cursor high byte register
	out		dx, al				;extract val out of accumulator
	mov		dx, 0x3D5			;VGA data register
	mov		al, bh				;high byte of position
	out		dx, al				;extract val out of accumulator

	mov		dx, 0x3D4			;VGA index reg
	mov		al, 0x0F			;select cursor low byte register
	out		dx, al				;extract val out of accumulator
	mov		dx, 0x3D5			;VGA data reg
	mov		al, bl				;low byte of position
	out		dx, al				;extract val out of accumulator

	;pop back from stack saved values
	pop		edx
	pop		ebx
	pop		eax
	ret

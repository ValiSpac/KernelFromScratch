%define TEST_PRINTK	"%d"

section .bss
shift_state	resb 1	;1 if shift is held
caps_state	resb 1	;1 if capslock is toggled on
ext_pending	resb 1	;1 if previous byte was the 0xE0 extended prefix


section .text
global keyboard_has_data
global keyboard_poll
global keyboard_read_scancode


inb:
	in		al, dx	;i/o port byte copy
	ret


keyboard_has_data:
	mov		dx, PS2_STATUS_PORT	;load ps2 port
	call	inb					;reads byte from i/o port into al
	and		al, 1	;test bit 0
	ret


keyboard_read_scancode:
	mov		dx, PS2_DATA_PORT	;load ps2 port
	call	inb					;call access to port
	ret


keyboard_poll:
	call	keyboard_has_data
	test	al, al
	jz		.done

	call	keyboard_read_scancode	;read byte from controller output buffer

	cmp		al, 0xE0		;check for 0xE0 extended prefix
	je		.set_extended

	mov		cl, al				;save raw scancode in cl
	test	al, 0x80
	jnz		.release

	;--- key press ---
	mov		ah, 0				;ah=0 for normal keys
	cmp		byte [ext_pending], 0
	je		.no_ext
	mov		ah, 0xE0			;ah=0xE0 for extended keys
	mov		byte [ext_pending], 0

.no_ext:
	call	scancode_to_ascii	;translate scancode to ascii in al

	test	al, al				;al=0 means non-printable
	jz		.done

	call	apply_case			;apply shift/capslock
	cmp		al, 32				;store only printable
	jb		.print_char

.store_char:
	mov		ebx, [input_index]
	cmp		ebx, 80				;check if index full (enter will reset it)
	jae		.done

	mov		[input_buffer + ebx], al
	inc		ebx
	mov		[input_index], ebx	;store char in index
	jmp		.print_char

.print_char:
	call	terminal_putchar	;echo result
	jmp		.done

.set_extended:
	mov		byte [ext_pending], 1
	jmp		.done

.release:
	mov		byte [ext_pending], 0	;clear extended state on any release
	and		cl, 0x7F				;strip the release bit to get press scancode
	cmp		cl, 0x2A				;left shift release
	je		.shift_release
	cmp		cl, 0x36				;right shift release
	je		.shift_release
	jmp		.done

.shift_release:
	mov		byte [shift_state], 0
.done:
	ret


;doc: https://wiki.osdev.org/PS/2_Keyboard
;input: ah = 0 (normal) or 0xE0 (extended), al = scancode
;output: al = ascii character (0 = non-printable / handled internally)
scancode_to_ascii:
	cmp		ah, 0xE0			;special (higher 0xE0, lower 0xXX)
	je		.special

	;--- numbers ---
	cmp		al, 0x02
	je		.num1
	cmp		al, 0x03
	je		.num2
	cmp		al, 0x04
	je		.num3
	cmp		al, 0x05
	je		.num4
	cmp		al, 0x06
	je		.num5
	cmp		al, 0x07
	je		.num6
	cmp		al, 0x08
	je		.num7
	cmp		al, 0x09
	je		.num8
	cmp		al, 0x0A
	je		.num9
	cmp		al, 0x0B
	je		.num0

	;--- letters ---
	cmp		al, 0x10
	je		.key_q
	cmp		al, 0x11
	je		.key_w
	cmp		al, 0x12
	je		.key_e
	cmp		al, 0x13
	je		.key_r
	cmp		al, 0x14
	je		.key_t
	cmp		al, 0x15
	je		.key_y
	cmp		al, 0x16
	je		.key_u
	cmp		al, 0x17
	je		.key_i
	cmp		al, 0x18
	je		.key_o
	cmp		al, 0x19
	je		.key_p
	cmp		al, 0x1E
	je		.key_a
	cmp		al, 0x1F
	je		.key_s
	cmp		al, 0x20
	je		.key_d
	cmp		al, 0x21
	je		.key_f
	cmp		al, 0x22
	je		.key_g
	cmp		al, 0x23
	je		.key_h
	cmp		al, 0x24
	je		.key_j
	cmp		al, 0x25
	je		.key_k
	cmp		al, 0x26
	je		.key_l
	cmp		al, 0x2C
	je		.key_z
	cmp		al, 0x2D
	je		.key_x
	cmp		al, 0x2E
	je		.key_c
	cmp		al, 0x2F
	je		.key_v
	cmp		al, 0x30
	je		.key_b
	cmp		al, 0x31
	je		.key_n
	cmp		al, 0x32
	je		.key_m

	;--- symbols ---
	cmp		al, 0x01
	je		.escape
	cmp		al, 0x0C
	je		.dash
	cmp		al, 0x0D
	je		.equal
	cmp		al, 0x0E
	je		.backspace
	cmp		al, 0x0F
	je		.tab
	cmp		al, 0x1A
	je		.leftbracket
	cmp		al, 0x1B
	je		.rightbracket
	cmp		al, 0x1C
	je		.enter
	cmp		al, 0x1D
	je		.leftcontrol
	cmp		al, 0x27
	je		.semicol
	cmp		al, 0x28
	je		.squote
	cmp		al, 0x29
	je		.backtick
	cmp		al, 0x2A
	je		.leftshift
	cmp		al, 0x2B
	je		.backslash
	cmp		al, 0x33
	je		.comma
	cmp		al, 0x34
	je		.dot
	cmp		al, 0x35
	je		.fwdslash
	cmp		al, 0x36
	je		.rightshift
	cmp		al, 0x38
	je		.leftalt
	cmp		al, 0x39
	je		.space
	cmp		al, 0x3A
	je		.capslock
	cmp		al, 0x45
	je		.numberlock
	cmp		al, 0x46
	je		.scrolllock

	;--- function keys ---
	cmp		al, 0x3B
	je		.f1
	cmp		al, 0x3C
	je		.f2
	cmp		al, 0x3D
	je		.f3
	cmp		al, 0x3E
	je		.f4
	cmp		al, 0x3F
	je		.f5
	cmp		al, 0x40
	je		.f6
	cmp		al, 0x41
	je		.f7
	cmp		al, 0x42
	je		.f8
	cmp		al, 0x43
	je		.f9
	cmp		al, 0x44
	je		.f10
	cmp		al, 0x57
	je		.f11
	cmp		al, 0x58
	je		.f12

	;--- keypad ---
	cmp		al, 0x37
	je		.keypadstar
	cmp		al, 0x47
	je		.keypad7
	cmp		al, 0x48
	je		.keypad8
	cmp		al, 0x49
	je		.keypad9
	cmp		al, 0x4A
	je		.keypadminus
	cmp		al, 0x4B
	je		.keypad4
	cmp		al, 0x4C
	je		.keypad5
	cmp		al, 0x4D
	je		.keypad6
	cmp		al, 0x4E
	je		.keypadplus
	cmp		al, 0x4F
	je		.keypad1
	cmp		al, 0x50
	je		.keypad2
	cmp		al, 0x51
	je		.keypad3
	cmp		al, 0x52
	je		.keypad0
	cmp		al, 0x53
	je		.keypaddot

	xor		al, al			;unknown scancode, return 0
	ret

;--- extended keys (0xE0 prefix) ---
.special:
	cmp		al, 0x1C
	je		.keypadenter
	cmp		al, 0x1D
	je		.rightcontrol
	cmp		al, 0x35
	je		.keypadslash
	cmp		al, 0x38
	je		.rightalt
	cmp		al, 0x48
	je		.cursorup
	cmp		al, 0x4B
	je		.cursorleft
	cmp		al, 0x4D
	je		.cursorright
	cmp		al, 0x50
	je		.cursordown
	xor		al, al
	ret

;--- number handlers ---
.num1:
	mov		al, '1'
	ret
.num2:
	mov		al, '2'
	ret
.num3:
	mov		al, '3'
	ret
.num4:
	mov		al, '4'
	ret
.num5:
	mov		al, '5'
	ret
.num6:
	mov		al, '6'
	ret
.num7:
	mov		al, '7'
	ret
.num8:
	mov		al, '8'
	ret
.num9:
	mov		al, '9'
	ret
.num0:
	mov		al, '0'
	ret

;--- letter handlers ---
.key_q:
	mov		al, 'q'
	ret
.key_w:
	mov		al, 'w'
	ret
.key_e:
	mov		al, 'e'
	ret
.key_r:
	mov		al, 'r'
	ret
.key_t:
	mov		al, 't'
	ret
.key_y:
	mov		al, 'y'
	ret
.key_u:
	mov		al, 'u'
	ret
.key_i:
	mov		al, 'i'
	ret
.key_o:
	mov		al, 'o'
	ret
.key_p:
	mov		al, 'p'
	ret
.key_a:
	mov		al, 'a'
	ret
.key_s:
	mov		al, 's'
	ret
.key_d:
	mov		al, 'd'
	ret
.key_f:
	mov		al, 'f'
	ret
.key_g:
	mov		al, 'g'
	ret
.key_h:
	mov		al, 'h'
	ret
.key_j:
	mov		al, 'j'
	ret
.key_k:
	mov		al, 'k'
	ret
.key_l:
	mov		al, 'l'
	ret
.key_z:
	mov		al, 'z'
	ret
.key_x:
	mov		al, 'x'
	ret
.key_c:
	mov		al, 'c'
	ret
.key_v:
	mov		al, 'v'
	ret
.key_b:
	mov		al, 'b'
	ret
.key_n:
	mov		al, 'n'
	ret
.key_m:
	mov		al, 'm'
	ret

;--- symbol handlers ---
.escape:
	mov		al, 27
	ret
.dash:
	mov		al, '-'
	ret
.equal:
	mov		al, '='
	ret
.backspace:
	mov		ebx, [input_index]
	cmp		ebx, 0
	je		.empty_string

	dec		ebx
	mov		[input_index], ebx

	mov		al, 8
	ret
.empty_string:
	mov		al, 8
	ret
.tab:
	mov		al, 9
	ret
.leftbracket:
	mov		al, '['
	ret
.rightbracket:
	mov		al, ']'
	ret
.enter:
	mov		ebx, [input_index]
	mov		byte[input_buffer + ebx], 0	;null terminator

	mov		al, 10
	call	terminal_putchar

	push	input_buffer
	call	shell						;check if input is command
	add		esp, 4

	mov		dword [input_index], 0		;reset buffer
	xor		al, al
	ret
.leftcontrol:
	xor		al, al
	ret
.semicol:
	mov		al, ';'
	ret
.squote:
	mov		al, 39
	ret
.backtick:
	mov		al, '`'
	ret
.leftshift:
	mov		byte [shift_state], 1
	xor		al, al
	ret
.backslash:
	mov		al, 92
	ret
.comma:
	mov		al, ','
	ret
.dot:
	mov		al, '.'
	ret
.fwdslash:
	mov		al, '/'
	ret
.rightshift:
	mov		byte [shift_state], 1
	xor		al, al
	ret
.leftalt:
	xor		al, al
	ret
.space:
	mov		al, ' '
	ret
.capslock:
	xor		byte [caps_state], 1
	xor		al, al
	ret
.numberlock:
	xor		al, al
	ret
.scrolllock:
	xor		al, al
	ret

;--- function keys ---
.f1:
	mov		al, 0
	call	window_switch
	xor		al, al
	ret
.f2:
	mov		al, 1
	call	window_switch
	xor		al, al
	ret
.f3:
	mov		al, 2
	call	window_switch
	xor		al, al
	ret
.f4:
	call	stack_dump
	xor		al, al
	ret
.f5:
	xor		al, al
	ret
.f6:
	xor		al, al
	ret
.f7:
	xor		al, al
	ret
.f8:
	xor		al, al
	ret
.f9:
	xor		al, al
	ret
.f10:
	xor		al, al
	ret
.f11:
	xor		al, al
	ret
.f12:
	xor		al, al
	ret

;--- keypad handlers ---
.keypadstar:
	mov		al, '*'
	ret
.keypad7:
	mov		al, '7'
	ret
.keypad8:
	mov		al, '8'
	ret
.keypad9:
	mov		al, '9'
	ret
.keypadminus:
	mov		al, '-'
	ret
.keypad4:
	mov		al, '4'
	ret
.keypad5:
	mov		al, '5'
	ret
.keypad6:
	mov		al, '6'
	ret
.keypadplus:
	mov		al, '+'
	ret
.keypad1:
	mov		al, '1'
	ret
.keypad2:
	mov		al, '2'
	ret
.keypad3:
	mov		al, '3'
	ret
.keypad0:
	mov		al, '0'
	ret
.keypaddot:
	mov		al, '.'
	ret
.keypadenter:
	mov		al, 10
	ret
.rightcontrol:
	xor		al, al
	ret
.keypadslash:
	mov		al, '/'
	ret
.rightalt:
	xor		al, al
	ret
.cursorup:
	push dword	0x48
	push dword	msg_test_printk_str
	push dword	'a'
	push dword	42
	push dword	msg_test_printk
	call		printk
	add			esp, 20
	xor			al, al
	ret
.cursorleft:
	push dword	0xE04B
	push dword	msg_cursorleft
	call		printk
	add			esp, 8
	xor			al, al
	ret
.cursorright:
	push dword	0xE04D
	push dword	msg_cursorright
	call		printk
	add			esp, 8
	xor			al, al
	ret
.cursordown:
	push dword	0xE050
	push dword	msg_cursordown
	call		printk
	add			esp, 8
	xor			al, al
	ret


apply_case:
	cmp		al, 'a'	;check if al is a lowercase letter
	jb		.check_shift_symbol
	cmp		al, 'z'
	ja		.no_change

	movzx	ecx, byte[shift_state]	;it is a letter, check if shift XOR caps
	xor		cl, [caps_state]
	test	cl, cl
	jz		.no_change

	sub		al, 32	;convert lowercase to uppercase
	ret

.check_shift_symbol:
	cmp		byte [shift_state], 0	;if shift is not held
	je		.no_change

	;shift is held => get correct symbol shift
	cmp		al, '1'
	je		.sym_1
	cmp		al, '2'
	je		.sym_2
	cmp		al, '3'
	je		.sym_3
	cmp		al, '4'
	je		.sym_4
	cmp		al, '5'
	je		.sym_5
	cmp		al, '6'
	je		.sym_6
	cmp		al, '7'
	je		.sym_7
	cmp		al, '8'
	je		.sym_8
	cmp		al, '9'
	je		.sym_9
	cmp		al, '0'
	je		.sym_0
	cmp		al, '-'
	je		.sym_dash
	cmp		al, '='
	je		.sym_equal
	cmp		al, '['
	je		.sym_lbracket
	cmp		al, ']'
	je		.sym_rbracket
	cmp		al, ';'
	je		.sym_semicol
	cmp		al, 39
	je		.sym_squote
	cmp		al, '`'
	je		.sym_backtick
	cmp		al, 92
	je		.sym_backslash
	cmp		al, ','
	je		.sym_comma
	cmp		al, '.'
	je		.sym_dot
	cmp		al, '/'
	je		.sym_slash

.no_change:
	ret

.sym_1:
	mov		al, '!'
	ret
.sym_2:
	mov		al, '@'
	ret
.sym_3:
	mov		al, '#'
	ret
.sym_4:
	mov		al, '$'
	ret
.sym_5:
	mov		al, '%'
	ret
.sym_6:
	mov		al, '^'
	ret
.sym_7:
	mov		al, '&'
	ret
.sym_8:
	mov		al, '*'
	ret
.sym_9:
	mov		al, '('
	ret
.sym_0:
	mov		al, ')'
	ret
.sym_dash:
	mov		al, '_'
	ret
.sym_equal:
	mov		al, '+'
	ret
.sym_lbracket:
	mov		al, '{'
	ret
.sym_rbracket:
	mov		al, '}'
	ret
.sym_semicol:
	mov		al, ':'
	ret
.sym_squote:
	mov		al, '"'
	ret
.sym_backtick:
	mov		al, '~'
	ret
.sym_backslash:
	mov		al, '|'
	ret
.sym_comma:
	mov		al, '<'
	ret
.sym_dot:
	mov		al, '>'
	ret
.sym_slash:
	mov		al, '?'
	ret




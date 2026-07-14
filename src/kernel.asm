BITS	32	;use 32bit code

;in VGA mode, we have 8+8bits, upper bits being the colour/attribute, lower bits being the ascii character
%define VGA_ADDRESS			0XB8000	;default address for vga
%define VGA_WIDTH			80		;80 columns in terminal
%define VGA_HEIGHT			25		;25 rows in terminal
%define VGA_CELLS			(VGA_WIDTH * VGA_HEIGHT)
%define VGA_DEFAULT_COLOR	0x07	;black background, lightgrey foreground

%define SCREEN_COUNT	3	;number of screens we wanna handle

%define PS2_DATA_PORT	0x60	;port we read the ps2keyboard data from
%define PS2_STATUS_PORT	0x64	;status port for the keyboard

;include colour definitions
%include "colors.asm"


section .data
dec_buffer		times 12 db 0
screen_color	db VGA_DEFAULT_COLOR	;current text color attribute

extern stack_bottom
extern stack_top

section .bss
curr_screen		resd 1				;current active screen
cursor_row		resd 1				;live cursor row (used by terminal code)
cursor_col		resd 1				;live cursor col (used by terminal code)
screen_row		resd SCREEN_COUNT	;per-screen saved row positions
screen_col		resd SCREEN_COUNT	;per-screen saved col positions
screen_colors	resb SCREEN_COUNT	;colorscheme per screen

screen0_buffer	resw VGA_CELLS		;buffer for the cells in screen0
screen1_buffer	resw VGA_CELLS		;buffer for the cells in screen1
screen2_buffer	resw VGA_CELLS		;buffer for the cells in screen2
input_buffer	resb 81			;buffer for keyboard input
input_index		resd 1				;index for keyboard input


section .text
global kmain	;export kmain so that boot.asm can use it

;entrypoint for the vga display input handling
kmain:
	push	ebp
	mov		ebp, esp


	push	dword msg_gdtload	;gdt success message

	call	printk	;print it
	add		esp, 4	;clear from stack

	;enable cursor first before anything touches the terminal
	mov		dx, 0x3D4	;VGA index reg
	mov		al, 0x0A	;cursor start reg nubmer
	out		dx, al		;access al
	mov		dx, 0x3D5	;VGA data reg port
	mov		al, 0x0E	;cursor enable(bit 6-5), cursor scanline 14(bit 4-0)
	out		dx, al		;write cursor scanmine in reg number
	mov		dx, 0x3D4	;back to index port
	mov		al, 0x0B	;cursor end reg
	out		dx, al
	mov		dx, 0x3D5
	mov		al, 0x0F	;ends scanline 15
	out		dx, al		;write scanline end in end reg

	mov dword	[cursor_row], 0	;initializes cursor on the top of the screen
	mov dword	[cursor_col], 0	;initializes cursor on the left of the screen

	call	terminal_clear	;clears the screen

	; set terminal default colours per tty
	mov byte [screen_colors + 0], 0x07	; screen 0 -> light grey on black
	mov byte [screen_colors + 1], 0x0A	; screen 1 -> light green on black
	mov byte [screen_colors + 2], 0x0B	; screen 2 -> light cyan on black

;	UNUSED (OLD CODE TO SHOW 42 MANUALLY)
;	mov		edi, 0xB8000	;load edi with base address of vga
;	mov		ah, 0x07		;in higher bits of ax, the colour attr (0x07 for black background lightgrey foreground)
;	mov		al,	'4'			;in lower bits of ax, the ascii value for '4' character
;	mov		[edi], ax		;stores inside my edi the character in ax (4)
;	add		edi, 2			;each cell is 2bytes so move by that distance in the edi register for next cell
;	mov		al,	'2'			;lower bits, the ascii value for '2' character (we keep the same colour in ah)
;	mov		[edi], ax		;stores inside my edi the character in ax (2) to have 42 in my edi
;	ret						;returns to boot.asm before entering the halt loop

	mov		al, VGA_COLOR_LIGHT_GREY	;foreground in al
	mov		ah, VGA_COLOR_BLACK			;background in al
	call	vga_make_color				;create color using al ah bytes and combining them into ah
	call	terminal_set_color			;set the created color to current default

	mov		esi, msg_42		;moves into my esi buffer my 42 message
	call	terminal_putstr	;write the string in my buffer on my screen (from esi to edi)

	;foreground lightred and background black for next msg
	mov		al, VGA_COLOR_LIGHT_RED
	mov		ah, VGA_COLOR_BLACK
	call	vga_make_color
	call	terminal_set_color

	mov		esi, msg_second	;moves into my esi buffer my second message
	call	terminal_putstr	;write the string in my buffer on my screen (from esi to edi)


	;foreground lightgreen and background black for next msg
	mov		al, VGA_COLOR_LIGHT_GREEN
	mov		ah, VGA_COLOR_BLACK
	call	vga_make_color
	call	terminal_set_color

	mov		ecx, 3			;print 30 lines so we must scroll to see the next msg
	mov		esi, msg_scroll	;move my scrolling msg in my buffer

	; Restore default style
	call	terminal_set_color_default

.main_loop:
	call	keyboard_poll
	jmp		.main_loop

section .rodata

;prefix for log
prefix_info	db "[INFO] ", 0
prefix_ok	db "[ OK ] ", 0
prefix_err	db "[ERR ] ", 0


%define	CMD_SHELL_HELP		"help"
%define	CMD_SHELL_STACK		"stack"
%define	CMD_SHELL_CLEAR		"clear"
%define	CMD_SHELL_HALT		"halt"
%define	CMD_SHELL_REBOOT	"reboot"


;entry messages
msg_42	db "42", 10, 0
msg_second	db "Terminal ready", 10, 0
msg_scroll	db "Scroll ready", 10, 0
msg_gdtload	db "[GDT] loaded successfully", 10, 0

;keyboard messagess
msg_test_printk	db "[KBD] UP ARROW hi %d, %c, %s, %x", 10, 0
msg_cursorleft	db "[KBD] LEFT ARROW (scancode=%x)", 10, 0
msg_cursorright	db "[KBD] RIGHT ARROW (scancode=%x)", 10, 0
msg_cursordown	db "[KBD] DOWN ARROW (scancode=%x)", 10, 0
msg_test_printk_str	db "HELLO", 10, 0
;stack dump messages
msg_stkdmp_stk	db "[STK] esp=%x ebp=%x", 10, 0
msg_stkdmp_frm	db "[FRAME %d] ebp=%x ret=%x prev=%x", 10, 0
msg_stkdmp_raw	db "[RAW +%d] %x", 10, 0

;shell messages
msg_shell_help	db "[SHELL] Commands: help|stack|clear|halt|reboot", 10, 0
cmd_shell_help	db "help", 0
cmd_shell_stack	db "stack", 0
cmd_shell_clear	db "clear", 0
cmd_shell_halt	db "halt", 0
cmd_shell_reboot	db "reboot", 0

;include kernel modules
%include "stack_dump.asm"
%include "terminal.asm"
%include "keyboard.asm"
%include "printk.asm"
%include "window.asm"
%include "shell.asm"
%include "print_utils/print_hex_digit.asm"
%include "print_utils/print_hex32.asm"
%include "print_utils/print_dec.asm"
%include "print_utils/print_log.asm"
%include "libasm/ft_strcmp.s"

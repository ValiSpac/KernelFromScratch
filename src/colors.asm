; VGA color values (4-bit values)
%define VGA_COLOR_BLACK			0x0
%define VGA_COLOR_BLUE			0x1
%define VGA_COLOR_GREEN			0x2
%define VGA_COLOR_CYAN			0x3
%define VGA_COLOR_RED			0x4
%define VGA_COLOR_MAGENTA		0x5
%define VGA_COLOR_BROWN			0x6
%define VGA_COLOR_LIGHT_GREY	0x7
%define VGA_COLOR_DARK_GREY		0x8
%define VGA_COLOR_LIGHT_BLUE	0x9
%define VGA_COLOR_LIGHT_GREEN	0xA
%define VGA_COLOR_LIGHT_CYAN	0xB
%define VGA_COLOR_LIGHT_RED		0xC
%define VGA_COLOR_LIGHT_MAGENTA	0xD
%define VGA_COLOR_LIGHT_BROWN	0xE
%define VGA_COLOR_WHITE			0xF

section .text
global vga_make_color
global terminal_set_color
global terminal_set_color_default

vga_make_color:
	mov		dl, al	;copy foreground from al into dl
	mov		al, ah	;move background into al to shift it
	shl		al, 4	;shift 4 to make place for foreground
	or		al, dl	;merge bits from both
	ret				;now fore+background colors are in al

terminal_set_color:
	mov		[screen_color], al	;apply color in my al to my screen_color
	ret

terminal_set_color_default:
	mov byte	[screen_color], VGA_DEFAULT_COLOR	;use my const, copy it into screen_color
	ret

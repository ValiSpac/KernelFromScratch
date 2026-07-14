BITS	32	;tells NASM we are targetting 32bit x86 code


;multiboot consts
MULTIBOOT_MAGIC		equ 0x1BADB002	;magic number expected by GRUB for multibootv1
MULTIBOOT_FLAGS		equ 0	;no extra behaviour flags
MULTIBOOT_CHECKSUM	equ -(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS)	;magic + flags + checksum == 0 (mod 2^32) so we store it's negative in the checksum


;multiboot header section
section .multiboot
align 4
dd MULTIBOOT_MAGIC		;32bit field with magic value
dd MULTIBOOT_FLAGS		;32bit field with the flags we ask grub
dd MULTIBOOT_CHECKSUM	;32bit field checksum so that the sum of all 3 is 0


;BSS section: reserve memory for a stack
section .bss
align 16
stack_bottom:	;marks the start of the reserved memory
resb 16384		;reserve 16KiB for this stack
stack_top:		;marks the end of the stack


;code section
section .text
global _start	;export _start to use as entrypoint
global stack_bottom
global stack_top
extern kmain	;makes NASM able to use the extern kmain (defined in another file)
extern gdt_re_load ;load gdt + flushes segment


;entrypoint
_start:
	cli						;disable interrupts
	mov		esp, stack_top	;load esp with the top of the stack we reserved
	xor		ebp, ebp		;clear ebp (back to 0)
	call	gdt_re_load		;install gdt at 0x800 (defined in linker)
	call	kmain			; call the external function kmain

.hang:
	hlt				;halt cpu until next external interrupt
	jmp		.hang	;loop

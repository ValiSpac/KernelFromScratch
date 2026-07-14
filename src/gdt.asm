[BITS 32]	;set to 32-bit mode

section	.gdt		;start gdt section
global	gdt_start	;beginning of gdt
global	gdt_end		;end of gdt
global	gdtr		;gdt register
global	gdt_re_load	;gdt re/loading method

;segment descriptor struct
%macro gdt_entry 4	;%1=base  %2=limit  %3=access  %4=flags
	dw (%2) & 0xFFFF		;limit 15:0
	dw (%1) & 0xFFFF		;base 15:0
	db ((%1) >> 16) & 0xFF	;base 23:16
	db (%3)					;access byte
	db (((%4) << 4) | (((%2) >> 16) & 0x0F)); flags nibble + limit 19:16
	db ((%1) >> 24) & 0xFF	;base 31:24
%endmacro

;selector consts to define sections (index*8)
%define KERNEL_CS	0X08
%define KERNEL_DS	0X10
%define KERNEL_SS	0X18
%define USER_CS		0X20
%define USER_DS		0X28
%define USER_SS		0X30

;access bytes
;7:p(present must be 1) 6-5:dpl(privilege level) 4:s(descriptor type) 3:e(executable) 2:dc(direction) 1:rw(read/write) 0:a(accesed, 0)
%define ACC_KCODE	0x9A	;10011010 - ring 0 code, readable
%define ACC_KDATA	0x92	;10010010 - ring 0 data/stack, writable
%define ACC_UCODE	0xFA	;11111010 - ring 3 code, readable
%define ACC_UDATA	0xF2	;11111010 - ring-3 data/stack, writable

;flags nibble
;3:granularity 2:d/b(32 bit seg - 1 for protected mode) 1:64-bit(0 for protected 32bit) 0:available
%define FLAGS_32	0xC	;1100 - for flat 32-bit segments


;init gd
gdt_start:
	dq	0x0000000000000000	;0x00 mandatory null descriptor
	gdt_entry 0x00000000, 0xFFFFF, ACC_KCODE, FLAGS_32	;0x08 kernel code segment
	gdt_entry 0x00000000, 0xFFFFF, ACC_KDATA, FLAGS_32	;0x10 kernel data segment
	gdt_entry 0x00000000, 0xFFFFF, ACC_KDATA, FLAGS_32	;0x18 kernel stack segment
	gdt_entry 0x00000000, 0xFFFFF, ACC_UCODE, FLAGS_32	;0x20 user code segment
	gdt_entry 0x00000000, 0xFFFFF, ACC_UDATA, FLAGS_32	;0x28 user data segment
	gdt_entry 0x00000000, 0xFFFFF, ACC_UDATA, FLAGS_32	;0x30 user stack segment

;end of gdt
gdt_end:

;get the gdt register
gdtr:
	dw		gdt_end - gdt_start - 1	;limit storage
	dd		gdt_start				;base storage


section	.text

;re/load CS register containing code selector
gdt_re_load:
	lgdt	[gdtr]				;load gdt register
	jmp		KERNEL_CS:.flush_cs	;far jump reloads cs

;reload data segment registers
.flush_cs:
	mov		ax, KERNEL_DS	;data define
	;fill ds-ss segments
	mov		ds, ax			;null segment descriptor
	mov		es, ax			;code segment descriptor for the privileged (kernel) mode
	mov		fs, ax			;data segment descriptor for the privileged (kernel) mode
	mov		gs, ax			;code segment descriptor for the non-privileged (user) mode

	mov		ax, KERNEL_SS	;define for SS segment
	mov		ss, ax			;data segment descriptor for the non-privileged (user) mode

	ret

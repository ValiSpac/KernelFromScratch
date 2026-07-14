/* Linker will execute starting from this symbol */
ENTRY(_start)

/* define the sections here */
SECTIONS
{
	/* go to physical address 800 for gdt */
	. = 0x00000800;
	/* global descriptor table location */
	.gdt : { *(.gdt) }


	/* start loading the kernel at the physical address 1MiB, standard for x86 kernels */
	. = 1M;

	/* put multiboot header early so grub can find it near beginning of iso */
	.multiboot : { *(.multiboot) }

	/* section for all executable code */
	.text : { *(.text) }

	/* read-only data (strings, consts, gdt/idt, etc...) */
	.rodata : { *(.rodata) }

	/* initialized writable data */
	.data : { *(.data) }

	/* uninitialized writable data */
	.bss : { *(.bss) *(COMMON) }
}



/*bootstrap assembly stub that sets up the processor such that high level languages such as C can be used */


// Constants for multiboot header
.set ALIGN,    1<<0             /* align loaded modules on page boundaries */
.set MEMINFO,  1<<1             /* provide memory map */
.set FLAGS,    ALIGN | MEMINFO  /* this is the Multiboot 'flag' field */
.set MAGIC,    0x1BADB002       /* 'magic number' lets bootloader find the header */
.set CHECKSUM, -(MAGIC + FLAGS) /* checksum */


/* Multiboot header that marks program as kernel
Bootloader looks for this section in the first 8KiB of the kernel file*/
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/*
Multiboot standard does not define the value of the stack pointer register(esp)
Up to the kernel to allocate room for esp, alligned to 16 bytes (x86 arhitecture will asume 16b aligned stack),
giving it a size of 16Kb (16384 bytes) and marking the top of the stack. (stakc grows downwards)
*/
.section .bss
.align 16
stack_bottom:
.skip 16384
stack_top:

/* The linker script specifies _start as the entry point for the kernel */
.section .text
.global _start
.type _start, @function
_start:
    /*
    At this point there are no features in our x86 machine(32-bit protected mode).
    The kernel has full control of the CPU. It can use only a few hardware features and the scripts it provides.
    */
    /*
    Set the esp register to point to the top of the stack. C cannot function without a stack.
    */
    mov $stack_top, %esp
    /*
    Enter the high-level kernel. The ABI(Application binary interface) requires the stack to be algined 16 bytes when it calls the instruction
    */
    call kernel_main
    /*
    IF the systems has nothing to do we put it in a infinite loop:
    1.Disable interupts with cli (cleat interrupt enable in eflags, IFFlag = 0)
    2.Wait for the next interupt to arrive with hlt. This will lock up the computer
    3.Jump to the hlt instruction in case of interrupt
    */
    cli
1:  hlt
    jmp 1b

/*
Set the size of _start symbol to the current location "." minux its start
*/
.size _start, . - _start

section	.text
global	shell

;shell entrypoint, parse command here (dispatch to exec)
shell:
	push	ebp
	mov		ebp, esp
	push	esi
	mov		esi, [ebp+8]	;we do love untangled regs

	jmp		.parse

;compare string in esi with available commands
.parse:
	push	dword cmd_shell_help
	push	esi
	call	ft_strcmp
	add		esp, 8
	test	eax, eax
	je		.help

	push	dword cmd_shell_stack
	push	esi
	call	ft_strcmp
	add		esp, 8
	test	eax, eax
	je		.stack

	push	dword cmd_shell_clear
	push	esi
	call	ft_strcmp
	add		esp, 8
	test	eax, eax
	je		.clear

	push	dword cmd_shell_halt
	push	esi
	call	ft_strcmp
	add		esp, 8
	test	eax, eax
	je		.halt

	push	dword cmd_shell_reboot
	push	esi
	call	ft_strcmp
	add		esp, 8
	test	eax, eax
	je		.reboot

	jmp		.done	;no match

;show list of commands
.help:
	push	dword msg_shell_help
	call	printk	;call printk to display
	add		esp, 4	;clear the elements from the stack
	jmp		.done

;print the stack
.stack:
	call	stack_dump	;just call my stackdump
	jmp		.done

;clear the current terminal
.clear:
	call	terminal_clear	;just call terminal clear
	jmp		.done

;der Zug halt am Hauptbahnhof
.halt:
	cli		;clear interrupts
.halt_loop:
	hlt		;HALT, KOMMEN SIE MIT MICH
	jmp		.halt_loop

;my final message				goodbye
.reboot:
	mov		al, 0xFE	;load lower nybble with 0xFE val
	out		0x64, al	;send nybble to port 64 -> reboot instruction
	jmp		.done

;just return
.done:
	pop	esi
	pop	ebp
	ret

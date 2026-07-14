section .text
global print_hex_digit

print_hex_digit:
	cmp		al, 9
	jbe		.digit	;considers it a digit if between 0 and 9
	add		al, 55	;else, add 55 to it ('A' - 10 = 55)
	ret

.digit:
	add		al, '0'	;make the digit an ascii digit and return
	ret

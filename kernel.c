#include "kernel.h"

size_t strlen(const char* str)
{
    size_t len = 0;
    while (str[len])
        len++;
    return len;
}

/* Clears the screen by filling every cell in the buffer with a space char */
void terminal_initialize(void)
{
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);

    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
}

void terminal_scroll()
{
    volatile char *dst = (volatile char *)0xB8000;
    volatile char *src = (volatile char *)(0xB8000 + (VGA_WIDTH * 2));
    int bytes = (VGA_HEIGHT - 1) * VGA_WIDTH * 2;
    int i;

    for (i = 0; i < bytes; i++) {
        dst[i] = src[i];
    }
}

void terminal_delete_last_line()
{
    int x;
    volatile char *ptr;

    for(x = 0; x < VGA_WIDTH * 2; x++) {
        ptr = 0xB8000 + (VGA_WIDTH * 2) * (VGA_HEIGHT - 1) + x;
        *ptr = 0;
	}
}

void terminal_setcolor(uint8_t color)
{
    terminal_color = color;
}

/* Indexing where in the terminal to put the character */
void terminal_putentryat(char c, uint8_t color, size_t x, size_t y)
{
    const size_t index = y * VGA_WIDTH + x;
    terminal_buffer[index] = vga_entry(c, color);
}

/* Core write operation, uses teminal_putentryat to know where to write the char */
void terminal_putchar(char ch)
{
    unsigned char c = ch;

    if (c == '\n') {
        terminal_column = 0;
        terminal_row++;
    } else {
        terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
        terminal_column++;
        if (terminal_column == VGA_WIDTH) {
            terminal_column = 0;
            terminal_row++;
        }
    }
    if (terminal_row == VGA_HEIGHT) {
        terminal_scroll();
        terminal_delete_last_line();
        terminal_row = VGA_HEIGHT - 1;
    }
}


/* Core writing method */
void terminal_write(const char* data, size_t size)
{
    for (size_t i = 0; i < size; i++)
        terminal_putchar(data[i]);
}

void terminal_writestring(const char* data)
{
    terminal_write(data, strlen(data));
}

void terminal_write42()
{
    terminal_setcolor(VGA_COLOR_LIGHT_MAGENTA);
    terminal_writestring("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
    terminal_writestring("@@@@@@@@  @@@  @@@@@      @@@@@@@@\n");
    terminal_writestring("@@@@@@@@  @@@  @@@@@@@@@@  @@@@@@@\n");
    terminal_writestring("@@@@@@@@@      @@@@@@@@@@  @@@@@@@\n");
    terminal_writestring("@@@@@@@@@@@@@  @@@@@@     @@@@@@@@\n");
    terminal_writestring("@@@@@@@@@@@@@  @@@@@  @@@@@@@@@@@@\n");
    terminal_writestring("@@@@@@@@@@@@@  @@@@@       @@@@@@@\n");
    terminal_writestring("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
}

void kernel_main(void)
{
    /* Initialize terminal interface */
    terminal_initialize();
    terminal_writestring("Hello kernel world!\n");
    terminal_write42();
}


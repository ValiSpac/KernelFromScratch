#ifndef KERNEL_H
#define KERNEL_H

/* Freestading libraries that are part of the compiler */
/*Bool data types*/
#include <stdbool.h>
/*size_t and NULL*/
#include <stddef.h>
/* intx_t and uintx_t datatypes, required for OS deployment
    Also uint16_t and uint8_t critical for byte alignement*/
#include <stdint.h>

/* Hardware text mode color constants.
   depends on a single byte, the upper 4 bits are the foreground color and the lower 4 bits the background*/
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN = 14,
    VGA_COLOR_WHITE = 15,
};

#define VGA_WIDTH   80
#define VGA_HEIGHT  25
#define VGA_MEMORY  0xB8000 /* physical memory address where VGA text mode video memory lives */

/* Varaibles to define the complete state of the terminal */
size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer = (uint16_t*)VGA_MEMORY; /* Basically the top left cell */

/* Set the color for 1 character cell */
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg)
{
    return fg | bg << 4;
}

/* Here the upper 8 bits will represent the ascii character and the lower 8 the vag color*/
static inline uint16_t vga_entry(unsigned char uc, uint8_t color)
{
    return (uint16_t) uc | (uint16_t) color << 8;
}

#endif

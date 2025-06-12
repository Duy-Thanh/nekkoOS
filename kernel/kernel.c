/*
 * nekkoOS Kernel - Main kernel implementation
 * 32-bit x86 operating system kernel
 * 
 * This file contains the main kernel initialization and core functions
 */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* VGA text mode constants */
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

/* VGA color constants */
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

/* Multiboot information structure */
struct multiboot_info {
    uint32_t flags;
    uint32_t mem_lower;
    uint32_t mem_upper;
    uint32_t boot_device;
    uint32_t cmdline;
    uint32_t mods_count;
    uint32_t mods_addr;
    uint32_t syms[4];
    uint32_t mmap_length;
    uint32_t mmap_addr;
    uint32_t drives_length;
    uint32_t drives_addr;
    uint32_t config_table;
    uint32_t boot_loader_name;
    uint32_t apm_table;
    uint32_t vbe_control_info;
    uint32_t vbe_mode_info;
    uint16_t vbe_mode;
    uint16_t vbe_interface_seg;
    uint16_t vbe_interface_off;
    uint16_t vbe_interface_len;
};

/* Global variables */
static uint16_t* const vga_buffer = (uint16_t*)VGA_MEMORY;
static size_t terminal_row = 0;
static size_t terminal_column = 0;
static uint8_t terminal_color = 0;

/* Function prototypes */
void kernel_main(uint32_t magic, struct multiboot_info* mboot_info);
void terminal_initialize(void);
void terminal_setcolor(uint8_t color);
void terminal_putchar(char c);
void terminal_write(const char* data, size_t size);
void terminal_writestring(const char* data);
void kprintf(const char* format, ...);
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg);
static inline uint16_t vga_entry(unsigned char uc, uint8_t color);
size_t strlen(const char* str);
void init_gdt(void);
void init_idt(void);
void init_memory(struct multiboot_info* mboot_info);
void init_interrupts(void);

/* String length function */
size_t strlen(const char* str) {
    size_t len = 0;
    while (str[len])
        len++;
    return len;
}

/* VGA helper functions */
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t) uc | (uint16_t) color << 8;
}

/* Terminal functions */
void terminal_initialize(void) {
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            vga_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
}

void terminal_setcolor(uint8_t color) {
    terminal_color = color;
}

void terminal_putchar(char c) {
    if (c == '\n') {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT) {
            terminal_row = 0;
        }
        return;
    }
    
    if (c == '\r') {
        terminal_column = 0;
        return;
    }
    
    if (c == '\t') {
        terminal_column = (terminal_column + 8) & ~(8 - 1);
        if (terminal_column >= VGA_WIDTH) {
            terminal_column = 0;
            if (++terminal_row == VGA_HEIGHT) {
                terminal_row = 0;
            }
        }
        return;
    }
    
    const size_t index = terminal_row * VGA_WIDTH + terminal_column;
    vga_buffer[index] = vga_entry(c, terminal_color);
    
    if (++terminal_column == VGA_WIDTH) {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT) {
            terminal_row = 0;
        }
    }
}

void terminal_write(const char* data, size_t size) {
    for (size_t i = 0; i < size; i++)
        terminal_putchar(data[i]);
}

void terminal_writestring(const char* data) {
    terminal_write(data, strlen(data));
}

/* Simple printf implementation */
void kprintf(const char* format, ...) {
    // Simple implementation - just prints the format string for now
    terminal_writestring(format);
}

/* Memory initialization */
void init_memory(struct multiboot_info* mboot_info) {
    kprintf("Initializing memory management...\n");
    
    if (mboot_info->flags & 0x1) {
        kprintf("Memory: Lower = ");
        // TODO: Convert numbers to strings
        kprintf("KB, Upper = ");
        kprintf("KB\n");
    }
    
    kprintf("Memory management initialized.\n");
}

/* GDT initialization stub */
void init_gdt(void) {
    kprintf("Initializing Global Descriptor Table...\n");
    // TODO: Implement GDT setup
    kprintf("GDT initialized.\n");
}

/* IDT initialization stub */
void init_idt(void) {
    kprintf("Initializing Interrupt Descriptor Table...\n");
    // TODO: Implement IDT setup
    kprintf("IDT initialized.\n");
}

/* Interrupt initialization */
void init_interrupts(void) {
    kprintf("Initializing interrupt handlers...\n");
    // TODO: Implement interrupt handlers
    kprintf("Interrupts initialized.\n");
}

/* Main kernel function */
void kernel_main(uint32_t magic, struct multiboot_info* mboot_info) {
    /* Initialize terminal */
    terminal_initialize();
    
    /* Set terminal color */
    terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK));
    
    /* Print kernel startup messages */
    kprintf("nekkoOS Kernel v0.1\n");
    kprintf("==================\n\n");
    
    /* Check multiboot magic */
    if (magic != 0x2BADB002) {
        terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_RED, VGA_COLOR_BLACK));
        kprintf("ERROR: Invalid multiboot magic number!\n");
        kprintf("Expected: 0x2BADB002, Got: 0x");
        // TODO: Print hex number
        kprintf("\n");
        goto halt;
    }
    
    terminal_setcolor(vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK));
    kprintf("Multiboot magic verified.\n");
    
    /* Initialize kernel subsystems */
    kprintf("\nInitializing kernel subsystems...\n");
    kprintf("==================================\n");
    
    /* Initialize memory management */
    init_memory(mboot_info);
    
    /* Initialize GDT */
    init_gdt();
    
    /* Initialize IDT */
    init_idt();
    
    /* Initialize interrupts */
    init_interrupts();
    
    /* Kernel initialization complete */
    terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK));
    kprintf("\nKernel initialization complete!\n");
    kprintf("===============================\n");
    
    terminal_setcolor(vga_entry_color(VGA_COLOR_YELLOW, VGA_COLOR_BLACK));
    kprintf("\nSystem ready. Entering idle loop...\n");
    
    /* Main kernel loop */
    terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK));
    while (1) {
        /* Kernel idle loop */
        /* TODO: Implement scheduler and process management */
        __asm__ volatile ("hlt");
    }
    
halt:
    /* Halt system */
    terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_RED, VGA_COLOR_BLACK));
    kprintf("System halted.\n");
    
    /* Disable interrupts and halt */
    __asm__ volatile ("cli");
    while (1) {
        __asm__ volatile ("hlt");
    }
}
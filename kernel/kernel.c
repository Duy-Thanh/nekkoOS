/*
 * nekkoOS Kernel - Main kernel implementation
 * 32-bit x86 operating system kernel
 * 
 * This file contains the main kernel initialization and core functions
 */

#include "types.h"
#include "vga.h"
#include "multiboot.h"
#include "string.h"

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
void kprintf_hex(uint32_t value);
void kprintf_dec(uint32_t value);
void init_gdt(void);
void init_idt(void);
void init_memory(struct multiboot_info* mboot_info);
void init_interrupts(void);



/* Number to string conversion functions */
void uint_to_hex_string(uint32_t value, char* buffer) {
    const char hex_chars[] = "0123456789ABCDEF";
    buffer[0] = '0';
    buffer[1] = 'x';
    
    for (int i = 7; i >= 0; i--) {
        buffer[2 + (7 - i)] = hex_chars[(value >> (i * 4)) & 0xF];
    }
    buffer[10] = '\0';
}

void uint_to_dec_string(uint32_t value, char* buffer) {
    if (value == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return;
    }
    
    char temp[12];
    int i = 0;
    
    while (value > 0) {
        temp[i++] = '0' + (value % 10);
        value /= 10;
    }
    
    for (int j = 0; j < i; j++) {
        buffer[j] = temp[i - 1 - j];
    }
    buffer[i] = '\0';
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

/* Print hexadecimal number */
void kprintf_hex(uint32_t value) {
    char buffer[11];
    uint_to_hex_string(value, buffer);
    terminal_writestring(buffer);
}

/* Print decimal number */
void kprintf_dec(uint32_t value) {
    char buffer[12];
    uint_to_dec_string(value, buffer);
    terminal_writestring(buffer);
}

/* Memory initialization */
void init_memory(struct multiboot_info* mboot_info) {
    kprintf("Initializing memory management...\n");
    
    if (mboot_info->flags & MULTIBOOT_INFO_MEMORY) {
        kprintf("Memory: Lower = ");
        kprintf_dec(mboot_info->mem_lower);
        kprintf("KB, Upper = ");
        kprintf_dec(mboot_info->mem_upper);
        kprintf("KB\n");
        
        uint32_t total_memory = mboot_info->mem_lower + mboot_info->mem_upper;
        kprintf("Total conventional memory: ");
        kprintf_dec(total_memory);
        kprintf("KB (");
        kprintf_dec(total_memory / 1024);
        kprintf("MB)\n");
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
    if (magic != MULTIBOOT_BOOTLOADER_MAGIC) {
        terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_RED, VGA_COLOR_BLACK));
        kprintf("ERROR: Invalid multiboot magic number!\n");
        kprintf("Expected: ");
        kprintf_hex(MULTIBOOT_BOOTLOADER_MAGIC);
        kprintf(", Got: ");
        kprintf_hex(magic);
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
    
    terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_BROWN, VGA_COLOR_BLACK));
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
/* nekkoOS Kernel Linker Script
 * 32-bit x86 kernel memory layout
 * Links kernel to be loaded at 1MB (0x100000)
 */

ENTRY(_start)

SECTIONS
{
    /* Kernel loaded at 1MB */
    . = 0x100000;

    /* Multiboot header must be at the beginning */
    .multiboot ALIGN(4K) : {
        *(.multiboot)
    }

    /* Read-execute section */
    .text ALIGN(4K) : {
        *(.text)
        *(.text.*)
    }

    /* Read-only data */
    .rodata ALIGN(4K) : {
        *(.rodata)
        *(.rodata.*)
    }

    /* Read-write data (initialized) */
    .data ALIGN(4K) : {
        *(.data)
        *(.data.*)
    }

    /* Read-write data (uninitialized) and stack */
    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }

    /* Stack section */
    .stack ALIGN(4K) : {
        . = . + 0x4000; /* 16KB stack */
        _stack_top = .;
    }

    /* Kernel end marker */
    _kernel_end = .;

    /* Discard debug information and other unnecessary sections */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.note)
        *(.note.*)
    }
}

; nekkoOS Kernel Entry Point
; 32-bit x86 kernel bootstrap assembly
; This file contains the multiboot header and kernel entry point

.set ALIGN,    1<<0             ; align loaded modules on page boundaries
.set MEMINFO,  1<<1             ; provide memory map
.set FLAGS,    ALIGN | MEMINFO  ; this is the Multiboot 'flag' field
.set MAGIC,    0x1BADB002       ; 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) ; checksum of above, to prove we are multiboot

; Multiboot header
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

; Reserve stack space
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

; Kernel entry point
.section .text
.global _start
.type _start, @function

_start:
    ; Setup stack
    mov $stack_top, %esp

    ; Reset EFLAGS
    pushl $0
    popf

    ; Save multiboot information
    ; EAX contains magic number
    ; EBX contains pointer to multiboot info structure
    push %ebx  ; Multiboot info pointer
    push %eax  ; Magic number

    ; Clear screen
    call clear_screen

    ; Display kernel banner
    call display_banner

    ; Initialize kernel
    call kernel_main

    ; Kernel should never return, but if it does, halt
    cli
1:  hlt
    jmp 1b

; Function: clear_screen
; Clears the VGA text mode screen
clear_screen:
    push %eax
    push %ecx
    push %edi

    mov $0xB8000, %edi      ; VGA text buffer
    mov $0x0720, %ax        ; Space character with light gray on black
    mov $2000, %ecx         ; 80x25 = 2000 characters
    rep stosw               ; Fill screen

    pop %edi
    pop %ecx
    pop %eax
    ret

; Function: display_banner
; Displays the kernel startup banner
display_banner:
    push %eax
    push %esi
    push %edi

    mov $0xB8000, %edi      ; VGA text buffer
    mov $banner_text, %esi  ; Banner string
    mov $0x0F, %ah          ; White text on black background

display_loop:
    lodsb                   ; Load character from string
    test %al, %al           ; Check for null terminator
    jz display_done

    cmp $'\n', %al          ; Check for newline
    je handle_newline

    stosw                   ; Store character and attribute
    jmp display_loop

handle_newline:
    ; Calculate position for next line
    push %eax
    mov %edi, %eax
    sub $0xB8000, %eax      ; Get current offset
    mov $160, %ecx          ; 80 chars * 2 bytes per char
    xor %edx, %edx
    div %ecx                ; Divide by line length
    inc %eax                ; Next line
    mul %ecx                ; Multiply back
    add $0xB8000, %eax      ; Add base address
    mov %eax, %edi
    pop %eax
    jmp display_loop

display_done:
    pop %edi
    pop %esi
    pop %eax
    ret

; Data section
.section .rodata
banner_text:
    .asciz "nekkoOS v0.1 - 32-bit Operating System\n\nKernel loaded successfully!\nInitializing system...\n\n"

; Mark the size of _start for debugging
.size _start, . - _start

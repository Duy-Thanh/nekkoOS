; nekkoOS Stage 2 Bootloader
; Extended bootloader with protected mode setup and kernel loading
; This stage enables A20 line, sets up GDT, enters protected mode, and loads kernel

[BITS 16]                   ; Start in 16-bit real mode
[ORG 0x10000]              ; Loaded at 0x10000 by Stage 1

; Constants
KERNEL_LOAD_ADDR    equ 0x100000    ; Load kernel at 1MB
KERNEL_START_LBA    equ 17          ; Kernel starts after stage2
KERNEL_SECTOR_COUNT equ 64          ; Kernel size in sectors
MEMORY_MAP_ADDR     equ 0x8000      ; Memory map storage

; GDT constants
GDT_CODE_SEG        equ 0x08        ; Code segment selector
GDT_DATA_SEG        equ 0x10        ; Data segment selector

start_stage2:
    ; Store boot drive number passed from Stage 1
    mov [boot_drive], dl
    
    ; Setup segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF          ; Set stack

    ; Display Stage 2 message
    mov si, msg_stage2
    call print_string

    ; Get memory map
    call get_memory_map

    ; Enable A20 line
    call enable_a20

    ; Load kernel into memory
    call load_kernel

    ; Setup GDT
    call setup_gdt

    ; Enter protected mode
    call enter_protected_mode

    ; Should never reach here
    jmp halt

; Function: print_string (16-bit)
; Input: SI = pointer to null-terminated string
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; Function: get_memory_map
; Gets system memory map using BIOS interrupt 0x15
get_memory_map:
    mov si, msg_memory_map
    call print_string

    mov di, MEMORY_MAP_ADDR ; Destination for memory map
    xor ebx, ebx            ; EBX = 0 to start
    xor bp, bp              ; Entry count
    mov edx, 0x534D4150     ; "SMAP" signature

.loop:
    mov eax, 0xE820         ; Function code
    mov ecx, 24             ; Size of entry
    int 0x15                ; BIOS interrupt
    jc .error               ; Error if carry set

    cmp eax, 0x534D4150     ; Check signature
    jne .error

    cmp ecx, 20             ; Minimum entry size
    jl .skip_entry

    inc bp                  ; Increment entry count
    add di, 24              ; Move to next entry

.skip_entry:
    test ebx, ebx           ; Check if done
    jz .done
    jmp .loop

.done:
    mov [memory_map_entries], bp
    mov si, msg_memory_done
    call print_string
    ret

.error:
    mov si, msg_memory_error
    call print_string
    ret

; Function: enable_a20
; Enables the A20 line for accessing memory above 1MB
enable_a20:
    mov si, msg_a20
    call print_string

    ; Try BIOS method first
    mov ax, 0x2403          ; Check A20 support
    int 0x15
    jc .try_keyboard

    mov ax, 0x2401          ; Enable A20
    int 0x15
    jc .try_keyboard

    ; Test if A20 is enabled
    call test_a20
    cmp ax, 1
    je .success

.try_keyboard:
    ; Try keyboard controller method
    call wait_8042
    mov al, 0xAD            ; Disable keyboard
    out 0x64, al

    call wait_8042
    mov al, 0xD0            ; Read output port
    out 0x64, al

    call wait_8042_data
    in al, 0x60             ; Read data
    push ax

    call wait_8042
    mov al, 0xD1            ; Write output port
    out 0x64, al

    call wait_8042
    pop ax
    or al, 2                ; Set A20 bit
    out 0x60, al

    call wait_8042
    mov al, 0xAE            ; Enable keyboard
    out 0x64, al

    call wait_8042

    ; Test A20 again
    call test_a20
    cmp ax, 1
    je .success

    ; Fast A20 method
    in al, 0x92
    or al, 2
    out 0x92, al

    call test_a20
    cmp ax, 1
    je .success

    mov si, msg_a20_error
    call print_string
    jmp halt

.success:
    mov si, msg_a20_success
    call print_string
    ret

; Function: wait_8042
wait_8042:
    in al, 0x64
    test al, 2
    jnz wait_8042
    ret

wait_8042_data:
    in al, 0x64
    test al, 1
    jz wait_8042_data
    ret

; Function: test_a20
; Returns: AX = 1 if A20 enabled, 0 if disabled
test_a20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax
    mov es, ax
    mov di, 0x0500

    mov ax, 0xFFFF
    mov ds, ax
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je .exit

    mov ax, 1

.exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

; Function: load_kernel
; Loads the kernel from disk into memory at 1MB
load_kernel:
    mov si, msg_loading_kernel
    call print_string

    ; Setup for loading to 1MB (requires switching to unreal mode)
    ; For simplicity, we'll load to conventional memory first, then move

    ; Load kernel sectors
    mov ax, 0x2000          ; Temporary load segment
    mov es, ax
    mov bx, 0               ; Offset

    ; Setup DAP for kernel loading
    mov word [dap_size], 0x10
    mov word [dap_sectors], KERNEL_SECTOR_COUNT
    mov word [dap_offset], 0
    mov word [dap_segment], 0x2000
    mov dword [dap_lba_low], KERNEL_START_LBA
    mov dword [dap_lba_high], 0

    ; Read kernel sectors
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    jc .kernel_error

    mov si, msg_kernel_loaded
    call print_string
    ret

.kernel_error:
    mov si, msg_kernel_error
    call print_string
    jmp halt

; Function: setup_gdt
; Sets up the Global Descriptor Table
setup_gdt:
    mov si, msg_gdt
    call print_string

    lgdt [gdt_descriptor]
    ret

; Function: enter_protected_mode
; Switches from real mode to protected mode
enter_protected_mode:
    mov si, msg_protected
    call print_string

    cli                     ; Disable interrupts

    ; Set PE bit in CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to flush pipeline and load CS
    jmp GDT_CODE_SEG:protected_mode_start

; 32-bit protected mode code starts here
[BITS 32]
protected_mode_start:
    ; Setup data segments
    mov ax, GDT_DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Setup stack
    mov esp, 0x90000

    ; Move kernel from temporary location to 1MB
    mov esi, 0x20000        ; Source (temporary location)
    mov edi, KERNEL_LOAD_ADDR ; Destination (1MB)
    mov ecx, KERNEL_SECTOR_COUNT * 512 / 4 ; Count in dwords
    rep movsd

    ; Jump to kernel
    jmp KERNEL_LOAD_ADDR

; Should never reach here
protected_halt:
    hlt
    jmp protected_halt

[BITS 16]

; Function: halt
halt:
    mov si, msg_halted
    call print_string
    cli
    hlt
    jmp halt

; Data section
boot_drive:         db 0
memory_map_entries: dw 0

; Disk Address Packet
dap:
dap_size:       dw 0x10
dap_reserved:   dw 0
dap_sectors:    dw 0
dap_offset:     dw 0
dap_segment:    dw 0
dap_lba_low:    dd 0
dap_lba_high:   dd 0

; GDT (Global Descriptor Table)
gdt_start:
    ; Null descriptor
    dd 0x0, 0x0

    ; Code segment descriptor
    dw 0xFFFF           ; Limit low
    dw 0x0000           ; Base low
    db 0x00             ; Base middle
    db 10011010b        ; Access: present, ring 0, code, executable, readable
    db 11001111b        ; Flags: 4KB granularity, 32-bit
    db 0x00             ; Base high

    ; Data segment descriptor
    dw 0xFFFF           ; Limit low
    dw 0x0000           ; Base low
    db 0x00             ; Base middle
    db 10010010b        ; Access: present, ring 0, data, writable
    db 11001111b        ; Flags: 4KB granularity, 32-bit
    db 0x00             ; Base high

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; GDT size
    dd gdt_start                ; GDT address

; String messages
msg_stage2:         db 'nekkoOS Stage 2 Bootloader', 0x0D, 0x0A, 0
msg_memory_map:     db 'Getting memory map...', 0x0D, 0x0A, 0
msg_memory_done:    db 'Memory map obtained.', 0x0D, 0x0A, 0
msg_memory_error:   db 'Memory map error!', 0x0D, 0x0A, 0
msg_a20:            db 'Enabling A20 line...', 0x0D, 0x0A, 0
msg_a20_success:    db 'A20 line enabled.', 0x0D, 0x0A, 0
msg_a20_error:      db 'A20 enable failed!', 0x0D, 0x0A, 0
msg_loading_kernel: db 'Loading kernel...', 0x0D, 0x0A, 0
msg_kernel_loaded:  db 'Kernel loaded.', 0x0D, 0x0A, 0
msg_kernel_error:   db 'Kernel load error!', 0x0D, 0x0A, 0
msg_gdt:            db 'Setting up GDT...', 0x0D, 0x0A, 0
msg_protected:      db 'Entering protected mode...', 0x0D, 0x0A, 0
msg_halted:         db 'Stage 2 halted.', 0x0D, 0x0A, 0

; Pad to sector boundary
times 8192-($-$$) db 0      ; Pad Stage 2 to 16 sectors (8KB)

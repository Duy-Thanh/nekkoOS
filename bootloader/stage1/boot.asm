; nekkoOS Stage 1 Bootloader (MBR) with Mini Filesystem
; 32-bit Operating System Bootstrap
; This code fits in the Master Boot Record (512 bytes) and includes a mini filesystem

[BITS 16]                   ; 16-bit real mode
[ORG 0x7C00]               ; BIOS loads us at 0x7C00

; Constants
STAGE2_LOAD_SEGMENT equ 0x1000  ; Load stage2 at 0x10000
STAGE2_LOAD_OFFSET  equ 0x0000

start:
    ; Initialize segments and stack
    cli                     ; Disable interrupts
    xor ax, ax             ; Zero AX
    mov ds, ax             ; Data segment = 0
    mov es, ax             ; Extra segment = 0
    mov ss, ax             ; Stack segment = 0
    mov sp, 0x7C00         ; Stack pointer below bootloader
    sti                    ; Re-enable interrupts

    ; Clear screen
    mov ah, 0x00           ; Video mode function
    mov al, 0x03           ; 80x25 text mode
    int 0x10               ; BIOS video interrupt

    ; Display boot message
    mov si, msg_booting
    call print_string

    ; Store boot drive number
    mov [boot_drive], dl
    
    ; Debug: Show boot drive number
    mov si, msg_drive_debug
    call print_string
    mov al, dl
    call print_hex_byte
    mov si, msg_newline
    call print_string

    ; Load Stage 2 bootloader using simple sector reading
    call load_stage2

    ; Pass boot drive number to Stage 2 in DL register
    mov dl, [boot_drive]

    ; Jump to Stage 2
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

; Function: print_string
; Input: SI = pointer to null-terminated string
print_string:
    mov ah, 0x0E           ; Teletype output function
.loop:
    lodsb                  ; Load byte from SI into AL
    cmp al, 0              ; Check for null terminator
    je .done
    int 0x10               ; BIOS video interrupt
    jmp .loop
.done:
    ret

; Function: print_hex_byte
; Input: AL = byte to print
; Prints byte as hex (e.g., 80, FF, 0A)
print_hex_byte:
    push ax
    push cx
    
    mov ah, 0x0E
    mov cx, ax              ; Save original value
    
    ; Print high nibble
    shr al, 4
    cmp al, 9
    jle .high_digit
    add al, 'A' - 10
    jmp .print_high
.high_digit:
    add al, '0'
.print_high:
    int 0x10
    
    ; Print low nibble
    mov al, cl
    and al, 0x0F
    cmp al, 9
    jle .low_digit
    add al, 'A' - 10
    jmp .print_low
.low_digit:
    add al, '0'
.print_low:
    int 0x10
    
    pop cx
    pop ax
    ret

; Function: load_stage2
; Loads Stage 2 bootloader from fixed sectors (1-16)
load_stage2:
    mov si, msg_loading
    call print_string

    ; Check if LBA is supported
    mov ah, 0x41           ; Check extensions present
    mov bx, 0x55AA         ; Magic number
    mov dl, [boot_drive]   ; Drive number
    int 0x13               ; BIOS disk interrupt
    jc .use_chs           ; If carry set, use CHS instead

    ; Use LBA to load Stage 2
    mov si, msg_lba
    call print_string

    ; Setup DAP (Disk Address Packet)
    mov word [dap_size], 0x10           ; Size of DAP
    mov word [dap_sectors], 16          ; 16 sectors for Stage 2
    mov word [dap_offset], STAGE2_LOAD_OFFSET
    mov word [dap_segment], STAGE2_LOAD_SEGMENT
    mov dword [dap_lba_low], 1          ; Start at LBA 1
    mov dword [dap_lba_high], 0

    ; Read sectors using LBA
    mov ah, 0x42           ; Extended read
    mov dl, [boot_drive]   ; Drive number
    mov si, dap            ; DAP address
    int 0x13               ; BIOS disk interrupt
    jc .disk_error

    mov si, msg_loaded
    call print_string
    ret

.use_chs:
    ; Fallback to CHS addressing
    mov si, msg_chs
    call print_string

    ; Load Stage 2 using CHS (sectors 2-17, since CHS is 1-based)
    mov ax, STAGE2_LOAD_SEGMENT
    mov es, ax
    mov bx, STAGE2_LOAD_OFFSET

    ; Read 16 sectors starting from sector 2
    mov ah, 0x02           ; Read sectors function
    mov al, 16             ; Number of sectors
    mov ch, 0              ; Cylinder 0
    mov cl, 2              ; Sector 2 (1-based, LBA 1)
    mov dh, 0              ; Head 0
    mov dl, [boot_drive]   ; Drive number
    int 0x13               ; BIOS disk interrupt
    jc .disk_error

    mov si, msg_loaded
    call print_string
    ret

.disk_error:
    mov si, msg_disk_error
    call print_string
    jmp halt

; Function: halt
; Halts the system
halt:
    mov si, msg_halted
    call print_string
    cli                    ; Disable interrupts
    hlt                    ; Halt processor
    jmp halt               ; Infinite loop

; Data section
boot_drive:     db 0

; Disk Address Packet for LBA reading
dap:
dap_size:       dw 0x10    ; Size of DAP
dap_reserved:   dw 0       ; Reserved
dap_sectors:    dw 0       ; Number of sectors to read
dap_offset:     dw 0       ; Offset to load to
dap_segment:    dw 0       ; Segment to load to
dap_lba_low:    dd 0       ; Lower 32 bits of LBA
dap_lba_high:   dd 0       ; Upper 32 bits of LBA

; String messages
msg_booting:        db 'nekkoOS Stage 1 Bootloader', 0x0D, 0x0A, 0
msg_drive_debug:    db 'Boot drive: 0x', 0
msg_newline:        db 0x0D, 0x0A, 0
msg_loading:        db 'Loading Stage 2...', 0x0D, 0x0A, 0
msg_lba:            db 'Using LBA mode', 0x0D, 0x0A, 0
msg_chs:            db 'Using CHS mode', 0x0D, 0x0A, 0
msg_loaded:         db 'Stage 2 loaded successfully!', 0x0D, 0x0A, 0
msg_disk_error:     db 'Disk read error!', 0x0D, 0x0A, 0
msg_halted:         db 'System halted.', 0x0D, 0x0A, 0

; Mini filesystem directory (for future use - currently just reserves space)
; This could be expanded to include file entries
times 446-($-$$) db 0

; Reserved space for mini filesystem (64 bytes)
; Format: 4 entries x 16 bytes each
; Entry format: 8-byte name, 1-byte type, 1-byte reserved, 4-byte LBA, 2-byte sectors

; Entry 0: Stage 2
db 'STAGE2  '              ; 8-byte name
db 1                       ; Type: bootloader
db 0                       ; Reserved
dd 1                       ; LBA: sector 1
dw 16                      ; Sectors: 16

; Entry 1: Kernel
db 'KERNEL  '              ; 8-byte name
db 2                       ; Type: kernel
db 0                       ; Reserved
dd 17                      ; LBA: sector 17
dw 32                      ; Sectors: 32

; Entry 2-3: Reserved
times 32 db 0

; Boot signature (must be at bytes 510-511)
times 510-($-$$) db 0
dw 0xAA55
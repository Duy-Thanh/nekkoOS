; nekkoOS Stage 1 Bootloader (MBR) with Mini Filesystem
; 32-bit Operating System Bootstrap
; This code fits in the Master Boot Record (512 bytes) and includes a mini filesystem

[BITS 16]                   ; 16-bit real mode
[ORG 0x7C00]               ; BIOS loads us at 0x7C00

; Constants
STAGE2_LOAD_SEGMENT equ 0x1000  ; Load stage2 at 0x10000
STAGE2_LOAD_OFFSET  equ 0x0000

; Mini filesystem constants
MINIDIR_OFFSET equ 446      ; Directory starts at byte 446
ENTRY_SIZE     equ 16       ; Each entry is 16 bytes
ENTRY_NAME     equ 0        ; Name offset in entry
ENTRY_TYPE     equ 8        ; Type offset in entry
ENTRY_LBA      equ 10       ; LBA offset in entry
ENTRY_SECTORS  equ 14       ; Sector count offset in entry

; File types
TYPE_UNUSED    equ 0
TYPE_BOOTLOADER equ 1
TYPE_KERNEL    equ 2

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

    ; Find and load Stage 2 using mini filesystem
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

; Function: find_file
; Input: SI = pointer to filename (8 chars)
; Output: BX = directory entry offset, or 0 if not found
find_file:
    push si
    mov bx, MINIDIR_OFFSET + 0x7C00    ; Start of directory
    mov cx, 4                          ; 4 directory entries
    
.search_loop:
    ; Check if entry is used
    mov al, [bx + ENTRY_TYPE]
    cmp al, TYPE_UNUSED
    je .next_entry
    
    ; Compare filename
    push si
    push bx
    push cx
    
    lea di, [bx + ENTRY_NAME]
    mov cx, 8
    repe cmpsb
    
    pop cx
    pop bx
    pop si
    
    je .found
    
.next_entry:
    add bx, ENTRY_SIZE
    loop .search_loop
    
    ; Not found
    xor bx, bx
    jmp .done
    
.found:
    ; BX already contains the entry offset
    
.done:
    pop si
    ret

; Function: load_file_by_entry
; Input: BX = directory entry offset
; Output: Carry clear if success, set if error
load_file_by_entry:
    ; Get file info from directory entry
    mov eax, [bx + ENTRY_LBA]      ; Start LBA
    mov cx, [bx + ENTRY_SECTORS]   ; Number of sectors
    
    ; Load to Stage 2 location
    mov dx, STAGE2_LOAD_SEGMENT
    mov es, dx
    mov di, STAGE2_LOAD_OFFSET
    
    ; Setup DAP for reading
    mov word [dap_size], 0x10
    mov word [dap_reserved], 0
    mov word [dap_sectors], cx
    mov word [dap_offset], di
    mov word [dap_segment], dx
    mov dword [dap_lba_low], eax
    mov dword [dap_lba_high], 0
    
    ; Check if LBA is supported
    mov ah, 0x41           ; Check extensions present
    mov bx, 0x55AA         ; Magic number
    mov dl, [boot_drive]   ; Drive number
    int 0x13               ; BIOS disk interrupt
    jc .use_chs           ; If carry set, use CHS instead

    ; Read using LBA
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    jc .disk_error
    
    clc                    ; Clear carry (success)
    ret

.use_chs:
    ; Fallback to CHS - simplified for testing
    mov si, msg_chs_fallback
    call print_string
    
    ; For now, assume sectors 1-16 for Stage 2
    mov ax, STAGE2_LOAD_SEGMENT
    mov es, ax
    mov bx, STAGE2_LOAD_OFFSET

    mov ah, 0x02           ; Read sectors function
    mov al, 16             ; Number of sectors (Stage 2 size)
    mov ch, 0              ; Cylinder 0
    mov cl, 2              ; Sector 2 (1-based, LBA 1)
    mov dh, 0              ; Head 0
    mov dl, [boot_drive]   ; Drive number
    int 0x13               ; BIOS disk interrupt
    jc .disk_error

    clc                    ; Clear carry (success)
    ret

.disk_error:
    stc                    ; Set carry (error)
    ret

; Function: load_stage2
; Loads Stage 2 bootloader using mini filesystem
load_stage2:
    mov si, msg_loading
    call print_string

    ; Find Stage 2 in directory
    mov si, stage2_name
    call find_file
    
    cmp bx, 0
    je .not_found
    
    ; Load the file
    call load_file_by_entry
    jc .disk_error

    mov si, msg_loaded
    call print_string
    ret

.not_found:
    mov si, msg_not_found
    call print_string
    jmp halt

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

; File names for mini filesystem
stage2_name:     db 'STAGE2  '

; String messages
msg_booting:        db 'nekkoOS Stage 1 + MiniFS', 0x0D, 0x0A, 0
msg_loading:        db 'Loading Stage 2...', 0x0D, 0x0A, 0
msg_loaded:         db 'Stage 2 loaded!', 0x0D, 0x0A, 0
msg_not_found:      db 'Stage 2 not found!', 0x0D, 0x0A, 0
msg_disk_error:     db 'Disk read error!', 0x0D, 0x0A, 0
msg_chs_fallback:   db 'Using CHS mode...', 0x0D, 0x0A, 0
msg_halted:         db 'System halted.', 0x0D, 0x0A, 0

; Mini filesystem directory (placed at offset 446)
times 446-($-$$) db 0

; Directory entries start here (64 bytes total)
minidir:
    ; Entry 0: Stage 2 bootloader
    db 'STAGE2  '              ; Name (8 bytes)
    db TYPE_BOOTLOADER         ; Type
    db 0                       ; Reserved
    dd 1                       ; Start LBA (sector 1)
    dw 16                      ; Size (16 sectors)
    
    ; Entry 1: Kernel
    db 'KERNEL  '              ; Name (8 bytes) 
    db TYPE_KERNEL             ; Type
    db 0                       ; Reserved
    dd 17                      ; Start LBA (sector 17)
    dw 32                      ; Size (32 sectors)
    
    ; Entry 2: Reserved
    times 16 db 0
    
    ; Entry 3: Reserved  
    times 16 db 0

; Boot signature (must be at bytes 510-511)
times 510-($-$$) db 0
dw 0xAA55
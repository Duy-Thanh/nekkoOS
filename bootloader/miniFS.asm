; nekkoOS Mini Filesystem for Bootloader
; A simple 512-byte filesystem structure that fits in the MBR
; This is ONLY for the bootloader to locate Stage 2 and Kernel

; Mini Filesystem Layout:
; Bytes 0-445:   Stage 1 bootloader code
; Bytes 446-509: Mini filesystem directory (64 bytes)
; Bytes 510-511: Boot signature (0x55AA)

; Mini Filesystem Directory Structure (64 bytes total):
; Entry 0 (16 bytes): Stage 2 bootloader
; Entry 1 (16 bytes): Kernel
; Entry 2 (16 bytes): Reserved
; Entry 3 (16 bytes): Reserved

; Each directory entry (16 bytes):
; Bytes 0-7:   File name (8 chars, null-padded)
; Byte 8:      File type (0=unused, 1=bootloader, 2=kernel)
; Byte 9:      Reserved
; Bytes 10-13: Start LBA sector (32-bit)
; Bytes 14-15: Size in sectors (16-bit)

[BITS 16]
[ORG 0x7C00]

; Mini filesystem directory starts at offset 446
MINIDIR_OFFSET equ 446

; Directory entry structure
ENTRY_SIZE     equ 16
ENTRY_NAME     equ 0   ; 8 bytes
ENTRY_TYPE     equ 8   ; 1 byte
ENTRY_RESERVED equ 9   ; 1 byte  
ENTRY_LBA      equ 10  ; 4 bytes
ENTRY_SECTORS  equ 14  ; 2 bytes

; File types
TYPE_UNUSED    equ 0
TYPE_BOOTLOADER equ 1
TYPE_KERNEL    equ 2

; Function: find_file
; Input: SI = pointer to filename (8 chars)
; Output: BX = directory entry offset, or 0 if not found
; Modifies: AX, CX, DI
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

; Function: load_file
; Input: BX = directory entry offset
; Output: Carry clear if success, set if error
; Modifies: AX, CX, DX, SI
load_file:
    ; Get file info from directory entry
    mov eax, [bx + ENTRY_LBA]      ; Start LBA
    mov cx, [bx + ENTRY_SECTORS]   ; Number of sectors
    
    ; For Stage 2: load to 0x1000:0x0000
    ; For Kernel: load to 0x2000:0x0000 (temporary)
    mov al, [bx + ENTRY_TYPE]
    cmp al, TYPE_BOOTLOADER
    je .load_stage2
    
    ; Load kernel to temporary location
    mov dx, 0x2000
    jmp .do_load
    
.load_stage2:
    mov dx, 0x1000
    
.do_load:
    mov es, dx
    xor di, di                     ; ES:DI = load address
    
    ; Setup DAP for reading
    mov word [dap_size], 0x10
    mov word [dap_reserved], 0
    mov word [dap_sectors], cx
    mov word [dap_offset], di
    mov word [dap_segment], dx
    mov dword [dap_lba_low], eax
    mov dword [dap_lba_high], 0
    
    ; Read using LBA
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    
    ret

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
    dw 32                      ; Size (32 sectors, should be enough)
    
    ; Entry 2: Reserved
    times 16 db 0
    
    ; Entry 3: Reserved  
    times 16 db 0

; Data for disk operations
boot_drive: db 0

; Disk Address Packet
dap:
dap_size:     dw 0x10
dap_reserved: dw 0
dap_sectors:  dw 0
dap_offset:   dw 0
dap_segment:  dw 0
dap_lba_low:  dd 0
dap_lba_high: dd 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
; nekkoOS Stage 1 Bootloader - FAT12 Boot Sector
; Simplified version that fits in 512 bytes

[BITS 16]
[ORG 0x7C00]

; Jump instruction and NOP (required for FAT12)
jmp short start
nop

; FAT12 BIOS Parameter Block (BPB) - Required for FAT12 filesystem
oem_identifier      db 'NEKKOOS '      ; 8 bytes OEM identifier
bytes_per_sector    dw 512             ; Bytes per sector
sectors_per_cluster db 1               ; Sectors per cluster
reserved_sectors    dw 1               ; Reserved sectors (boot sector)
fat_copies          db 2               ; Number of FAT copies
root_entries        dw 224             ; Root directory entries
total_sectors       dw 2880            ; Total sectors (1.44MB floppy size)
media_descriptor    db 0xF0            ; Media descriptor (removable disk)
sectors_per_fat     dw 9               ; Sectors per FAT
sectors_per_track   dw 18              ; Sectors per track
heads               dw 2               ; Number of heads
hidden_sectors      dd 0               ; Hidden sectors
total_sectors_large dd 0               ; Large sector count (if > 65535)

; Extended Boot Record (EBR)
drive_number        db 0               ; Drive number (filled at runtime)
reserved            db 0               ; Reserved
boot_signature      db 0x29            ; Extended boot signature
volume_serial       dd 0x12345678      ; Volume serial number
volume_label        db 'nekkoOS    '   ; 11 bytes volume label
filesystem_type     db 'FAT12   '      ; 8 bytes filesystem type

start:
    ; Initialize segments and stack
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Store boot drive
    mov [drive_number], dl

    ; Print boot message
    mov si, msg_boot
    call print

    ; Load root directory to 0x0800:0000
    mov ax, 19              ; Root starts at sector 19 (1 + 2*9)
    mov bx, 0x0800
    mov es, bx
    xor bx, bx
    mov cx, 14              ; 14 sectors for root directory
    call read_sectors

    ; Find STAGE2.BIN in root directory
    mov ax, 0x0800
    mov es, ax
    xor di, di
    mov cx, 224             ; Root entries

find_loop:
    mov si, stage2_name
    push cx
    push di
    mov cx, 11
    repe cmpsb
    pop di
    pop cx
    je found_stage2
    add di, 32              ; Next entry
    loop find_loop

    ; Not found
    mov si, msg_error
    call print
    jmp halt

found_stage2:
    ; Get first cluster
    mov ax, [es:di + 26]    ; First cluster at offset 26

    ; Load Stage 2 to 0x1000:0000
    ; Simplified: assume Stage 2 is in cluster 2 (sector 33)
    mov ax, 33              ; Data area starts at sector 33
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    mov cx, 16              ; Load 16 sectors for Stage 2
    call read_sectors

    ; Jump to Stage 2
    mov dl, [drive_number]
    jmp 0x1000:0x0000

; Function: read_sectors
; AX = start sector, CX = count, ES:BX = destination
read_sectors:
    mov [dap_sector], ax
    mov [dap_count], cx
    mov [dap_offset], bx
    mov [dap_segment], es

    ; Try LBA first
    mov ah, 0x42
    mov dl, [drive_number]
    mov si, dap
    int 0x13
    jnc .done

    ; Fallback to CHS
    mov ah, 0x02
    mov al, cl              ; Sector count
    mov ch, 0               ; Cylinder
    mov cl, 2               ; Sector (1-based)
    mov dh, 0               ; Head
    mov dl, [drive_number]
    int 0x13

.done:
    ret

; Function: print
; SI = string pointer
print:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

halt:
    cli
    hlt
    jmp halt

; Data
stage2_name     db 'STAGE2  BIN'
msg_boot        db 'nekkoOS STA1', 13, 10, 0
msg_error       db 'Error!', 13, 10, 0

; DAP structure
dap:
    db 0x10                 ; Size
    db 0                    ; Reserved
dap_count:
    dw 0                    ; Sector count
dap_offset:
    dw 0                    ; Offset
dap_segment:
    dw 0                    ; Segment
dap_sector:
    dd 0                    ; Start sector
    dd 0                    ; High part

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55

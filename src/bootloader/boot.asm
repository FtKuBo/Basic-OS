ORG 0x7C00
BITS 16

JMP SHORT main
NOP

    bdb_oem:                        DB  'MSWIN4.l'
    bdb_bytes_per_sector:           DW  512
    bdb_sectors_per_cluster:        DB  1
    bdb_reserved_sectors:           DW  1
    bdb_fat_count:                  DB  2
    bdb_dir_entries_count:          DW  0E0h
    bdb_total_sectors:              DW  2880
    bdb_media_descriptor_type:      DB  0F0h
    bdb_sectors_per_fat:            DW  9
    bdb_sectors_per_track:          DW  18
    bdb_heads:                      DW  2
    bdb_hidden_sectors:             DD  0
    bdb_large_sector_count:         DD  0

    ebr_drive_number:               DB  0
                                    DB  0
    ebr_signature:                  DB  29h
    ebr_volume_id:                  DB  12h,34h,56h,78h
    ebr_volume_label:               DB  'BASIC-OS   '
    ebr_system_id:                  DB  'FAT12   '



main:
    XOR ax, ax
    MOV ds, ax
    MOV es, ax
    MOV ss, ax

    MOV sp, 0x7C00

    MOV dl, [ebr_drive_number]
    MOV ax, 1
    MOV cl, 1
    MOV bx, 0x7E00
    CALL disk_read


    MOV si, os_boot_msg
    CALL print
    HLT


halt:
    JMP halt

;
; input: lba in ax | output: chs in cx
; cx [bits 0-5]: sector number | (LBA % sectors per track) + 1
; cx [bits 6-15]: cylinder | (LBA / sectors per track) /  number of heads
; dh: head | (LBA / sectors per track) % number of heads
;

lba_to_chs:
    PUSH ax
    PUSH dx

    XOR dx,dx
    DIV word [bdb_sectors_per_track] 
    INC dx ; sector
    MOV cx, dx
    
    XOR dx, dx
    DIV word [bdb_heads]

    MOV dh, dl ; head
    MOV ch, al
    SHL ah, 6
    OR cl, ah

    POP ax
    MOV dl, al
    POP ax

    RET



disk_read:
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx
    PUSH di

    call lba_to_chs

    MOV ah, 02h
    MOV di, 3

retry:
    STC 
    INT 13h
    JNC doneRead

    call diskReset

    DEC di
    TEST di,di
    JNZ retry

failDiskRead:
    MOV si, read_failure
    CALL print
    HLT
    JMP halt

diskReset:
    PUSHA
    MOV ah, 0
    STC
    INT 13h
    JC failDiskRead
    POPA
    RET

doneRead:
    POP di
    POP dx
    POP cx
    POP bx
    POP ax

    ret


print:
    PUSH si
    PUSH ax 
    PUSH bx

print_loop:
    LODSB
    CMP al, 0
    JE done_print
    
    MOV ah, 0x0E
    MOV bh, 0
    INT 0x10

    JMP print_loop

done_print:
    POP bx
    POP ax
    POP si
    RET

os_boot_msg: DB 'The KIKA dial CACA has booted', 0x0D, 0x0A, 0
read_failure: DB 'The disk failed to be read', 0x0D, 0x0A, 0
reset_failure: DB 'The disk failed to reset', 0x0D, 0x0A, 0
TIMES 510-($-$$) DB 0
DW 0AA55h
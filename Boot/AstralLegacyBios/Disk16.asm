;
; This file provide disk related functionaility
;

;
; Read disk sector for kernel image and map it into memory
;
; Args:
;   bx = memory addr to load at
; Clobbers:
;   ax, cx, bx
;
LoadDiskSector:
    mov     ah, 2       ; Function - read sector
    mov     al, 8       ; Number of sectors to read (8*512=0x1000)
    mov     ch, 0       ; Track/cylinder number (0-1023)
    mov     cl, 2       ; Sector number (1-17, e.g. 1 = 0-511B MBR, 2 = 512-1023B)
    mov     dh, 0       ; Head number (0-15)
    mov     dl, DRIVE   ; Drive number (QEMU index)
    mov     bx, BOOTLOADER_SECOND_STAGE_ADDR  ; es:bx memory addr to load into (we'll put it after bootloader in mem)

    int     0x13        ; Low level disk interrupt
                        ;   CF = 0 on success, = 1 on error
                        ;   AH = INT 13 status
                        ;   AL = numbers of sectors read
    jc      .err
    ret

    .err:
        mov     si, szErrLoadDiskSector
        call    PrintInt
        xor     bx, bx
        mov     bl, ah
        call    PrintHex
        mov     si, szNewLine
        call    PrintInt        
        ret

szErrLoadDiskSector:        db "Err - LoadDiskSector ", 0
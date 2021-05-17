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
DiskLoadSecondStage:
    mov     ah, 2       ; Function - read sector
    mov     al, 4       ; Number of sectors to read (4*512=2048)
    mov     ch, 0       ; Cylinder/track number (0-1023)
    mov     cl, 2       ; Sector number (1-17, e.g. 1 = 0-511B MBR, 2 = 512-1023B)
    mov     dh, 0       ; Head number (0-15)
    mov     dl, DRIVE   ; Drive number (QEMU index)
    mov     bx, BOOTLOADER_SECOND_STAGE_ADDR  ; es:bx memory addr to load into (we'll put it after bootloader in mem)

    int     0x13        ; Low level disk interrupt
                        ;   CF = 0 on success, = 1 on error
                        ;   AH = INT 13 status
                        ;   AL = numbers of sectors read
    jc      .err

    xor     bx, bx
    mov     si, szSuccessSectorFound0
    call    PrintStrInt
    mov     bl, ch
    call    PrintHex
    mov     si, szSuccessSectorFound1
    call    PrintStrInt
    mov     bl, dh
    call    PrintHex    
    mov     si, szSuccessSectorFound2
    call    PrintStrInt
    mov     bl, cl
    call    PrintHex
    mov     si, szSuccessSectorFound3
    call    PrintStrInt
    mov     bl, al
    call    PrintHex

    mov     si, szNewLine
    call    PrintStrInt
    mov     si, szNewLine
    call    PrintStrInt
    ret

    .err:
        mov     si, szErrLoadDiskSector
        call    PrintStrInt
        xor     bx, bx
        mov     bl, ah
        call    PrintHex
        mov     si, szNewLine
        call    PrintStrInt        
        ret

szSuccessSectorFound0:      db "Found Stage 2 at Cylinder: ", 0
szSuccessSectorFound1:      db ", Head: ", 0
szSuccessSectorFound2:      db ", Sector: ", 0
szSuccessSectorFound3:      db ", Sector size: ", 0
szErrLoadDiskSector:        db "Err - LoadDiskSector ", 13, 10, 0
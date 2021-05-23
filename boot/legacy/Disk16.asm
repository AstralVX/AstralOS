;
; This file provide disk related functionaility
;

;
; Read disk sector for kernel image and map it into memory
;
; Args:
;   al - Number of sectors to read (4*512=2048)
;   ch - Cylinder/track number (0-1023)
;   cl - Sector number (1-17, e.g. 1 = 0-511B MBR, 2 = 512-1023B)
;   dh - Head number (0-15)
;   dl - Drive number (QEMU index)
;   bx - Memory addr to load image at (<1MB)
;   es:bx - High memory addr to load image (>1MB) i.e. 1000h:0000h (load at 10000h), 
;           however even though disk controller will write to that mem, realmode code can't access that high
;
DiskIntReadSectors:
    pusha
    mov     ah, 2       ; Function - read sector
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
    jmp     .end

    .err:
        mov     si, szErrLoadDiskSector
        call    PrintStrInt
        xor     bx, bx
        mov     bl, ah
        call    PrintHex
        mov     si, szNewLine
        call    PrintStrInt        
        jmp     .end

    .end:
    popa
    ret

szSuccessSectorFound0:      db "Reading image at Cylinder: ", 0
szSuccessSectorFound1:      db ", Head: ", 0
szSuccessSectorFound2:      db ", Sector: ", 0
szSuccessSectorFound3:      db ", Sector size: ", 0
szErrLoadDiskSector:        db "Err - DiskIntReadSectors ", 13, 10, 0
; Tell NASM this is 16 bit (8086) code for real mode
bits 16

%include "Config.asm"

; Tell NASM to output all our labels with offset 0x7c00, because 
; BIOS will jump to this boot sector 0x7c00 and transfers control
org 0x7c00

jmp 0x0000:main

;
; BIOS will load this 512 byte boot sector from the storage MBR into memory
;
main:
    ;
    ; Initialise essential segment registers
    ;
    xor ax, ax
    mov ds, ax
    mov es, ax

    ;
    ; Setup a stack range at from 0x6000 to 0x7000, stack will grow downwards
    ; Since our bootloader is loaded at 0x7C00, we have almost 30KiB below free
    ; Disable interrupts to update ss:sp atomically (only required for <= 286 (8088)), then re-enable
    ;   N.b. interrupts are disabled for 1 inst after mov ss, ...
    ;
    cli
    mov     ax, 0x6000
    mov     ss, ax
    mov     sp, 0x7000
    sti

    mov     ax, 0x3
    int     0x10                            ; Set VGA screen mode to 3 (text 80x25)  

    call    PrintBanner

    mov     si, szStartedBootloaderRM
    call    PrintStrInt

    mov     si, szReadingDisk
    call    PrintTransitionMessage
    
    ; Read bootloader stage 2 into mem
    mov     al, 4                               ; Read 4 sectors (or 4*0x200=2048 bytes)
    mov     ch, 0                               ; Cylinder 0
    mov     cl, 2                               ; Sector number 2 (0x200 to 0x400)
    mov     dh, 0                               ; Head number 0
    mov     dl, DRIVE                           ; Drive number (QEMU index)
    mov     bx, BOOTLOADER_SECOND_STAGE_ADDR    ; ES:BX memory addr to load into (we'll put it after bootloader in mem)
    call    DiskIntReadSectors

    jmp 0x0000:BOOTLOADER_SECOND_STAGE_ADDR

    cli                                     ; Stop interrupts
    hlt                                     ; Stop CPU until next interrupt (hence CPU stopped)

PrintBanner:
    mov     cl, 80
    call    PrintDashedLine
    mov     cl, 29
    call    PrintDashedLine
    mov     si, szBanner                    ; Arg 1 - Move memory location of banner string into register SI
    mov     bl, 0x1F                        ; Arg 2 - Colour style
    call    PrintStrColourInt               ; Coloured print interrupt (SI = string, BL = colour)
    mov     cl, 30
    call    PrintDashedLine
    mov     cl, 80
    call    PrintDashedLine
    mov     si, szNewLineCarriageRet
    call    PrintStrInt
    ret

;
; Other file includes
;
%include "Print16.asm"
%include "Disk16.asm"

;
; Consts
;
szBanner:                   db " Astral - Bootloader ", 0
szStartedBootloaderRM:      db "Stage 1 - started in Real Mode (16 bit), TTY", 13, 10, 0
szReadingDisk:              db "Reading disk to find Stage 2", 13, 10, 0 



times 510 - ($-$$) db 0 ; Pad remaining 510 bytes with zeroes
dw 0xaa55               ; Bootloader magic value footer - marks this 512 byte sector bootable

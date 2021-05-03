; Tell NASM this is 16 bit (8086) code for real mode
bits 16

; Tell NASM to output all our labels with offset 0x7c00, because 
; BIOS will jump to this boot sector 0x7c00 and transfers control
org 0x7c00

; Configuration vars
%define BOOT_PROTECTED_MODE 0
%define DRIVE               0x80
;

jmp start

Init32b:
    cli                     ; Clear interrupt flag
    mov     ax, 0x2401      ; Interrupt 0x2401 - Enable A20 gate
    int     0x15            ; Interrupt vector - Miscellaneous system services

    lgdt    [gdt_pointer]   ; Load the gdt table
    mov     eax, cr0 
    or      eax, 0x1        ; Set the Protected Mode Enable (PE) bit on CR0 register
    mov     cr0, eax
    jmp     CODE_SEG:boot32 ; Long jump to the code segment

LoadDiskSector:
    mov     bx, 0       ; Offset into segment
    mov     dl, DRIVE   ; Drive? 0x80=harddisk
    mov     dh, 0       ; Head
    mov     Ch, 0       ; Track
    mov     ah, 2       ; Function - read sector
    int     0x13        ; Low level disk interrupt
    jc      .err
    ret

    .err:
        mov si, szErrLoadDiskSector
        call PrintInt
        ret
;
; Print a countdown on the screen with delays e.g. 543210
; 
; Args:
;   bl - countdown number to start from
;
PrintCountdown:
.L1:
    mov     cx, 0x0005  ; [cx:dx] intervals in uS
    mov     dx, 0x0000
    mov     ah, 0x86
    mov     al, 0       ; Needs to be cleared
    int     0x15        ; Wait (CX:DX = interval in uS) 

    mov     al, '0'     ; Decimal to ascii, -1, for printing
    add     al, bl
    dec     al
    mov     ah, 0xe
    int     0x10

    dec     bl          ; Counter from caller stored in BL
    jnz     .L1
    mov     si, szNewLine
    call    PrintInt
    ret

;
; General print interrupt function
;
; Args:
;   si - string to print for countdown
;
PrintInt:
    mov     ah, 0xe     ; Interrupt 0x0e - Write Character in TTY mode
.loop:
    lodsb               ; Load string byte from ds:si into al
    or      al, al           ; if al == 0
    jz      .end             ;   ret
    int     0x10            ; Interrupt vector - Video service 
    jmp     .loop
.end:
    ret

;
; Print a message with a countdown
;
; Args:
;   si - string to print for countdown
;
PrintTransitionMessage:
    call    PrintInt
    mov     bl, 5           ; Counter used in PrintCountdown uses BL
    call    PrintCountdown
    ret

;
; BIOS will load this 512 byte boot sector from the storage MBR into memory
;
start:
    mov     ax, 0x3
    int     0x10            ; Set VGA screen mode to 80x25

    mov     si, szBanner    ; Move memory location of string into register si
    call    PrintInt

    mov     si, szHello
    call    PrintInt

    ;
    ; Bassed on configuration params `BOOT_PROTECTED_MOD 
    ; - Continue in Real Mode and boot into a 16 bit bootloader, and boot a 16 bit OS
    ; - Call into Protected Mode and boot a 32 bit bootloader, then boot a 32 bit OS
    ;
    mov     ax, BOOT_PROTECTED_MODE
    cmp     ax, 1                           ; If (BOOT_PROTECTED_MODE)
    jnz     .Boot16BitBootloader
    mov     si, szCountdownToPM             ; Continue with 32 bit
    call    PrintTransitionMessage
    call    Init32b
    jmp     .End

    .Boot16BitBootloader:                   ; Else, we're continuing with 16 bit
    mov     si, szCountdownToBootLoader
    call    PrintTransitionMessage

    call    LoadDiskSector


    .End:
    ret

;
; Consts
;
szBanner:                   db "-------------------------------- Astral - Bootloader --------------------------", 13, 10, 0
szHello:                    db "Started bootloader in Real Mode (16 bit)", 13, 10, 0
szErrLoadDiskSector:        db "Err - LoadDiskSector", 13, 10, 0

szCountdownToPM:            db "About to transition to Protected Mode (32 bit) in .. ", 0  
szCountdownToBootLoader:    db "About to start our 16 bit bootloader in .. ", 0  
szNewLine:                  db 13, 10, 0

gdtStart:
; Define the null sector for the 64 bit gdt
; Null sector is required for memory integrity check
gdtNull:
    dd 0x00000000           ; All values in null entry are 0
    dd 0x00000000           ; All values in null entry are 0
    
; Define the code sector for the 64 bit GDT
gdtCode:
    dw 0xFFFF           ; Segment Limit (bits 0-15)
    dw 0x0000           ; Base low (bits 16-31)
    db 0x00             ; Base middle (bits 32-39)
    db 10011010b        ; Access:
                        ;   Pr - Present:               1
                        ;   Privl - Ring level:         00
                        ;   S - Descriptor type:        1
                        ;   Ex - Executable/code:       1
                        ;   DC - Direction/conforming:  0
                        ;   RW - Readable/writable:     1
                        ;   Ac - Accessed:              0        
    db 11001111b        ; Flags:
                        ;   Gr - Granularity (byte or page):    1
                        ;   Sz - Size (16 bit protected mode or 32 bit  protected mode): 1
                        ;   Reserved:                           00
    db 0x00             ; Base high (bits 56-63)
gdtData:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b        ; Access:
                        ;   Pr - Present:               1
                        ;   Privl - Ring level:         00
                        ;   S - Descriptor type:        1
                        ;   Ex - Code:                  0
                        ;   DC - Direction/conforming:  0
                        ;   RW - Readable/writable:     1
                        ;   Ac - Accessed:  
    db 11001111b
    db 0x00
gdtEnd:

gdt_pointer:
    dw gdtEnd - gdtStart
    dd gdtStart
CODE_SEG equ gdtCode - gdtStart
DATA_SEG equ gdtData - gdtStart


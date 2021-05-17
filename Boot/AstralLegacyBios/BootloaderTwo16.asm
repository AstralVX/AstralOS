;
; Bootloader - second stage
;
bits 16

%include "Config.asm"

; Tell NASM to output all our labels with offset 0x7E00
org BOOTLOADER_SECOND_STAGE_ADDR

jmp main


; Start
;dd 0x41414141               ; Our second stage bootloader magic header

;
; Print a countdown string (e.g. 543210) with a delay after every print
;
; Args:
;   bl - starting counter value at max, which is decremented
;
; Clobbers:
;   n/a
;
StartCountdown:
    pusha
    inc     bl
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
    call    PrintStrInt
    popa
    ret


Init32b:
    cli                     ; Clear interrupt flag
    mov     ax, 0x2401      ; Function 0x2401 - Enable A20 gate
    int     0x15            ; Interrupt vector - Miscellaneous system services

    lgdt    [gdt_pointer]   ; Load the gdt table
    mov     eax, cr0 
    or      eax, 0x1        ; Set the Protected Mode Enable (PE) bit on CR0 register
    mov     cr0, eax
    
    jmp     CODE_SEG:boot32 ; Long jump to the selector `code segment` (offset into GDT, pointing at a 32bit PM code segment descriptor) 


main:
    mov     si, szIntroStage2
    call    PrintStrInt

    ;mov     si, szSwitchToVga
    ;call    PrintStrInt    
    ;mov     bl, 9
    ;call    StartCountdown

    ;mov     ax, 12
    ;int     0x10                            ; Set VGA screen mode to 12 (VGA 640*480 16 color)


;mov ah, 00h     ; tell the bios we'll be in graphics mode
;mov al, 13h
;int 10h         ; call the BIOS
; mov ah, 0Ch     ; set video mode
; mov bh, 0       ; set output vga
; mov al, 3       ; set initial color
; mov cx, 80       ; x = 0
; mov dx, 100       ; y = 0
; int 10h         ; BIOS interrupt


    call    Init32b


;
; Other file includes
;
%include "Print16.asm"
%include "Disk16.asm"
%include "BootloaderTwo32.asm"
%include "Print32.asm"

;
; Strings
;
szIntroStage2:                  db "Executing from Stage 2 Bootloader", 13, 10, 0
szSwitchToVga:                  db "Switching to VGA 640x480 in .. ", 0


;
; GDT
;
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

; End
times 0x2048 - ($-$$) db 0  ; Pad our stage 2 bootloader to 2048 bytes, so we don't copy garbage data from disk
dd 0x42424242               ; Our second stage bootloader magic value footer


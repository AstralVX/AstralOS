;
; Bootloader - second stage
;
bits 16

%include "Config.asm"

; Tell NASM to output all our labels with offset 0x7E00
org BOOTLOADER_SECOND_STAGE_ADDR

; Start
;dd 0x41414141               ; Our second stage bootloader magic header

; Init32b:
;     cli                     ; Clear interrupt flag
;     mov     ax, 0x2401      ; Function 0x2401 - Enable A20 gate
;     int     0x15            ; Interrupt vector - Miscellaneous system services

;     lgdt    [gdt_pointer]   ; Load the gdt table
;     mov     eax, cr0 
;     or      eax, 0x1        ; Set the Protected Mode Enable (PE) bit on CR0 register
;     mov     cr0, eax
;     jmp     CODE_SEG:boot32 ; Long jump to the code segment


; boot32:
;     mov ax, DATA_SEG    ; Set all segments to point to data segment
;     mov ds, ax
;     mov es, ax
;     mov fs, ax
;     mov gs, ax
;     mov ss, ax

;     mov esi, szHello32
;     mov ebx, 0xb8000    ; VGA text memory mapped address 0xb8000
;     call printVga

;     cli
;     hlt                 ; Stop execution

    mov     si, szStage2
    call    PrintInt


;
; Other file includes
;
%include "Print16.asm"
%include "Disk16.asm"

;
; Strings
;
szStage2:                   db "Executing from Stage 2", 13, 10, 0


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
times 0x1000 - ($-$$) db 0  ; Pad remaining 510 bytes with zeroes
dd 0x42424242               ; Our second stage bootloader magic value footer


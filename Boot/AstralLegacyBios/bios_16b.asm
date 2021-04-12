; Tell NASM this is 16 bit code for real mode
bits 16

; Tell NASM to output all our labels with offset 0x7c00, because 
; BIOS will jump to this boot sector 0x7c00 and transfers control
org 0x7c00

jmp start

init_32b:
    cli                 ; Clear interrupt flag
    mov ax, 0x2401      ; Interrupt 0x2401 - Enable A20 gate
    int 0x15            ; Interrupt vector - Miscellaneous system services

    lgdt [gdt_pointer]  ; Load the gdt table
    mov eax, cr0 
    or eax, 0x1         ; Set the Protected Mode Enable (PE) bit on CR0 register
    mov cr0, eax
    jmp CODE_SEG:boot32 ; Long jump to the code segment

printBiosInt:
.loop:
    lodsb               ; Load string byte from ds:si into al
    or al, al           ; if al == 0
    jz .end             ;   ret
    int 0x10            ; Interrupt vector - Video service 
    jmp .loop
.end:
    ret

start:
    mov ax, 0x3
    int 0x10            ; Set vga text mode to a known value of 3

    mov si, szBanner    ; Move memory location of string into register si
    mov ah, 0xe         ; Interrupt 0x0e - Write Character in TTY mode
    call printBiosInt

    mov si, szHello
    mov ah, 0xe
    call printBiosInt

    call init_32b

;
; Consts
;
szBanner: db "--------------------------------- Astral BIOS ---------------------------------", 13, 10, 0
szHello: db "Starting BIOS in 16 bit", 13, 10, 0

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


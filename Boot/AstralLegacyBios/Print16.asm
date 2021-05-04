;
; This file provides printing functionaility in x86 real mode
;




;
; Print a countdown string (e.g. 543210) with a delay after every print
;
; Args:
;   bl - starting counter value at max, which is decremented
;
; Clobbers:
;   cx, dx, ax, bl, si
;
; PrintCountdown:
; .L1:
;     mov     cx, 0x0001  ; [cx:dx] intervals in uS
;     mov     dx, 0x0000
;     mov     ah, 0x86
;     mov     al, 0       ; Needs to be cleared
;     int     0x15        ; Wait (CX:DX = interval in uS) 

;     mov     al, '0'     ; Decimal to ascii, -1, for printing
;     add     al, bl
;     dec     al
;     mov     ah, 0xe
;     int     0x10

;     dec     bl          ; Counter from caller stored in BL
;     jnz     .L1
;     mov     si, szNewLine
;     call    PrintInt
;     ret

;
; Print a message with a delay included countdown
;
; Args:
;   si - string to print for countdown
;
; Clobbers:
;   bl
;
PrintTransitionMessage:
    call    PrintInt
    mov     bl, 5           ; Counter used in PrintCountdown uses BL
    ;call    PrintCountdown
    ret

;
; General print string interrupt function
;
; Args:
;   si - string to print for countdown
;
; Clobbers:
;   ax
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
; Print a 16 bit number in hex and gets zero padded e.g. 00F0
;
; Args
;   bx: the number
;
; Clobbers:
;   al, cx, bx
;
PrintHex:
    mov cx, 4
.Loop:
    mov al, bh
    shr al, 4

    cmp al, 0xA
    jb .Below0xA

    add al, 'A' - 0xA - '0'
.Below0xA:
    add al, '0'

    call PrintChar

    shl bx, 4
    loop .Loop

    ret

;
; Print a single character
;
; Args:
;   al: character to print
;
; Clobbers:
;   bx
;
PrintChar:
    pusha
    mov bx, 7
    mov ah, 0x0e
    int 0x10
    popa
    ret

;
; Generic strings
;
szNewLine:                  db 13, 10, 0
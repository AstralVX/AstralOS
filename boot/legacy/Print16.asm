;
; This file provides printing functionaility in x86 real mode
;


;
; Print 80 char line accross screen
;
; Args:
;   cl - dashes to print
;
; Clobbers:
;   ah, al, bx, cl
;
PrintDashedLine:
    mov     bl, 0x1F                        ; Colour char
.Loop:
    mov     al, '-'                         ; Pre-pend our banner with '---------------'
    call    PrintColourChar
    dec     cl
    jnz     .Loop    
    ret


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
    call    PrintStrInt
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
PrintStrInt:
    pusha
    mov     ah, 0xe     ; Interrupt 0x0e - Write Character in TTY mode
.loop:
    lodsb               ; Load string byte from ds:si into al
    or      al, al      ; if al == 0
    jz      .end        ;   ret
    int     0x10        ; Interrupt vector - Video service 
    jmp     .loop
.end:
    popa
    ret

;
; General print string interrupt function
;
; Args:
;   si - string to print for countdown
;   bl - colour (see subroutine PrintColourChar for colour styles)
;
; Clobbers:
;   ah, al
;
PrintStrColourInt:    
.loop:
    lodsb                   ; Load string byte from ds:si into al
    or      al, al          ; if al == 0
    jz      .end            ;   ret
    call    PrintColourChar
    jmp     .loop
.end:
    ret

;
; Print a 16 bit number in hex and gets zero padded e.g. 00F0
;
; Args
;   bx: the ascii number
;
; Clobbers:
;   al, cx, bx
;
PrintHex:
    pusha
    mov cx, 4
.Loop:
    mov al, bh
    shr al, 4

    cmp al, 0xA
    jb .Below0xA

    add al, 'A' - 0xA - '0'
.Below0xA:
    add al, '0'
    mov ah, 0x0E
    int 0x10

    shl bx, 4
    loop .Loop
    popa
    ret

;
; Print a single character 
;
; Args:
;   al: character to print
;   bx: bl = text/bg colour, top nibble = bg, bottom nibble = text. E.g. 1F = (blue bg, white text)
;       0 = black, 1 = blue, 2 = green, 3 = cyan, 4 = red, 5 = pink, 6 = brown, 7 = light grey, 8 = dark grey,
;       9 = light blue, A = light green, B = light cyan, C = light red, D = light pink, E = yellow, F = white
;
; Clobbers:
;   bh, ah, cx
;
PrintColourChar:
    pusha

    cmp al, 0x20            ; if al < 0x20 (' ')
    jl .ControlChar         ;   print as ControlChar
    cmp al, 0x7E            ; else if al > 0x7E ('~')
    jg .ControlChar         ;   print as ControlChar 

    .PrintableChar:         ; else it's a printable char
    mov     bh, 0x00        ; Set to 0, though bl is the main colour
    mov     cx, 1           ; Function 9 uses CX as a counter, but since we are only print a single char, set to 1
    mov     ah, 0x09        ; Function 9 = Write Character and attribute at cursor (will print even control chars)
    int     0x10            ; Int 10 - Video service

    .ControlChar:
    mov ah, 0x0E            ; Function 9 = Write Character in TTY mode (doesn't print control chars but does appropiate behaviour like new line)
    int 0x10                ; Int 10 - Video service

    .End:
    popa
    ret

;
; Generic strings
;
szNewLineCarriageRet:                   db 13, 10, 0
;
; Print a string to the 'text screen video memory'
;
; Args:
;   esi = text string
;
; Clobbers:
;   eax, ebx
;
PrintStrVgaTextMem:
    mov     ebx, [vgaLine]
    imul    ebx, (80*2)     ; 0x80 columns per row in 80x25, and each VGA pixel consumes 2 bytes (ascii char, colour)
    add     ebx, 0xb8000    ; VGA text memory mapped address 0xB8000 (usable even in VGA 640x480 mode)
.loop:
    lodsb                   ; Load string byte from ds:si into al
    or      al, al          ; if al == 0
    jz      .end            ;   ret
    or      eax, 0x0200     ; Character colour
    mov     word [ebx], ax  ;
    add     ebx, 2          ;
    jmp     .loop
.end:
    inc     dword [vgaLine] ; Move to next line for next string print
    ret


;
; Convert a DWORD to a string of 8 chars e.g. 0xABCD1234 to "ABCD1234"
;
; Args
;   ecx: output char pointer of at least 8 bytes (caller must alloc 9 bytes to inc NULL)
;   edx: input 32 bit number to convert
;
DwordToHexstring:
    push   edi              ; Save a call-preserved register for scratch space
    mov    edi, ecx         ; Out pointer
    mov    eax, edx         ; In number

    mov    ecx, 8           ; 8 hex digits, fixed width zero-padded
.digit_loop:                ; do {
    rol    eax, 4           ; rotate the high 4 bits to the bottom

    mov    edx, eax
    and    edx, 0x0f        ; and isolate 4-bit integer in EDX

    movzx  edx, byte [hex_lut + edx]
    mov    [edi], dl        ; copy a character from the lookup table
    inc    edi              ; loop forward in the output buffer

    dec    ecx
    jnz    .digit_loop      ; } while (--ecx)

    pop    edi
    ret


SECTION .RODATA
    hex_lut:  db  "0123456789ABCDEF"
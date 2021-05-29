;
; Print a string to the 'text screen video memory', where we hold a global
; x and y offset into the linear buffer. 
; Use \n to get a new line, otherwise it prints from the previous ending
;
; Args:
;   esi = text string
;
; Clobbers:
;   
;
PrintStrVgaTextMem:
    pusha
    xor     edx, edx
    xor     ecx, ecx        ; Count to hold string size
    mov     ebx, [xyText]
    add     ebx, 0xb8000    ; VGA text memory mapped address 0xB8000 (usable even in VGA 640x480 mode)
.loop:
    lodsb                   ; Load string byte from ds:si into al

    or      al, al          ; if al == 0
    jz      .finish         ;   ret

    cmp     al, 0xA         ; else if al == '\n'
    jnz     .write          
    mov     edx, 1          ;   found new line
    inc     ecx             ;   Char count of input string ++
    jmp     .finish         ;   ret

.write:
    mov     ah, 02h         ; Character colour, top nibble
    mov     word [ebx], ax  ; Write coloured char into VGA linear text buffer
    add     ebx, 2          ; Move to next text index in buffer
    inc     ecx             ; Char count of input string ++
    jmp     .loop
    
.finish:
    imul    ecx, 2          ; Since each text printed consists of 2 bytes
    add     [xyText], ecx   ; Update the global x and y offset for out linear text buffer

    cmp     edx, 1          ; If new line was found
    jnz     .end
    
    ; Round the linear text buffer up to the next 80 (hence next Y line)
    ;   addr = ((0xb8123 + 80 - 1) / 80) * 80;
    ;   80*2 used in code, as remember each text consumes 2 bytes in buffer
    mov     eax, (80*2)
    add     eax, [xyText]
    mov     ecx, (80*2)
    mov     edx, 0
    div     ecx             ; Unsigned div EDX:EAX (0:B8000) by ECX (80*2) = result stored in EAX = quotient, EDX = remainder
    mov     edx, eax        ; Ignore remainder and keep quotient
    mov     eax, (80*2)
    imul    eax, edx        ; Quotient * (80*2) = new linear text address offset for a new line
    mov     [xyText], eax

.end:
    popa
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

    mov byte [edi], 0       ; Append NULL at end

    pop    edi
    ret


SECTION .RODATA
    hex_lut:  db  "0123456789ABCDEF"
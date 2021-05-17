;
; Print a string to the 'text screen video memory'
;
; Args:
;   esi = text string
;   ebx = row offset (e.g. 0 = top line, 1 = line after etc)
;
; Clobbers:
;   eax, ebx
;
PrintToVgaTextMemory:
    imul ebx, (80*2)    ; 0x80 columns per row in 80x25, and each VGA pixel consumes 2 bytes (ascii char, colour)
    add ebx, 0xb8000    ; VGA text memory mapped address 0xB8000 (usable even in VGA 640x480 mode)
.loop:
    lodsb               ; Load string byte from ds:si into al
    or al, al           ; if al == 0
    jz .end             ;   ret
    or eax, 0x0200      ; Character colour
    mov word [ebx], ax  ;
    add ebx, 2          ;
    jmp .loop
.end:
    ret

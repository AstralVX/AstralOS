bits 32                 ; Now we're in 32 bit Protected Mode (so can't call BIOS interrupts anymore) with virtual addressing 

printVga:
.loop:
    lodsb               ; Load string byte from ds:si into al
    or al, al           ; if al == 0
    jz .end             ;   ret
    or eax, 0x0200      ; Chracter colour
    mov word [ebx], ax  ;
    add ebx, 2          ;
    jmp .loop
.end:
    ret








;
; Consts
;
szHello32: db "Started BIOS in 32 bit", 13, 10, 0

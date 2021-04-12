bits 32                 ; Now we're in protected mode, so can't call BIOS interrupts anymore

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






boot32:
    mov ax, DATA_SEG    ; Set all segments to point to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esi, szHello32
    mov ebx, 0xb8000    ; VGA text memory mapped address 0xb8000
    call printVga

    cli
    hlt                 ; Stop execution

;
; Consts
;
szHello32: db "Started BIOS in 32 bit", 13, 10, 0

times 510 - ($-$$) db 0 ; Pad remaining 510 bytes with zeroes
dw 0xaa55               ; Bootloader magic value footer - marks this 512 byte sector bootable

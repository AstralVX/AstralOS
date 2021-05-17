bits 32                 ; Now we're in 32 bit Protected Mode (so can't call BIOS interrupts anymore) with virtual addressing 

boot32:
    mov ax, DATA_SEG    ; Set all segments to point to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esi, szHelloFrom32b
    mov ebx, 9
    call PrintToVgaTextMemory
    
    cli
    hlt




;
; Consts (32 bit, video memory doesn't process control chars)
;
szHelloFrom32b: db "Transitioned to Protected Mode (32 bit)", 0

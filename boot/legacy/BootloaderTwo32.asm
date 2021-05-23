bits 32                     ; Now we're in 32 bit Protected Mode (so can't call BIOS interrupts anymore) with virtual addressing 

global      vgaLine

SECTION .data  
    vgaLine:    dd  0xB     ; Used in Print32 VGA print, the initial offset Y row for text in protected mode




GetKernelEntryPoint:
    ;pasre dos header here

    ret

;
; Jmp'ed to from BootloaderTwo16.asm when transition from RM to PE
;
boot32:
    mov ax, DATA_SEG    ; Set all segments to point to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esi, szHelloFrom32b
    call PrintToVgaTextMemory

    mov esi, szHelloFrom32b
    call PrintToVgaTextMemory

    mov esi, szHelloFrom32b
    call PrintToVgaTextMemory

    ;mov dword [0xb8000], 0x20692048
    
;mov edi,0x0A0000
;mov al,0x02      ; the color of the pixel
;mov [edi],al

    ; load kernel, if some code runs, change vid mode to vga and do gfx work from C

    call GetKernelEntryPoint

    cli
    hlt


;
; Consts (32 bit, video memory doesn't process control chars)
;
szHelloFrom32b: db "Transitioned to Protected Mode (32 bit)", 0

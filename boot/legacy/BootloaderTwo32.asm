bits 32                     ; Now we're in 32 bit Protected Mode (so can't call BIOS interrupts anymore) with virtual addressing 

global      vgaLine

SECTION .data  
    vgaLine:    dd  0xB     ; Used in Print32 VGA print, the initial offset Y row for text in protected mode



SECTION .text

GetKernelEntryPoint:
    ;pasre dos header here
    mov     eax, [KERNEL_ADDR_32]

    ret

;
; Jmp'ed to from BootloaderTwo16.asm when transition from RM to PE
;
boot32:
    push    ebp         ; Create stack frame
    mov     ebp, esp
    sub     esp, 0x9    ; Local stack varaibles
                        ; [0 - 9]: char hexString[9], 8 bytes used for number, 1 for null

    mov ax, DATA_SEG    ; Set all segments to point to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esi, szHelloFrom32b
    call PrintStrVgaTextMem

    mov esi, szHelloFrom32b
    call PrintStrVgaTextMem

    mov esi, szHelloFrom32b
    call PrintStrVgaTextMem

    ;mov dword [0xb8000], 0x20692048
    
;mov edi,0x0A0000
;mov al,0x02      ; the color of the pixel
;mov [edi],al

    ; load kernel, if some code runs, change vid mode to vga and do gfx work from C

    ;call GetKernelEntryPoint

    
;DEBUGBREAK

    lea ecx, [ebp - 8]          ; &hexString
    mov edx, 0xABCD1234
    call DwordToHexstring

    lea esi, [ebp - 8]
    call PrintStrVgaTextMem


    cli
    hlt

    mov     esp, ebp    ; Unwind stack frame
    pop     ebp
    ret

;
; Consts (32 bit, video memory doesn't process control chars)
;
szHelloFrom32b: db "Transitioned to Protected Mode (32 bit)", 0

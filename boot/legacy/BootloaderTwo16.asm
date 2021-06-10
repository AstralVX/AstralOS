;
; Bootloader - second stage
;
bits 16

%include "Config.asm"

; Tell NASM to output all our labels with offset 0x7E00
org BOOTLOADER_SECOND_STAGE_ADDR

; Data section that holds initialized data, i.e. global vars
SECTION .data
    g_linearFrameBuffer:    dd 0
    g_width:                dd 0
    g_height:               dd 0

; Unitialized global variables that doesn't occupy disk space
SECTION .bss
    STRUC VBE_INFO_STRUCTURE
        .signature      RESB 4      ; must be "VESA" to indicate valid VBE support
        .version        RESW 1      ; VBE version  high byte is major version, low byte is minor version
        .oem            RESD 1      ; segment:offset pointer to OEM
        .capabilities   RESD 1      ; bitfield that describes card capabilities
        .video_modes    RESD 1      ; segment:offset pointer to list of supported video modes (+18h)
        .video_memory   RESW 1      ; amount of video memory in 64KB blocks
        .software_rev   RESW 1      ; software revision
        .vendor         RESD 1      ; segment:offset to card vendor string
        .product_name   RESD 1      ; segment:offset to card model name
        .product_rev    RESD 1      ; segment:offset pointer to product revision
        .reserved       RESB 222    ; reserved for future expansion
        .oem_data       RESB 256    ; OEM BIOSes store their strings in this area
        alignb 4
    ENDSTRUC

    STRUC VBE_MODE_INFO_STRUCTURE
        .attributes                RESW 1   ; deprecated, only bit 7 should be of interest to you, and it indicates the mode supports a linear frame buffer.
        .window_a                  RESB 1   ; deprecated
        .window_b                  RESB 1   ; deprecated
        .granularity               RESW 1   ; deprecated used while calculating bank numbers
        .window_size               RESW 1
        .segment_a                 RESW 1
        .segment_b                 RESW 1
        .win_func_ptr              RESD 1   ; deprecated used to switch banks from protected mode without returning to real mode
        .pitch                     RESW 1   ; number of bytes per horizontal line
        .width                     RESW 1   ; width in pixels (offset 18-19)
        .height                    RESW 1   ; height in pixels
        .w_char                    RESB 1   ; unused...
        .y_char                    RESB 1   ; ...
        .planes                    RESB 1
        .bpp                       RESB 1   ; bits per pixel in this mode
        .banks                     RESB 1   ; deprecated total number of banks in this mode
        .memory_model              RESB 1
        .bank_size                 RESB 1   ; deprecated size of a bank, almost always 64 KB but may be 16 KB...
        .image_pages               RESB 1
        .reserved0                 RESB 1

        .red_mask                  RESB 1
        .red_position              RESB 1
        .green_mask                RESB 1
        .green_position            RESB 1
        .blue_mask                 RESB 1
        .blue_position             RESB 1
        .reserved_mask             RESB 1
        .reserved_position         RESB 1
        .direct_color_attributes   RESB 1      

        .framebuffer               RESD 1    ; phys addr of the linear frame buffer write here to draw to the screen
        .off_screen_mem_off        RESD 1
        .off_screen_mem_size       RESW 1    ; size of memory in the framebuffer but not being displayed on the screen
        .reserved1                 RESB 206
        alignb 1
    ENDSTRUC
    %define SIZEOF_VBE_MODE_INFO_STRUCTURE 256

; Code section
SECTION .text

jmp main

; Start
;dd 0x41414141               ; Our second stage bootloader magic header

;
; Set video mode to VESA whilst still in real mode
;
; Stack:
;   [bp - 0x02]: local arg 1..
;   [bp + 0x00]: 
;   [bp + 0x02]: ret
; Args:
;   [bp + 0x04]: UINT16 width
;   [bp + 0x06]: UINT16 height
;   [bp + 0x08]: UINT16 bitsperpixel
;
; Clobbers:
;   All, including ES
;
SetGraphicsToVesa:    
    push    bp                          ; Create stack frame
    mov     ax, ss                      ; Video interrupts in this subroutine heavily uses segment 'ES' ES:DI for pointers, so temporairly
    mov     es, ax                      ; set ES to our Stack Segment (SS) at 0x6000, so our SS:BP from `sub sp, ..` matches ES
    mov     bp, sp              
    sub     sp, 0x306                   ; Local stack variables
                                        ; [000h - 1FFh]: [bp-04h]:  UCHAR   vbeInfoStruct[512]
                                        ; [200h - 201h]: [bp-202h]: UINT16  videoModeOffset
                                        ; [202h - 203h]: [bp-204h]: UINT16  videoModeSegment
                                        ; [204h - 205h]: [bp-206h]: UINT16  videoMode                       // The video mode itself e.g. 0x115
                                        ; [206h - 305h]: [bp-306h]: VBE_MODE_INFO_STRUCTURE vbeModeInfo     // Sizeof 256

    mov     ax, 0x4F00                  ; Function - Get VBE BIOS info
    lea     bx, word [bp-04h]           ; &vbeInfoStruct into es:di, as interrupt need at specific ES:DI segment
    mov     word[es:di], bx
    mov     word[es:di + VBE_INFO_STRUCTURE.signature],     'VB'        ; On input vbeInfoStruct.Signature must be 'VBE2'
    mov     word[es:di + VBE_INFO_STRUCTURE.signature + 2], 'E2'
    int     0x10                        ; Interrupt - Video services

    cmp     ax, 0x004F				    ; Verify BIOS support VBE, as it should respond with 004F if success
    jz      .validateSignatureResponse
    mov     si, szErrVbeSupport
    jmp     .error
    
.validateSignatureResponse:
    mov     si, szErrVesaSig
    mov     ax, [es:di + VBE_INFO_STRUCTURE.signature]  ; Verify the BIOS responsed with 'VESA' in the Signature
    cmp     ax, 'VE'

    jnz     .error
    mov     ax, [es:di + 2 + VBE_INFO_STRUCTURE.signature]  
    cmp     ax, 'SA'
    jnz     .error

; Get list of video modes from segment:offset pointer
.loadVideoModes:
    ;mov     si, szFoundVidModes        ; Debug print
    ;call    PrintStrInt                ; Debug print

    mov     ax, [es:di + VBE_INFO_STRUCTURE.video_modes]        ; videoModeOffset
    mov     word [bp - 202h], ax
    mov     ax, [es:di + VBE_INFO_STRUCTURE.video_modes + 2]    ; videoModeSegment
    mov     word [bp - 204h], ax    

; Following subroutine has VideoMode segment:offset at [fs:si]
.findNextMode:
    mov     ax, word [bp - 202h]        ; videoModeOffset
    mov     si, ax
    mov     fs, word [bp - 204h]        ; videoModeSegment

    mov     dx, word [fs:si]    
    add     si, 2
    mov     word [bp - 202h], si        ; videoModeOffset += 2
    mov     word [bp - 206h], dx        ; Save mode found

    cmp     dx, 0xFFFF
    mov     si, szErrVideoModeNotFound
    jz      .errLastVidMode

    ;mov     bx, dx                      ; Debug print
    ;call    PrintHex                    ; Debug print
    ;mov     si, szComma                 ; Debug print
    ;call    PrintStrInt                 ; Debug print

    mov     ax, 0x4F01				    ; Function - Get VBE mode info
    mov     cx, word [bp - 206h]        ; Video Mode
    lea     di, word [bp - 306h]        ; &vbeModeInfo    
    int     0x10                        ; Load mode infos at VBE_MODE_INFO_LABELS

    cmp     ax, 0x004F
    mov     si, szErr10_4F01
    jnz     .error                       ; Check for success code in AX

    ; Compare modes found with desired width/height/bpp
    mov     bx, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.width]
    cmp     bx, word [ss:bp + 0x4]         ; Arg width    
    jnz     .findNextMode

    mov     bx, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.height]
    cmp     bx, word [ss:bp + 0x6]         ; Arg height
    jnz     .findNextMode

    mov     bl, byte [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.bpp]
    cmp     bl, byte [ss:bp + 0x8]         ; Arg bits per pixel
    jnz     .findNextMode

    ; Copy linear frame buffer/width/height into global vars to be used in 32-bit Protected Mode
    mov     ax, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.framebuffer]
    mov     [g_linearFrameBuffer], ax
    mov     ax, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.framebuffer + 2]
    mov     [g_linearFrameBuffer + 2], ax
    mov     ax, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.width]
    mov     [g_width], ax
    mov     ax, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.height]
    mov     [g_height], ax

    ; Print found mode
    mov     si, szVideoModeFound
    call    PrintStrInt
    mov     bx, word [bp - 206h]
    call    PrintHex
    mov     si, szComma
    call    PrintStrInt
    mov     si, sz800x600x32
    call    PrintStrInt
    mov     si, szLfb
    call    PrintStrInt
    mov     bx, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.framebuffer+2]
    call    PrintHex
    mov     bx, word [ss:bp - 0x306 + VBE_MODE_INFO_STRUCTURE.framebuffer]
    call    PrintHex
    mov     si, szNewLineCarriageRet
    call    PrintStrInt

    mov     si, szSwitchToVesa
    call    PrintStrInt
    mov     bl, 3
    call    StartCountdown

    ; Set video mode
    mov     ax, 0x4F02                      ; Function - Set VBE mode
    mov     bx, word [bp - 206h]            ; Bits 0 - 13 are the VideoMode
    or      bx, 0x4000                      ; Enable linear frame buffer, by setting bit 14
    int     0x10                            ; Interrupt - Video services

	cmp     ax, 0x004F
    mov     si, szErrSetVbeMode
	jnz     .error

    clc
    jmp     .end

.errLastVidMode:
    mov     si, szErrVideoModeNotFound
    call    .error    
.error:
    call    PrintStrInt
.end:
    ;DEBUGBREAK
    mov     sp, bp                  ; Unwind stack frame
    pop     bp
    ret     6                       ; Return and increase SP by 3 word args we pushed onto the stack

;
; Print a countdown string (e.g. 543210) with a delay after every print
;
; Args:
;   bl - starting counter value at max, which is decremented
;
; Clobbers:
;   n/a
;
StartCountdown:
    pusha
    inc     bl
.L1:
    mov     cx, 0x0005  ; [cx:dx] intervals in uS
    mov     dx, 0x0000
    mov     ah, 0x86
    mov     al, 0       ; Needs to be cleared
    int     0x15        ; Wait (CX:DX = interval in uS) 

    mov     al, '0'     ; Decimal to ascii, -1, for printing
    add     al, bl
    dec     al
    mov     ah, 0xe
    int     0x10
    mov     al, ' '
    int     0x10

    dec     bl          ; Counter from caller stored in BL
    jnz     .L1
    mov     si, szNewLineCarriageRet
    call    PrintStrInt
    popa
    ret


Init32b:
    cli                     ; Clear interrupt flag
    mov     ax, 0x2401      ; Function 0x2401 - Enable A20 gate
    int     0x15            ; Interrupt vector - Miscellaneous system services

    lgdt    [gdt_pointer]   ; Load the gdt table
    mov     eax, cr0 
    or      eax, 0x1        ; Set the Protected Mode Enable (PE) bit on CR0 register
    mov     cr0, eax
    
    jmp     CODE_SEG:boot32 ; Long jump to the selector `code segment` (offset into GDT, pointing at a 32bit PM code segment descriptor) 


main:
    mov     si, szIntroStage2
    call    PrintStrInt

    mov     si, szLoadingKernel
    call    PrintStrInt

    ;
    ; Read kernel into mem at 1MB (whilst we can't access from realmode, the disk controller will write it there no problem)
    ; When we transition into protected mode later, we don't have access to BIOS interrupts, and too much effort to write 
    ; a disk/floppy controller in x86 asm to read the kernel image from disk and map it in. So just do it now with BIOS INT!
    ;
    push    es                                  ; Save previous ES
    mov     ax, KERNEL_ADDR_ES                  ; ES:BX is the larger target memory location of disk sectors
    mov     es, ax
    mov     bx, KERNEL_ADDR_BX
    mov     al, 8                               ; Read 8 sectors (4096 bytes)
    mov     ch, 0                               ; Cylinder 0
    mov     cl, 9                               ; Sector number 2 (0x200 to 0x400)
    mov     dh, 0                               ; Head number 0
    mov     dl, DRIVE                           ; Drive number (QEMU index)
    call    DiskIntReadSectors
    pop     es

    ;mov     si, szSwitchToVga
    ;call    PrintStrInt    
    ;mov     bl, 9
    ;call    StartCountdown

    ;mov     ax, 0x10
    ;int     0x10                            ; Set VGA screen mode to 12 (VGA 640*480 16 color)


; mov ah, 00h     ; tell the bios we'll be in graphics mode
; mov al, 13h
; int 10h         ; call the BIOS
; mov ah, 0Ch     ; set video mode
; mov bh, 0       ; set output vga
; mov al, 3       ; set initial color
; mov cx, 80       ; x = 0
; mov dx, 100       ; y = 0
; int 10h         ; BIOS interrupt

    push    es
    push    32                  ; bits per pixel
    push    600                 ; height
    push    800                 ; width
    call    SetGraphicsToVesa
    pop     es

    call    Init32b


;
; Other file includes
;
%include "Print16.asm"
%include "Disk16.asm"
%include "BootloaderTwo32.asm"
%include "Print32.asm"
%include "video32.asm"

;
; Strings
;
szIntroStage2:                  db "Executing from Stage 2 Bootloader", 13, 10, 0
szLoadingKernel:                db "Loading kernel into memory", 13, 10, 0
szErrVbeSupport:                db "Err - BIOS doesn't support VBE", 13, 10, 0
szErrVesaSig:                   db "Err - VESA signature failed", 13, 10, 0
szErr10_4F01:                   db "Err - INT 10h, 4F01h failed", 13, 10, 0
szErrVideoModeNotFound:         db 13, 10, "Err - searched all VideoModes and couldn't find target", 13, 10, 0
szVideoModeFound:               db "Found ideal VideoMode ", 0
sz800x600x32:                   db "800 x 600 x 32. ", 13, 10, 0
szLfb:                          db "Linear Frame Buffer at DWORD: ", 0
szComma:                        db ", ", 0
szFoundVidModes:                db "Found VideoModes: ", 0
szSwitchToVesa:                 db "Switching to VESA video mode in .. ", 0
szErrSetVbeMode:                db "Err - INT 10h, 4F02h failed", 13, 10, 0

;
; GDT
;
gdtStart:
; Define the null sector for the 64 bit gdt
; Null sector is required for memory integrity check
gdtNull:
    dd 0x00000000           ; All values in null entry are 0
    dd 0x00000000           ; All values in null entry are 0
    
; Define the code sector for the 64 bit GDT
gdtCode:
    dw 0xFFFF           ; Segment Limit (bits 0-15)
    dw 0x0000           ; Base low (bits 16-31)
    db 0x00             ; Base middle (bits 32-39)
    db 10011010b        ; Access:
                        ;   Pr - Present:               1
                        ;   Privl - Ring level:         00
                        ;   S - Descriptor type:        1
                        ;   Ex - Executable/code:       1
                        ;   DC - Direction/conforming:  0
                        ;   RW - Readable/writable:     1
                        ;   Ac - Accessed:              0        
    db 11001111b        ; Flags:
                        ;   Gr - Granularity (byte or page):    1
                        ;   Sz - Size (16 bit protected mode or 32 bit  protected mode): 1
                        ;   Reserved:                           00
    db 0x00             ; Base high (bits 56-63)
gdtData:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b        ; Access:
                        ;   Pr - Present:               1
                        ;   Privl - Ring level:         00
                        ;   S - Descriptor type:        1
                        ;   Ex - Code:                  0
                        ;   DC - Direction/conforming:  0
                        ;   RW - Readable/writable:     1
                        ;   Ac - Accessed:  
    db 11001111b
    db 0x00
gdtEnd:

gdt_pointer:
    dw gdtEnd - gdtStart
    dd gdtStart
CODE_SEG equ gdtCode - gdtStart
DATA_SEG equ gdtData - gdtStart

; End
;times 0x2048 - ($-$$) db 0  ; Pad our stage 2 bootloader to 2048 bytes, so we don't copy garbage data from disk
;dd 0x42424242               ; Our second stage bootloader magic value footer


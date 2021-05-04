; Tell NASM this is 16 bit (8086) code for real mode
bits 16

%include "Config.asm"

; Tell NASM to output all our labels with offset 0x7c00, because 
; BIOS will jump to this boot sector 0x7c00 and transfers control
org 0x7c00

jmp 0x0000:main

;
; BIOS will load this 512 byte boot sector from the storage MBR into memory
;
main:
    ;
    ; Initialise essential segment registers
    ;
    xor ax, ax
    mov ds, ax
    mov es, ax

    ;
    ; Setup a stack range at from 0x6000 to 0x7000, stack will grow downwards
    ; Since our bootloader is loaded at 0x7C00, we have almost 30KiB below free
    ; Disable interrupts to update ss:sp atomically (only required for <= 286 (8088)), then re-enable
    ;   N.b. interrupts are disabled for 1 inst after mov ss, ...
    ;
    cli
    mov     ax, 0x6000
    mov     ss, ax
    mov     sp, 0x7000
    sti

    mov     ax, 0x3
    int     0x10                            ; Set VGA screen mode to 3 (80x25)


    mov     ah, 80
.Loop:
    mov     al, '-'                         ; Pre-pend our banner with '-------'
    call    PrintChar
    dec     ah
    jnz     .Loop

    mov     si, szBanner                    ; Move memory location of string into register SI
    call    PrintInt                        ; All print functions, require SI to be set to the string 

    mov     si, szStartedBootloaderRM
    call    PrintInt



    ;
    ; Bassed on configuration params `BOOT_PROTECTED_MODE` 
    ; - Continue in Real Mode and boot into a 16 bit OS, and boot a 16 bit OS
    ; - Call into Protected Mode and boot a 32 bit OS
    ;
    ;mov     ax, BOOT_PROTECTED_MODE
    ;cmp     ax, 1                           ; If (BOOT_PROTECTED_MODE)
    ;jnz     .Boot16BitBootloader
    ;mov     si, szCountdownToPM             ; Continue with 32 bit
    ;call    PrintTransitionMessage
    ;call    Init32b
    ;jmp     .End

    .Boot16BitBootloader:                   ; Else, we're continuing with 16 bit
    mov     si, szCountdownToBootLoader
    call    PrintTransitionMessage

    call    LoadDiskSector
    ;jmp     0x0000:main

    jmp 0x0000:BOOTLOADER_SECOND_STAGE_ADDR

    hlt
    ret

;
; Other file includes
;
%include "Print16.asm"
%include "Disk16.asm"

;
; Consts
;
szBanner:                   db "-------------------------------- Astral - Bootloader ---------------------------", 13, 10, 0
;szBanner:                   db "Astral - Bootloader", 13, 10, 0
szStartedBootloaderRM:      db "Stage 1 - started in Real Mode (16 bit)", 13, 10, 0

;szCountdownToPM:            db "About to transition to Protected Mode (32 bit) in .. ", 0  
szCountdownToBootLoader:    db "Reading disk to find Stage 2", 13, 10, 13, 10, 0 



times 510 - ($-$$) db 0 ; Pad remaining 510 bytes with zeroes
dw 0xaa55               ; Bootloader magic value footer - marks this 512 byte sector bootable

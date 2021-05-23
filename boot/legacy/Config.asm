;
; Configuration vars
;

%define BOOT_PROTECTED_MODE             0
;
; Index of storage - in QEMU this vale is from 'index=0,if=floppy'
;
%define DRIVE                           0
;
; Address the bootlodaer Stage 2 will be loaded at
; 
%define BOOTLOADER_SECOND_STAGE_ADDR        0x7E00
;
; Address the kernel will be loaded at 1000h:0000h (10000h)
;
%define KERNEL_ADDR_ES                      0x1000
%define KERNEL_ADDR_BX                      0x0000
%define KERNEL_ADDR_32                      0x10000

;
; Poor mans breakpoint - infinite loop, then requires manual debugger break in
;   Jmp to the ($) current address of the instruction, same as jmp -2
; To continue in GDB step over 2 instructions:
;    set $eip += 2
;
%define DEBUGBREAK                          jmp $
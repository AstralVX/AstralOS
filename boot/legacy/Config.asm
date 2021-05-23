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
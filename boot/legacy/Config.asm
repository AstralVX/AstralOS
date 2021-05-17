;
; Configuration vars
;

%define BOOT_PROTECTED_MODE             0
;
; Index of storage - in QEMU this vale is from 'index=0,if=floppy'
;
%define DRIVE                           0
;
; Address Stage 2 should be loaded at, and maximum size to occupy in memory
; 
%define BOOTLOADER_SECOND_STAGE_ADDR        0x7E00
%define BOOTLOADER_SECOND_STAGE_MAX_SIZE    0x1000
;

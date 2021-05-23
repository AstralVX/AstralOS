bits 32                     ; Now we're in 32 bit Protected Mode (so can't call BIOS interrupts anymore) with virtual addressing 

global  yText
global  xText

SECTION .bss
    ;
    ; DOS image header
    ;
    STRUC IMAGE_DOS_HEADER
        .e_magic      RESW 1   ; Magic number
        .e_cblp       RESW 1   ; Bytes on last page of file
        .e_cp         RESW 1   ; Pages in file
        .e_crlc       RESW 1   ; Relocations
        .e_cparhdr    RESW 1   ; Size of header in paragraphs
        .e_minalloc   RESW 1   ; Minimum extra paragraphs needed
        .e_maxalloc   RESW 1   ; Maximum extra paragraphs needed
        .e_ss         RESW 1   ; Initial (relative) SS value
        .e_sp         RESW 1   ; Initial SP value
        .e_csum       RESW 1   ; Checksum
        .e_ip         RESW 1   ; Initial IP value
        .e_cs         RESW 1   ; Initial (relative) CS value
        .e_lfarlc     RESW 1   ; File address of relocation table
        .e_ovno       RESW 1   ; Overlay number
        .e_res        RESW 4   ; Reserved words
        .e_oemid      RESW 1   ; OEM identifier (for e_oeminfo)
        .e_oeminfo    RESW 1   ; OEM information; e_oemid specific
        .e_res2       RESW 10  ; Reserved words
        .e_lfanew     RESD 1   ; File address of new exe header
    ENDSTRUC

    ;
    ; Represents the optional header format.
    ; https://docs.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-image_optional_header32
    ;
    STRUC IMAGE_OPTIONAL_HEADER32
        .Magic                          RESW 1 ; For 32 bit should be IMAGE_NT_OPTIONAL_HDR32_MAGIC
        .MajorLinkerVersion             RESB 1 ; The major version number of the linker.
        .MinorLinkerVersion             RESB 1 ; The minor version number of the linker.
        .SizeOfCode                     RESD 1 ; The size of the/all code sections, in bytes.
        .SizeOfInitializedData          RESD 1 ; The size of the/all initialized data section, in bytes.
        .SizeOfUninitializedData        RESD 1 ; The size of the/all uninitialized data section, in bytes.
        .AddressOfEntryPoint            RESD 1 ; A pointer to the entry point function, relative to the image base address.
        .BaseOfCode                     RESD 1 ; A pointer to the beginning of the code section, relative to the image base.
        .BaseOfData                     RESD 1 ; A pointer to the beginning of the data section, relative to the image base.
        .ImageBase                      RESD 1 ; The preferred address of the first byte of the image when it is loaded in memory.
        .SectionAlignment               RESD 1 ; The alignment of sections loaded in memory, in bytes.
        .FileAlignment                  RESD 1 ; The alignment of the raw data of sections in the image file, in bytes. 
        .MajorOperatingSystemVersion    RESW 1 ; The major version number of the required operating system.
        .MinorOperatingSystemVersion    RESW 1 ; The minor version number of the required operating system.
        .MajorImageVersion              RESW 1 ; The major version number of the image.
        .MinorImageVersion              RESW 1 ; The minor version number of the image.
        .MajorSubsystemVersion          RESW 1 ; The major version number of the subsystem.
        .MinorSubsystemVersion          RESW 1 ; The minor version number of the subsystem.
        .Win32VersionValue              RESD 1 ; Reserved.
        .SizeOfImage                    RESD 1 ; The size of the image, in bytes, including all headers. Must be a multiple of SectionAlignment.
        .SizeOfHeaders                  RESD 1 ; The combined size of the following headers.
        .CheckSum                       RESD 1 ; The image file checksum. 
        .Subsystem                      RESW 1 ; The subsystem required to run this image.
        .DllCharacteristics             RESW 1 ; The DLL characteristics of the image. 
        .SizeOfStackReserve             RESD 1 ; The number of bytes to reserve for the stack. 
        .SizeOfStackCommit              RESD 1 ; The number of bytes to commit for the stack.
        .SizeOfHeapReserve              RESD 1 ; The number of bytes to reserve for the local heap.
        .SizeOfHeapCommit               RESD 1 ; The number of bytes to commit for the local heap.
        .LoaderFlags                    RESD 1 ; Obsolete.
        .NumberOfRvaAndSizes            RESD 1 ; The number of directory entries in the remainder of the optional header.
        .DataDirectory                  RESD 1 ; A pointer to the first IMAGE_DATA_DIRECTORY structure in the data directory.
    ENDSTRUC

    ;
    ; Represents the COFF header format
    ;
    STRUC IMAGE_FILE_HEADER
        .Machine                RESW 1  ; Architecture type
        .NumberOfSections       RESW 1  ; Number of sections
        .TimeDateStamp          RESD 1  ; Low 32 bits of the time stamp of the image
        .PointerToSymbolTable   RESD 1  ; Offset of the symbol table, in bytes, or zero if no COFF symbol table exists
        .NumberOfSymbols        RESD 1  ; Number of symbols in the symbol table
        .SizeOfOptionalHeader   RESW 1  ; Size of the optional header, in bytes
        .Characteristics        RESW 1  ; Characteristics of the image
    ENDSTRUC

    STRUC IMAGE_NT_HEADERS32
        .Signature      RESD 1      ;
        .FileHeader     RESB 20     ; IMAGE_FILE_HEADER
        .OptionalHeader RESB 224    ; IMAGE_OPTIONAL_HEADER32
    ENDSTRUC

SECTION .data  
    xyText:     dd  (0xB * 80 * 2)  ; Used in Print32 VGA print, the initial X/Y offset 0xB for text in protected mode


SECTION .text

GetKernelEntryPoint:
    push    ebp                     ; Create stack frame
    mov     ebp, esp            
    sub     esp, 0x9                ; Local stack varaibles
                                    ; [0 - 9]: char hexString[9], 8 bytes used for number, 1 for null

    mov     eax, [KERNEL_ADDR_32 + IMAGE_DOS_HEADER.e_magic]
    cmp     ax, 0x5a4d              ; 'MZ'
    jnz     .end  
    lea     esi, szVerifiedKernelDos
    call    PrintStrVgaTextMem

    lea     eax, [KERNEL_ADDR_32]
    add     eax, [KERNEL_ADDR_32 + IMAGE_DOS_HEADER.e_lfanew]
    mov     ebx, dword [eax + IMAGE_NT_HEADERS32.Signature]
    cmp     bx, 0x4550              ; 'PE'
    jnz     .end  
    lea     esi, szVerifiedKernelNt
    call    PrintStrVgaTextMem

    lea     eax, dword [eax + IMAGE_NT_HEADERS32.OptionalHeader]
    mov     ebx, dword [eax + IMAGE_OPTIONAL_HEADER32.Magic]
    cmp     bx, 0x010B              ; IMAGE_NT_OPTIONAL_HDR32_MAGIC 0x010B
    jnz     .end  
    lea     esi, szVerifiedKernel32bImage
    call    PrintStrVgaTextMem

    mov     ebx, dword [eax + IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint]

lea     ebx, [KERNEL_ADDR_32]
mov     ebx, 0x104F0
;DEBUGBREAK
jmp     ebx


    ; lea     ecx, [ebp - 8]          ; &hexString
    ; mov     edx, eax
    ; call    DwordToHexstring    
    ; lea     esi, [ebp - 8]
    ; call    PrintStrVgaTextMem

.end:
    mov     esp, ebp                ; Unwind stack frame
    pop     ebp
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

    ;mov dword [0xb8000], 0x20692048
    
;mov edi,0x0A0000
;mov al,0x02      ; the color of the pixel
;mov [edi],al

    ; load kernel, if some code runs, change vid mode to vga and do gfx work from C

    call GetKernelEntryPoint



    mov esi, szAaa
    call PrintStrVgaTextMem

    
    mov esi, szHelloFrom32b
    call PrintStrVgaTextMem

    cli
    hlt

    mov     esp, ebp    ; Unwind stack frame
    pop     ebp
    ret

;
; Consts used in protected mode.
; New lines only supported at end of string, identified by 0xA.
;
szHelloFrom32b:                         db "Transitioned to Protected Mode", 0xA, 0
szVerifiedKernelDos                     db "Verified kernel DOS header 'MZ' 0x5A4D", 0xA, 0
szVerifiedKernelNt                      db "Verified kernel NT header  'PE' 0x4550", 0xA, 0
szVerifiedKernel32bImage                db "Verified kernel 32b image       0x010B", 0xA, 0
szAaa:                                  db "HELLO", 0
szNewLine:                              db 0xA, 0

bits 32                     ; Now we're in 32 bit Protected Mode (so can't call BIOS interrupts anymore) with virtual addressing 

global  yText
global  xText

SECTION .bss
    ;
    ; DOS image header
    ;
    STRUC IMAGE_DOS_HEADER
        .e_magic      RESW 1   ; Magic number 'MZ'
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
        alignb 4
    ENDSTRUC
    %define SIZEOF_IMAGE_DOS_HEADER     64     

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
        alignb 4
    ENDSTRUC
    %define SIZEOF_IMAGE_OPTIONAL_HEADER32     224

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
        alignb 4
    ENDSTRUC
    %define SIZEOF_IMAGE_FILE_HEADER    20

    STRUC IMAGE_NT_HEADERS32
        .Signature      RESD 1                                  ; NT header 'PE'
        .FileHeader     RESB SIZEOF_IMAGE_FILE_HEADER           ; IMAGE_FILE_HEADER
        .OptionalHeader RESB SIZEOF_IMAGE_OPTIONAL_HEADER32     ; IMAGE_OPTIONAL_HEADER32
        alignb 4
    ENDSTRUC
    %define SIZEOF_IMAGE_NT_HEADERS32   248

    ;
    ; Section headers of e.g. .text, .data, .rdata, etc
    ;
    STRUC IMAGE_SECTION_HEADER
        .Name                   RESB 8  ; An 8-byte, UTF-8 string. There is no terminating null character if the string is eight characters long
        .VirtualSize            RESD 1  ; Total size of the section when loaded into memory, in bytes
        .VirtualAddress         RESD 1  ; Address of the first byte of the section when loaded into memory, relative to the image base.
        .SizeOfRawData          RESD 1  ; Size of the initialized data on disk, in bytes. 
        .PointerToRawData       RESD 1  ; File pointer to the first page within the COFF file.
        .PointerToRelocations   RESD 1  ; File pointer to the beginning of the relocation entries for the section. 
        .PointerToLinenumbers   RESD 1  ; File pointer to the beginning of the line-number entries for the section
        .NumberOfRelocations    RESW 1  ; Number of relocation entries for the section
        .NumberOfLinenumbers    RESW 1  ; Number of line-number entries for the section.
        .Characteristics        RESD 1  ; Characteristics of the image (execute, r/w, initalized data, uninit data, etc)
        alignb 4
    ENDSTRUC
    %define SIZEOF_IMAGE_SECTION_HEADER 40

SECTION .data  
    xyText:     dd  (0xB * 80 * 2)  ; Used in Print32 VGA print, the initial X/Y offset 0xB for text in protected mode


SECTION .text



;
; Map the kernel file into virtual memory by parsing the PE format and mapping the Sections into there designated
; virtual addresses
;
; Returns:
;   Virtual address of kernel entry point
;
MapKernelImage:
    push    ebp                     ; Create stack frame
    mov     ebp, esp            
    sub     esp, 0x1C               ; Local stack variables
                                    ; [00 - 08]: [ebp-04h]: CHAR   hexString[9]     // 8 bytes used for number, 1 for null
                                    ; [09 - 0B]:            UINT8  padding[3]
                                    ; [0C - 0F]: [ebp-10h]: UINT32 idxSection       // current index of section headers parsed
                                    ; [10 - 13]: [ebp-14h]: UINT32 cTotalSections   // total sections
                                    ; [14 - 17]: [ebp-18h]: UINT32 ImageBase        // kernel base address
                                    ; [18 - 1B]: [ebp-1Ch]: UINT32 AddrOfEntryPoint // RVA offset to entry point

    ;
    ; Parse the DOS header for the offset to the NT header
    ;
    mov     eax, [KERNEL_ADDR_32 + IMAGE_DOS_HEADER.e_magic]
    cmp     ax, 0x5a4d              ; 'MZ'
    jnz     .end  
    lea     esi, szVerifiedKernelDos
    call    PrintStrVgaTextMem

    ;
    ; Parse the NT header
    ;
    lea     eax, dword [KERNEL_ADDR_32]
    add     eax, dword [KERNEL_ADDR_32 + IMAGE_DOS_HEADER.e_lfanew]
    mov     ebx, dword [eax + IMAGE_NT_HEADERS32.Signature]
    cmp     bx, 0x4550              ; 'PE'
    jnz     .end  
    lea     esi, szVerifiedKernelNt
    call    PrintStrVgaTextMem

    ;
    ; Parse the file header
    ;
    lea     edx, dword [eax + IMAGE_NT_HEADERS32.FileHeader]
    movzx   ebx, word [edx + IMAGE_FILE_HEADER.NumberOfSections]    ; Mov the 16 bit val and zero extend tops bits
    mov     dword [ebp-0x14], ebx                                   ; Move NumberOfSections into ebp-0x14

    ;
    ; Parse the Optional header
    ;
    lea     edx, dword [eax + IMAGE_NT_HEADERS32.OptionalHeader]
    mov     ebx, dword [edx + IMAGE_OPTIONAL_HEADER32.Magic]
    cmp     bx, 0x010B                                              ; IMAGE_NT_OPTIONAL_HDR32_MAGIC 0x010B
    jnz     .end
    mov     ebx, dword [edx + IMAGE_OPTIONAL_HEADER32.ImageBase]
    mov     dword [ebp-0x18], ebx                                   ; Copy preferred ImageBase (e.g. 0x10000) into ebp-0x18    
    mov     ebx, dword [edx + IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint]
    mov     dword [ebp-0x1C], ebx                                   ; Copy RVA offset of code entry point into ebp-0x1C
    lea     esi, szVerifiedKernel32bImage
    call    PrintStrVgaTextMem

    ;
    ; Parse the Sections header
    ;
    lea     eax, [KERNEL_ADDR_32]
    add     eax, [KERNEL_ADDR_32 + IMAGE_DOS_HEADER.e_lfanew]       ; Go to offset to NT header
    add     eax, SIZEOF_IMAGE_NT_HEADERS32                          ; Add NT header size
    mov     dword [ebp-0x10], 0                                     ; Set idxSection to 0
    
    ;
    ; Copy raw sections from file pointer into calculated virtual addresses
    ;
    .sectionLoop:
    mov     esi, KERNEL_ADDR_32                                     ; Move file pointer of kernel to source
    add     esi, dword [eax + IMAGE_SECTION_HEADER.PointerToRawData]; Get Section Header point to raw data
    mov     edi, [ebp-0x18]                                         ; Move ImageBase (e.g. 0x10000) into dest
    add     edi, dword [eax + IMAGE_SECTION_HEADER.VirtualAddress]  ; Add Section's VirtualAddress offset to the preferred ImageBase
    mov     ecx, dword [eax + IMAGE_SECTION_HEADER.SizeOfRawData]   ; Move Section size in bytes into ecx
    shr     ecx, 2                                                  ; Divide by 4
    rep     movsd                                                   ; High perf copy of ecx*dwords from edi into esi

    lea     esi, szCopyingSection                                   ; Verbose print of section name e.g. ".text"
    call    PrintStrVgaTextMem
    lea     esi, dword [eax + IMAGE_SECTION_HEADER.Name]
    call    PrintStrVgaTextMem
    lea     esi, szNewLine
    call    PrintStrVgaTextMem

    add     eax, SIZEOF_IMAGE_SECTION_HEADER                        ; Move eax originally pointer to SectionHeader[0] to next
    inc     dword [ebp-0x10]                                        ; idxSection++
    mov     ecx, dword [ebp-0x10]
    cmp     ecx, dword [ebp-0x14]                                   ; if idxSection < cTotalSections
    jb      .sectionLoop                                            ; jmp if below
        
    lea     esi, szKernelBaseVa                                     ; Print kernel base VA
    call    PrintStrVgaTextMem
    mov     eax, dword [ebp-0x18]                                   ; ImageBase VA 
    lea     ecx, [ebp - 8]                                          ; &hexString
    mov     edx, eax
    call    DwordToHexstring    
    lea     esi, [ebp - 8]
    call    PrintStrVgaTextMem

    lea     esi, szKernelEpVa                                       ; Print kernel entry point VA
    call    PrintStrVgaTextMem
    mov     eax, dword [ebp-0x18]                                   ; ImageBase VA 
    add     eax, dword [ebp-0x1C]                                   ; RVA of entry point    
    lea     ecx, [ebp - 8]                                          ; &hexString
    mov     edx, eax
    call    DwordToHexstring    
    lea     esi, [ebp - 8]
    call    PrintStrVgaTextMem
    lea     esi, szNewLine
    call    PrintStrVgaTextMem

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
    sub     esp, 0x4    ; Local stack varaibles
                        ; [00 - 03]: [ebp-04h]: PVOID   pKernelEp       // Entry point of kernel code

    mov ax, DATA_SEG    ; Set all segments to point to data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov     esi, szHelloFrom32b
    call    PrintStrVgaTextMem

    ; load kernel, if some code runs, change vid mode to vga and do gfx work from C
    call    MapKernelImage
    mov     dword [ebp-0x04], eax

;mov edi,0x0A0000
;mov al,0x02      ; the color of the pixel
;mov [edi],al
    ; print loading circle, then transition to another gfx mode, and show same loading circle

DEBUGBREAK
    mov     eax, dword [ebp-0x04]
    call    eax


    cli
    hlt

    mov     esp, ebp    ; Unwind stack frame
    pop     ebp
    ret

;
; Consts used in protected mode.
; New lines only supported at end of string, identified by 0xA.
;
szHelloFrom32b                          db "Transitioned to Protected Mode", 0xA, 0
szVerifiedKernelDos                     db "Verified kernel DOS header 'MZ' 0x5A4D", 0xA, 0
szVerifiedKernelNt                      db "Verified kernel NT header  'PE' 0x4550", 0xA, 0
szVerifiedKernel32bImage                db "Verified kernel 32b image       0x010B", 0xA, 0
szCopyingSection                        db "Copying section: ", 0
szKernelBaseVa                          db "Kernel has been loaded at: ", 0
szKernelEpVa                            db ". Entry point: ", 0
szNewLine                               db 0xA, 0

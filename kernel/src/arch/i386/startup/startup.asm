; This file contains the code that is going to be linked at the beginning of
; the kernel binary.
; It should contain core CPU initialisation routines such as entering
; long mode.

global _start
global cmdline

extern textmodeprint
extern clearscreen
extern check_cpuid
extern paging_init
extern gdt_ptr
extern gdt_ptr_lowerhalf
extern kmain
extern sections_bss
extern sections_bss_end

%define kernel_phys_offset 0xc0000000

section .bss

cmdline resb 2048

section .data

calls:
    .clearscreen        dd clearscreen - kernel_phys_offset
    .check_cpuid        dd check_cpuid - kernel_phys_offset
    .paging_init        dd paging_init - kernel_phys_offset

section .text
bits 32

_start:
    mov esp, 0xeffff0

    ; mask the PIC right away
    mov al, 0xff
    out 0x21, al
    out 0xa1, al

    ; zero out bss
    mov edi, sections_bss
    mov ecx, sections_bss_end
    sub ecx, sections_bss
    xor eax, eax
    rep stosb

    mov esi, dword [ebx+16]
    mov edi, cmdline - kernel_phys_offset
    mov ecx, 2047
  .cpycmdline:
    lodsb
    test al, al
    jz near .cpycmdline_out
    stosb
    dec ecx
    jnz near .cpycmdline
  .cpycmdline_out:
    xor al, al
    stosb

    call [(calls.clearscreen) - kernel_phys_offset]

    call [(calls.check_cpuid) - kernel_phys_offset]

    call [(calls.paging_init) - kernel_phys_offset]

    lgdt [gdt_ptr_lowerhalf - kernel_phys_offset]

    jmp 0x08:.pmode_init - kernel_phys_offset

.pmode_init:
    mov ax, 0x10
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Jump to the higher half
    mov eax, .higher_half
    jmp eax

  .higher_half:
    mov esp, kernel_phys_offset + 0xeffff0

    lgdt [gdt_ptr - kernel_phys_offset]

    xor eax, eax
    not eax
    push eax
    jmp kmain

.halt:
    cli
    hlt
    jmp .halt

; File Descriptors
STDIN equ 0
STDOUT equ 1
STDERR equ 2

; Op Codes
SYS_READ equ 0
SYS_WRITE equ 1
SYS_EXIT equ 60

; Datatype Sizes
BYTES_CHAR equ 1
BYTES_INT equ 4

; ASCII Codes
ASCII_NULL equ 0
ASCII_NEWLINE equ 0xA
ASCII_ZERO equ 0x30
ASCII_NINE equ 0x39

BUFFER_SIZE equ 16

section .data
  STR_PROMPT db "Enter a binary number to convert:", ASCII_NEWLINE, ASCII_NULL

section .bss
  ; =====
  num resb BYTES_INT
  binNum resb BYTES_INT
  decNum resb BYTES_INT
  base resb BYTES_INT
  rem resb BYTES_INT
  ; =====
  input resb BUFFER_SIZE

global _start

%macro exit 0
  xor rbx, rbx
  mov rax, SYS_EXIT
  syscall
%endmacro

section .text
  power:                    ; power(int rax [base], int rbx [exponent])
    push rbx                ; Store the exponent in stack
    dec rbx                 ; Decrement the exponent by 1 (example 2^5)
    push rcx
    mov rcx, rax            ; Store the original base in RCX
  powerLoop:
    mul rcx                 ; Multiply RAX by RCX
    dec rbx                 ; Decrement the exponent by 1
    cmp rbx, 0              ; Is the exponent equal to 0?
    jne powerLoop           ; If not, loop again
    pop rcx
    pop rbx                 ; Restore the original exponent
    ret                     ; Returns the power in RAX

  strlen:                   ; strlen(char* rax [msg])
    mov rbx, rax            ; Store the value of RAX in RBX

  strlenLoop:
    inc rax                 ; Increment the address stored in RAX by 1 byte
    mov cl, [rax]           ; Dereference the address in RAX and store the value in cl (bits 0-7 in register CX/ECX/RCX)
    cmp cl, ASCII_NULL      ; Check if the current character is a NULL bit
    jne strlenLoop          ; If the current character is NOT a null bit, loop back to the top
    sub rax, rbx            ; If the current character IS a null bit, calculate the difference of RAX (one edge of string) and RBX (other edge of string) to find the length
    sub rax, 1              ; Do not count the newline byte
    ret                     ; Returns the string length in RAX

  read:                     ; read()
    mov rdx, BUFFER_SIZE
    mov rsi, input
    mov rdi, STDIN
    mov rax, SYS_READ
    syscall
    ret

  printString:              ; printString(char* rax [msg])
    push rcx                ; SYSCALL or SYS_WRITE will destroy the value stored in rcx. It should be stored safely in stack
    push rax                ; strlen will modify RAX. Store RAX safely in stack
    call strlen             ; Determine the length of the string in RAX

    mov rdx, rax            ; Pass the length to arg2 of SYS_WRITE
    pop rsi                 ; Set the string to write to STDOUT
    mov rdi, STDOUT         ; Set stream to write to STDOUT
    mov rax, SYS_WRITE      ; Set the OPCODE to 'write'
    syscall                 ; Send the system interrupt

    pop rcx                 ; Restore the saved RCX value
    ret                     ; End the function

  _start:
    exit
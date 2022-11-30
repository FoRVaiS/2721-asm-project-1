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
  STRING_BUF resb BUFFER_SIZE

global _start

%macro exit 0
  xor rbx, rbx
  mov rax, SYS_EXIT
  syscall
%endmacro

section .text
  power:                    ; power(int rax [base], int rbx [exponent])
    cmp rax, 0              ; Check if the base is equal to 0
    je baseEqu0             ; Return 0 (rax)

    cmp rbx, 1              ; Check if the exponent is lower than 1
    jl expBelow1            ; Return 1

    push rbx                ; Store the exponent in stack
    dec rbx
    push rcx
    mov rcx, rax            ; Store the original base in RCX
  powerLoop:
    mul rcx                 ; Multiply RAX by RCX
    dec rbx                 ; Decrement the exponent by 1
    cmp rbx, 0              ; Is the exponent equal to 0?
    jg powerLoop            ; If not, loop again
    pop rcx
    pop rbx                 ; Restore the original exponent
  baseEqu0:
    ret                     ; Returns the power in RAX
  expBelow1:
    mov rax, 1
    ret

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
    mov rsi, STRING_BUF
    mov rdi, STDIN
    mov rax, SYS_READ
    syscall
    ret

  printString:              ; printString(char* rbx [msg])
    mov rax, rbx            ; Pass the msg to Arg0
    call strlen             ; Determine the length of the string in RAX

    mov rdx, rax            ; Pass the length to arg2 of SYS_WRITE
    mov rsi, rbx            ; Set the string to write to STDOUT
    mov rdi, STDOUT         ; Set stream to write to STDOUT
    mov rax, SYS_WRITE      ; Set the OPCODE to 'write'
    syscall                 ; Send the system interrupt

    ret                     ; End the function

  printChar:                ; printChar(char rbx [character])
    push rbx

    mov rdx, 1              ; Pass the length to arg2 of SYS_WRITE
    mov rsi, rsp            ; Set the string to write to STDOUT
    mov rdi, STDOUT         ; Set stream to write to STDOUT
    mov rax, SYS_WRITE      ; Set the OPCODE to 'write'
    syscall                 ; Send the system interrupt

    pop rbx
    ret

  printInteger:             ; printInteger(int rbx [num], int rsi [size])
    mov rax, rbx
    mov rsi, 0
    
  printIntegerLoop:
    xor rdx, rdx
    mov rcx, 10
    div rcx

    mov rbx, rdx
    add rbx, ASCII_ZERO
    push rbx
    inc rsi

    cmp rax, 0
    jne printIntegerLoop

  printIntegerReverse:
    pop rbx
    push rsi
    call printChar
    pop rsi

    dec rsi
    cmp rsi, 0
    jne printIntegerReverse
    ret

  calculate:                ; calculate(char* rdi [input], int rsi [size] )
    mov rcx, 0              ; Loop counter register
    mov rbx, 0              ; The register holding the acc value
  
  calculateLoop:
    ; Calculate the exponent for the bit position
    mov rdx, rsi
    sub rdx, 1
    sub rdx, rcx

    ; Calculate the decimal value
    push rbx
    mov rax, 2
    mov rbx, rdx
    call power

    ; Grab the bit starting from position at RCX
    ; rdx will hold the bit
    mov dl, [rdi]
    inc rdi
    sub dl, ASCII_ZERO

    ; Multiply the decimal value by whether or not the bit is enabled
    mul dl

    ; Add result to the acc register
    pop rbx
    add rbx, rax

    inc rcx
    cmp rcx, rsi
    jl calculateLoop
    ret

  _start:
    call read

    mov rax, STRING_BUF
    call strlen 

    mov rdi, STRING_BUF
    mov rsi, rax
    call calculate

    call printInteger
    exit
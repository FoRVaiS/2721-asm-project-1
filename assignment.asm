; File Descriptors
STDIN equ 0
STDOUT equ 1
STDERR equ 2

; Op Codes
SYS_READ equ 0
SYS_WRITE equ 1
SYS_EXIT equ 60

; Datatype Sizes
BYTES_CHAR equ 4
BYTES_INT equ 4

; ASCII Codes
ASCII_NULL equ 0
ASCII_NEWLINE equ 0xA
ASCII_ZERO equ 0x30

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
  nextChar resb BYTES_CHAR

global _start

%macro exit 0
  mov rbx, 0
  mov rax, SYS_EXIT
  syscall
%endmacro

section .text
  strlen:
    mov rbx, rax            ; Store the value of RAX in RBX

  strlenLoop:
    inc rax                 ; Increment the address stored in RAX by 1 byte
    mov cl, [rax]           ; Dereference the address in RAX and store the value in cl (bits 0-7 in register CX/ECX/RCX)
    cmp cl, ASCII_NULL      ; Check if the current character is a NULL bit
    jne strlenLoop          ; If the current character is NOT a null bit, loop back to the top
    sub rax, rbx            ; If the current character IS a null bit, calculate the difference of RAX (one edge of string) and RBX (other edge of string) to find the length
    ret                     ; End the function

  read:
    mov RCX, 0

  readLoop:
    mov RDX, BYTES_CHAR
    mov RSI, nextChar
    mov RDI, STDIN
    mov RAX, SYS_READ
    syscall

    push nextChar
    inc cl
    cmp RSP, ASCII_NEWLINE
    jne readLoop
    ret

  ; printString(char* rax)
  printString:
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

  ; printInt(int* rax)
  printInt:
    mov rbx, 10             ; Set the divisor to 10
    mov rcx, 0              ; Set the bit/number position to 0

  printIntPushLoop:
    mov rdx, 0              ; By default, `div` will return join RDX:RAX. Set RDX to 0 to prevent arithmatic errors
    div rbx                 ; Divide RAX by RBX

    add rdx, ASCII_ZERO     ; Convert single-digit integer to ASCII by offseting by 48
    push rdx                ; Push the ascii-digit to the stack
    inc rcx                 ; Increment to next bit/number position

    cmp rax, 0              ; Check if the dividend is 0
    jne printIntPushLoop    ; If the dividend IS NOT 0, start the process again

  printStringPopLoop:
    mov rax, rsp            ; Store the address of the top item in the stack in RAX
    call printString        ; Print the value stored in RAX
    pop rax                 ; Remove the item from the stack
    dec rcx                 ; Decrement the bit/number position
    cmp rcx, 0              ; Check if we have reached the last digit
    jne printStringPopLoop  ; If more numbers remain, print and remove the next digit
    ret                     ; End the function

  _start:
    mov rax, STR_PROMPT
    call printString

    mov rax, num
    call read

    mov rax, num
    call printString
    exit

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
  xor     rbx, rbx
  mov     rax, SYS_EXIT
  syscall
%endmacro

section .text
  power:                      ; power(int rax [base], int rbx [exponent])
    cmp   rax, 0              ; Check if the base is equal to 0
    je    baseEqu0            ; Return 0 (rax)

    cmp   rbx, 1              ; Check if the exponent is lower than 1
    jl    expBelow1           ; Return 1

    cmp   rbx, 1
    je    expEqu1

    push  rbx                 ; Store the exponent in stack
    dec   rbx                 ; Decrement the exponent
    push  rcx                 ; Store the original state of rcx
    mov   rcx, rax            ; Store the base in rcx
  powerLoop:
    mul   rcx                 ; Multiply power [rax] by the base [rcx]
    dec   rbx                 ; Decrement the exponent by 1
    cmp   rbx, 0              ; Is the exponent equal to 0?
    jg    powerLoop           ; If not, loop again
    pop   rcx                 ; Restore the original state of rcx
    pop   rbx                 ; Restore the original exponent
  expEqu1:
  baseEqu0:
    ret                       ; Returns the power in RAX
  expBelow1:
    mov   rax, 1              ; Set the power to 1
    ret

  ; Returns the number of characters in a string
  strlen:                     ; strlen(char* rax [msg])
    mov   rbx, rax            ; Store the value of RAX in RBX

  strlenLoop:
    inc   rax                 ; Increment the address stored in RAX by 1 byte
    mov   cl, [rax]           ; Dereference the address in RAX and store the value in cl (bits 0-7 in register CX/ECX/RCX)
    cmp   cl, ASCII_NULL      ; Check if the current character is a NULL bit
    jne   strlenLoop          ; If the current character is NOT a null bit, loop back to the top
    sub   rax, rbx            ; If the current character IS a null bit, calculate the difference of RAX (one edge of string) and RBX (other edge of string) to find the length
    sub   rax, 1              ; Do not count the newline byte
    ret                       ; Returns the string length in RAX

  ; Reads input from user
  read:                       ; read()
    mov   rdx, BUFFER_SIZE    ; Read characters from the STDIN of size BUFFER_SIZE
    mov   rsi, STRING_BUF     ; Store string into a string buffer
    mov   rdi, STDIN          ; Read from STDIN
    mov   rax, SYS_READ       ; Set the instruction code to READ
    syscall
    ret

  ; Prints a string given a char pointer
  printString:                ; printString(char* rbx [msg])
    mov   rax, rbx            ; Pass the msg to Arg0
    call  strlen              ; Determine the length of the string in RAX
    add   rax, 1              ; Add one more byte to include the last character in string

    mov   rdx, rax            ; Pass the length to arg2 of SYS_WRITE
    mov   rsi, rbx            ; Set the string to write to STDOUT
    mov   rdi, STDOUT         ; Set stream to write to STDOUT
    mov   rax, SYS_WRITE      ; Set the OPCODE to 'write'
    syscall                   ; Send the system interrupt

    ret                       ; End the function

  ; Prints a character given an ascii key code
  printChar:                  ; printChar(char rbx [character])
    push  rbx

    mov   rdx, 1              ; Pass the length to arg2 of SYS_WRITE
    mov   rsi, rsp            ; Set the string to write to STDOUT
    mov   rdi, STDOUT         ; Set stream to write to STDOUT
    mov   rax, SYS_WRITE      ; Set the OPCODE to 'write'
    syscall                   ; Send the system interrupt

    pop   rbx
    ret

  ; Prints each digit as a char
  printInteger:               ; printInteger(int rbx [num], int rsi [size])
    mov   rax, rbx            ; Stores the original num into rax
    mov   rsi, 0              ; The number of digits

  printIntegerLoop:
    ; Divide the num by 10 to get the last digit
    xor   rdx, rdx            ; Reset rdx
    mov   rcx, 10             ; Set rcx as base 10
    div   rcx                 ; Divide rax [num] by 10

    ; Store the digit as an ascii character in stack
    mov   rbx, rdx            ; Move the value from rdx [remainder] to rbx
    add   rbx, ASCII_ZERO     ; Convert to the digit to it's ascii representation
    push  rbx                 ; Push the char to stack
    inc   rsi                 ; Increment the digit counter

    ; Ensure the entire num has been converted
    cmp   rax, 0              ; Is the quotient equal to 0?
    jne   printIntegerLoop    ; If not, keep dividing

  printIntegerReverse:
    ; Print the digit char
    pop   rbx                 ; Pop the last value from stack into rbx
    push  rsi                 ; Rsi will be modified after calling printChar, store the value in stack
    call  printChar           ; Print the digit char
    pop   rsi                 ; Load the original rsi value

    ; Check that the entire num has been printed
    dec   rsi                 ; Decrement the digit counter
    cmp   rsi, 0              ; Is the digit counter equal to 0?
    jne   printIntegerReverse ; If not, keep printing
    ret

  ; Convert a binary string to into an integer
  calculate:                  ; calculate(char* rdi [input], int rsi [size] )
    mov   rcx, 0              ; Loop counter register
    mov   rbx, 0              ; The register holding the acc value

  calculateLoop:
    ; Calculate the exponent for the bit position
    mov   rdx, rsi
    sub   rdx, 1
    sub   rdx, rcx

    ; Calculate the decimal value
    push  rbx
    mov   rax, 2
    mov   rbx, rdx
    call  power

    ; Grab the bit starting from position at RCX
    ; rdx will hold the bit
    mov   dl, [rdi]
    inc   rdi
    sub   dl, ASCII_ZERO

    ; Multiply the decimal value by whether or not the bit is enabled
    mul   dl

    ; Add result to the acc register
    pop   rbx
    add   rbx, rax

    inc   rcx
    cmp   rcx, rsi
    jl    calculateLoop
    ret

  _start:
    mov   rbx, STR_PROMPT
    call  printString

    call  read

    mov   rax, STRING_BUF
    call  strlen

    mov   rdi, STRING_BUF
    mov   rsi, rax
    call  calculate

    call  printInteger

    mov   rbx, ASCII_NEWLINE
    call  printChar
    exit
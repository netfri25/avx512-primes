; vim: set ft=fasm:

format ELF64 executable
entry _start

include 'common.asm'

segment readable executable

_start:
    mov dword [primes], 2
    mov dword [primes + 4], 3

    ; cursor to the current prime
    ; each prime is a dword (4 bytes unsigned)
    mov r8, primes + 8

    ; number that is currently being tested
    mov r9d, 5

    .loop:
        ; pointer to the prime to check as divisor.
        ; since 2 is the first prime and we know for sure that the number won't
        ; be divisible by 2, then we skip it
        mov rsi, primes + 4

        .check_divisors:
            ; p: ecx = the current prime divisor
            mov ecx, dword [rsi]

            ; if (n % p == 0) not prime
            mov edx, 0
            mov eax, r9d
            div ecx
            test edx, edx
            jz .not_prime

            ; if (p * p >= n) found prime
            mov eax, ecx
            mul ecx
            cmp eax, r9d
            jae .prime

            ; check the next prime in the primes list
            add rsi, 4
            jmp .check_divisors

        .prime:
        ; push the found prime to the primes list
        mov dword [r8], r9d
        add r8, 4
        cmp r8, primes_end
        jae .exit_loop

        .not_prime:
        ; check the next odd number
        add r9d, 2
        jmp .loop

    .exit_loop:

    ; mov r8, primes
    ; .write_loop:
    ;     xor rax, rax
    ;     mov eax, dword [r8]
    ;     call write_number
    ;     add r8, 4
    ;     cmp r8, primes_end
    ;     jne .write_loop

    jmp exit


segment readable writeable
PRIMES_CAP equ 1000000
primes: rd PRIMES_CAP
primes_end: rb 0

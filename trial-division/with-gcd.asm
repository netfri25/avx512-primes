; vim: set ft=fasm:

format ELF64 executable
entry _start

include '../common.asm'
include 'gcd.asm'

segment readable executable

_start:
    mov dword [primes + 0*4], 2
    mov dword [primes + 1*4], 3
    mov dword [primes + 2*4], 5
    mov dword [primes + 3*4], 7

    ; cursor to the end of primes (where primes are appended)
    ; each prime is a dword (4 bytes unsigned)
    mov r8, primes + 4*4

    ; numbers that are currently being tested
    vmovdqu32 zmm6, [starting_values]

    ; zmm4: 1s
    mov ecx, 1
    vpbroadcastd zmm4, ecx

    .loop:
        vmovdqa32 zmm0, zmm6
        ; pointer to the prime to check as divisor.
        ; since 2 is the first prime and we know for sure that the number won't
        ; be divisible by 2, then we skip it
        mov rsi, primes + 4

        ; initialize all bits of k1 to 1
        ; k1 marks all primes numbers when the check_divisors loop finishes
        vpcmpeqd k1, zmm0, zmm0

        .check_divisors:
            ; p: ecx = the current prime divisor
            mov ecx, dword [rsi]
            vpbroadcastd zmm1, ecx
            vmovdqa32 zmm5, zmm1  ; save the broadcasted prime for later

            ; if (gcd(n, p) != 1) not prime
            vmovdqa32 zmm2, zmm0            ; copy to prevent destruction
            GCD_ODDS zmm1, zmm2, zmm3, k0   ; evaluate the gcd, stored in zmm1. trashes zmm3 and k2
            vpcmpeqd k0, zmm1, zmm4         ; get a mask of all gcd results that are equal to 1
            kandd k1, k1, k0                ; is_prime = is_prime & is_gcd_one
            vmovdqa32 zmm0{k1}{z}, zmm0     ; keep only possible candidates

            ; TODO: do I want to check if is_gcd_one resulted in all ones? this can help short circuiting

            ; if (p * p >= n) break
            ; if (!(n > p * p)) break
            vpmulld zmm5, zmm5, zmm5
            vpcmpgtd k0, zmm0, zmm5
            kortestd k0, k0
            jz .break

            ; check the next prime in the primes list
            add rsi, 4
            jmp .check_divisors

        .break:

        ; append the found primes to the primes list
        vpcompressd [r8]{k1}, zmm0
        xor rcx, rcx
        kmovd ecx, k1
        popcnt ecx, ecx
        lea r8, [r8 + rcx*4]

        cmp r8, primes_end
        jae .exit_loop

        ; check the next odd numbers
        vpaddd zmm6, zmm6, [increments]
        jmp .loop

    .exit_loop:

    mov r8, primes
    .write_loop:
        xor rax, rax
        mov eax, dword [r8]
        call write_number
        add r8, 4
        cmp r8, primes_end
        jne .write_loop

    jmp exit


segment readable
starting_values: dd  9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39
increments:      dd 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32

segment readable writeable
PRIMES_CAP equ 1000000
primes: rd PRIMES_CAP
primes_end: rb 16*4 ; 16*4 is a padding of 16 values

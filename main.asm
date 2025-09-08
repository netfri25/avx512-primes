; vim: set ft=fasm:

format ELF64 executable
entry _start

include 'common.asm'

segment readable executable

_start:
    mov dword [primes + 0*4], 2
    mov dword [primes + 1*4], 3
    mov dword [primes + 2*4], 5
    mov dword [primes + 3*4], 7

    ; index 0 should never be read, and is left undefined
    ; mov dword [divisors + 0*4], ...
    mov dword [divisors + 1*4], 9
    mov dword [divisors + 2*4], 15
    mov dword [divisors + 3*4], 21

    ; index to the end of primes (where primes are appended)
    mov r8, 4

    ; numbers that are currently being tested
    vmovdqu32 zmm6, [starting_values]

    ; zmm4: 1s
    mov ecx, 1
    vpbroadcastd zmm4, ecx

    .loop:
        vmovdqa32 zmm0, zmm6
        ; index to the prime to check as divisor.
        ; since 2 is the first prime and we know for sure that the number won't
        ; be divisible by 2, then we skip it
        mov rsi, 1

        ; initialize all bits of k1 to 1
        ; k1 marks all primes numbers when the check_divisors loop finishes
        vpcmpeqd k1, zmm0, zmm0

        .check_prime_divisors:
            ; p: ecx = the current prime divisor
            mov ecx, dword [primes + rsi*4]
            vpbroadcastd zmm1, ecx

            ; highest divisor yet of the current prime divisor
            mov ecx, dword [divisors + rsi*4]
            vpbroadcastd zmm2, ecx

            ; ==  3 -> max 11 iterations
            ; ==  5 -> max  7 iterations
            ; ==  7 -> max  5 iterations
            ; == 11 -> max  3 iterations
            ; == 13 -> max  3 iterations
            ; == 17 -> max  2 iterations
            ; == 19 -> max  2 iterations
            ; == 23 -> max  2 iterations
            ; == 29 -> max  2 iterations
            ; == 31 -> max  2 iterations
            ; >= 37 -> max  1 iteration
            .divisor_loop:
                ; keep values that are not equal to that divisor
                vpcmpeqd k0, zmm0, zmm2
                kandnd k1, k0, k1

                ; if divisor is bigger than all values, go to next prime divisor
                ; if (!(divisior < n)) break
                vpcmpgtd k0, zmm0, zmm2
                kortestd k0, k0
                jz .next_divisor

                ; increment the divisor by 2*prime
                ; TODO: can this be optimized?
                vpaddd zmm2, zmm2, zmm1
                vpaddd zmm2, zmm2, zmm1

                ; save the updated divisor
                ; TODO: should this be out of the loop?
                ;       for most primes it will run either once or not at all
                vmovd dword [divisors + rsi*4], xmm2

                jmp .divisor_loop

            .next_divisor:

            ; filter non primes
            vmovdqa32 zmm0{k1}, zmm0

            ; if (p * p >= n) break
            ; if (!(n > p * p)) break
            vpmulld zmm1, zmm1, zmm1
            vpcmpgtd k0, zmm0, zmm1
            kortestd k0, k0
            jz .break

            ; check the next prime in the primes list
            inc rsi
            jmp .check_prime_divisors

        .break:

        ; append the found primes to the primes list and divisors list
        vpcompressd [primes   + r8*4]{k1}, zmm0
        vpcompressd [divisors + r8*4]{k1}, zmm0
        xor rcx, rcx
        kmovd ecx, k1
        popcnt ecx, ecx
        add r8, rcx

        cmp r8, (primes_end - primes) / 4
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
; TODO: can be optimized by starting only with primes
starting_values: dd  9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39
increments:      dd 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32

segment readable writeable
PRIMES_CAP equ 1000000
primes: rd PRIMES_CAP
primes_end: rb 16*4 ; 16*4 is a padding of 16 values
divisors: rd PRIMES_CAP

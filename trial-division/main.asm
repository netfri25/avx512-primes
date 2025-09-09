; vim: set ft=fasm:

format ELF64 executable
entry _start

include '../common.asm'

segment readable executable

_start:
    ; initialize primes up until 11, since it needs the smallest prime number such that:
    ; p + 2*WHEEL < p^2
    mov dword [primes + 0*4], 2
    mov dword [primes + 1*4], 3
    mov dword [primes + 2*4], 5
    mov dword [primes + 3*4], 7
    mov dword [primes + 4*4], 11

    ; commented movs should never be read anyways, and are left undefined
    ; mov dword [divisors + 0*4], ...
    ; mov dword [divisors + 1*4], ...
    ; mov dword [divisors + 2*4], ...
    mov dword [divisors + 3*4], 21
    mov dword [divisors + 4*4], 33

    ; index to the end of primes (where primes are appended)
    mov r8, 5

    ; numbers that are currently being tested
    vmovdqu32 zmm6, [starting_values]

    ; zmm4: 1s
    mov ecx, 1
    vpbroadcastd zmm4, ecx

    .loop:
        vmovdqa32 zmm0, zmm6
        ; index to the prime to check as divisor.
        ; since a 30 wheel is being used (2*3*5), then we can skip checking for
        ; divisibility by either 2, 3, or 5.
        mov rsi, 3

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

            ; WHEEL = 2 * 3 * 5
            ; STEP = 2 * WHEEL
            ; for p in primes[3:]:
            ;   max iterations = ceil(STEP / prime)
            ; primes         = [ 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, ...      ]
            ; max iterations = [ 9,  6,  5,  4,  4,  3,  3,  2,  2,  2,  2,  2,  2,  2,  1, repeat 1 ]
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
; optimize using a 30-wheel: https://en.wikipedia.org/wiki/Wheel_factorization
starting_values: dd 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 49, 53, 59, 61, 67, 71
increments:      dd 16 dup 60

segment readable writeable
PRIMES_CAP equ 1000000
primes: rd PRIMES_CAP
primes_end: rb 16*4 ; 16*4 is a padding of 16 values
divisors: rd PRIMES_CAP

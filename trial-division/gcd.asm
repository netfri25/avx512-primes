; vim: set ft=fasm:

; only `dest` gets modified
macro VPTZCNTD dest, src {
    ; temp = b - 1
    vpternlogd dest, dest, dest, 0xFF ; assign all dwords to -1
    vpaddd dest, src, dest ; b + (-1)

    ; (b - 1) & ~b
    vpandnd dest, src, dest

    ; popcnt((b - 1) & ~b)
    vpopcntd dest, dest
    ; dest now contains tzcnt(src)
}

; evaluates the gcd of a and b where both are known to be odd
; returns the value in a
macro GCD_ODDS a, b, temp, mask {
    local .return
    local .again
.again:
    ; a' = min(a, b)
    ; b' = max(a, b)
    vpmaxud temp, a, b
    vpminud a, a, b
    vmovdqa32 b, temp

    ; exit if a is all zeros
    vptestmd mask, a, a
    kortestd mask, mask
    je .return

    ; apply one step: b = b - a
    vpsubd b, b, a

    ; since `odd - odd == even`, remove trailing zeros
    ; temp = tzcnt(b)
    VPTZCNTD temp, b

    ; b = b >> tzcnt(b)
    vpsrlvd b, b, temp
    jmp .again
.return:
    ; result in a
    ; can be optimized if the max and min are swapped
    vmovdqa32 a, b
}

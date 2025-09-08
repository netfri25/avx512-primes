; vim: set ft=fasm:
SYS_write equ 1
SYS_exit equ 60
STDOUT_FD equ 1

segment readable writeable

BUFFER_CAP equ 1024
write_buffer: rb BUFFER_CAP
write_buffer_end: rb 0

segment readable executable

; rax: u64
; ? rsi, rdi, rdx, rcx, r11
; -> rax: number of bytes written
write_number:
    mov byte [write_buffer_end - 1], 10 ; newline
    mov rsi, write_buffer_end - 1

    ; divisor
    mov rcx, 10
    .digit:
        mov rdx, 0
        div rcx

        ; write remainder
        add dl, '0'
        dec rsi
        mov byte [rsi], dl

        ; continue if not zero
        test rax, rax
        jnz .digit

    ; rsi already contains pointer to the buffer start
    mov rax, SYS_write
    mov rdi, STDOUT_FD

    ; len = end - current (end is non inclusive)
    mov rdx, write_buffer_end
    sub rdx, rsi
    syscall
    jle write_error

    ret


; doesn't return
; jumpable. no need to `call exit`
exit:
    ; exit(error_code)
    mov rax, SYS_exit
    mov rdi, [error_code]
    syscall

; doesn't return
; rsi: error text
; rdx: error len
error:
    mov rax, 1
    mov rdi, 2
    syscall
    mov [error_code], 1
    jmp exit

write_error:
    mov rsi, write_error_msg.text
    mov rdx, write_error_msg.len
    jmp error

segment readable writeable
error_code dq 0

segment readable
write_error_msg:
.text db "can't write file", 10
.len = $ - .text

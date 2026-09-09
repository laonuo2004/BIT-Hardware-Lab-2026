# M6 stage 2: poll UART STATUS bit 0 before every TX write.
# Expected serial output: UART_OK\r\n

    lui  x10, 0x40000

send_u:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_u
    addi x1, x0, 85
    sw   x1, 0(x10)

send_a:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_a
    addi x1, x0, 65
    sw   x1, 0(x10)

send_r:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_r
    addi x1, x0, 82
    sw   x1, 0(x10)

send_t:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_t
    addi x1, x0, 84
    sw   x1, 0(x10)

send_underscore:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_underscore
    addi x1, x0, 95
    sw   x1, 0(x10)

send_o:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_o
    addi x1, x0, 79
    sw   x1, 0(x10)

send_k:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_k
    addi x1, x0, 75
    sw   x1, 0(x10)

send_cr:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_cr
    addi x1, x0, 13
    sw   x1, 0(x10)

send_lf:
    lw   x2, 4(x10)
    andi x2, x2, 1
    bne  x2, x0, send_lf
    addi x1, x0, 10
    sw   x1, 0(x10)

done:
    jal  x0, done

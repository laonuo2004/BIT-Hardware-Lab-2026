.data
list:
    .word 4, 2, 5, 1, 3

.text
main:
    la t2, list
    addi s0, t2, 20
    ori t0, t2, 0
    jal end1
L1:
    addi t1, t2, 16
    jal end2
L2:
    lw a0, 0(t1)
    lw a1, -4(t1)
    bge a0, a1, endif
    sw a1, 0(t1)
    sw a0, -4(t1)
endif:
    addi t1, t1, -4
end2:
    blt t0, t1, L2
    addi t0, t0, 4
end1:
    blt t0, s0, L1

    la t2, list
    li t3, 5
print_loop:
    lw a0, 0(t2)
    li a7, 1
    ecall
    li a0, 32
    li a7, 11
    ecall
    addi t2, t2, 4
    addi t3, t3, -1
    bne t3, zero, print_loop

    li a7, 10
    ecall

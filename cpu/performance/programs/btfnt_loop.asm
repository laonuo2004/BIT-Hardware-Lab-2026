# 256-iteration BTFNT loop; END_PC = 0x10.
addi x1, x0, 0
addi x2, x0, 256
loop:
addi x1, x1, 1
blt  x1, x2, loop
finished:
jal  x0, finished

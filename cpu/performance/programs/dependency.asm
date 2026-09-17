# Twenty ALU instructions with a continuous RAW dependency, then the end marker.
# Expected: x1=20.  END_PC = 0x50.
addi x1, x0, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
finished:
jal x0, finished

# 32-element reverse bubble sort; END_PC = 0x40.
addi x0,x0,0
xor  t2,t2,t2
addi s0,t2,128
ori  t0,t2,0
jal  end1
L1:
addi t1,t2,124
jal  end2
L2:
lw   a0,0(t1)
lw   a1,-4(t1)
bge  a0,a1,endif
sw   a1,0(t1)
sw   a0,-4(t1)
endif:
addi t1,t1,-4
end2:
blt  t0,t1,L2
addi t0,t0,4
end1:
blt  t0,s0,L1
finished:
jal  x0,finished

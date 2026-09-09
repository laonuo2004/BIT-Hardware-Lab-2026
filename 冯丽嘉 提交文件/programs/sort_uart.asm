# ============================================================
# sort_uart.asm — BIT 2026 小学期硬件实训 应用汇编（冯丽嘉）
#
# 功能：初始化数组 4,2,5,1,3 -> 冒泡排序 -> UART 输出
#       "SORT: 1 2 3 4 5\r\n" -> 等待字符 'r' 后重新运行
#
# 硬约束：
#   * 仅使用 16 条 RV32I 指令：
#     add sub xor addi ori lui lw sw beq bne blt bge jal and or andi
#   * 无 ecall / jalr / 移位 / slt
#   * 地址：数据 RAM 0x00000000；UART TX 0x40000000 / STATUS +4 / RX +8
#   * UART STATUS：bit0=忙 bit1=RX有效；写 TX 前须轮询 bit0==0
# ============================================================
    .text
    .globl main

main:
# ---------------- 初始化数组 a[0..4] = 4,2,5,1,3 ----------------
init:
    addi t0, x0, 4
    sw   t0, 0(x0)        # a[0] = 4
    addi t0, x0, 2
    sw   t0, 4(x0)        # a[1] = 2
    addi t0, x0, 5
    sw   t0, 8(x0)        # a[2] = 5
    addi t0, x0, 1
    sw   t0, 12(x0)       # a[3] = 1
    addi t0, x0, 3
    sw   t0, 16(x0)       # a[4] = 3

# ---------------- 冒泡排序：4 轮，每轮 4 次相邻比较 ----------------
    addi s0, x0, 0        # s0 = 外层计数 i = 0
outer_loop:
    addi t1, x0, 0        # t1 = 指针 ptr = 0
    addi s1, x0, 4        # s1 = 内层计数 j = 4
inner_loop:
    lw   t2, 0(t1)        # t2 = a[j]
    lw   t3, 4(t1)        # t3 = a[j+1]
    bge  t3, t2, no_swap  # 若 a[j+1] >= a[j] 则跳过交换
    sw   t3, 0(t1)        # a[j]   = a[j+1]
    sw   t2, 4(t1)        # a[j+1] = a[j]
no_swap:
    addi t1, t1, 4        # ptr += 4
    addi s1, s1, -1       # j--
    bne  s1, x0, inner_loop
    addi s0, s0, 1        # i++
    addi t4, x0, 4
    bne  s0, t4, outer_loop

# ---------------- UART 基址 ----------------
    lui  a0, 0x40000      # a0 = 0x40000000（TX 寄存器）

# ---------------- 输出固定前缀 "SORT: " ----------------
send_S:                    # 'S' = 0x53
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_S
    addi t0, x0, 0x53
    sw   t0, 0(a0)
send_O:                    # 'O' = 0x4F
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_O
    addi t0, x0, 0x4F
    sw   t0, 0(a0)
send_R:                    # 'R' = 0x52
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_R
    addi t0, x0, 0x52
    sw   t0, 0(a0)
send_T:                    # 'T' = 0x54
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_T
    addi t0, x0, 0x54
    sw   t0, 0(a0)
send_colon:                # ':' = 0x3A
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_colon
    addi t0, x0, 0x3A
    sw   t0, 0(a0)
send_space0:               # ' ' = 0x20
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_space0
    addi t0, x0, 0x20
    sw   t0, 0(a0)

# ---------------- 输出第一个数 a[0]（无前导空格） ----------------
    lw   t2, 0(x0)        # t2 = a[0]（已排序 = 1）
    addi t2, t2, 0x30     # 转 ASCII '1'
send_num0:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_num0
    sw   t2, 0(a0)

# ---------------- 输出剩余 4 个数，每个前面加空格 ----------------
    addi t1, x0, 4        # ptr = 4（指向 a[1]）
    addi s1, x0, 4        # 计数 = 4
num_loop:
    # 先发空格
send_space1:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_space1
    addi t0, x0, 0x20
    sw   t0, 0(a0)
    # 再发数字
    lw   t2, 0(t1)        # t2 = a[ptr]
    addi t2, t2, 0x30     # 转 ASCII
send_num:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_num
    sw   t2, 0(a0)
    addi t1, t1, 4
    addi s1, s1, -1
    bne  s1, x0, num_loop

# ---------------- 输出 "\r\n"（0x0D 0x0A） ----------------
send_cr:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_cr
    addi t0, x0, 0x0D
    sw   t0, 0(a0)
send_lf:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_lf
    addi t0, x0, 0x0A
    sw   t0, 0(a0)

# ---------------- 等待字符 'r' 后重新运行 ----------------
wait_r:
    lw   t0, 4(a0)        # 读 STATUS
    andi t0, t0, 2        # bit1 = RX 有效
    beq  t0, x0, wait_r   # 无数据则继续等待
    lw   t0, 8(a0)        # 读 RX（并消费该字节）
    addi t3, x0, 0x72     # 'r' = 0x72
    bne  t0, t3, wait_r   # 非 'r'，忽略并继续等待
    jal  x0, init         # 收到 'r'，重新初始化重跑

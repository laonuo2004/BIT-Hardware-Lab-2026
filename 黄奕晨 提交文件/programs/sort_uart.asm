# ============================================================
# sort_uart.asm — UART 交互式多数据集排序
#
# 复位后打印菜单；串口命令选择数组并输出排序前后结果。
#   1 已排序 1 2 3 4 5
#   2 逆序   5 4 3 2 1
#   3 重复   3 1 3 2 1
#   4 乱序   4 2 5 1 3
#   r 重复上一次（上电默认 4）
#   其它字符 UNKNOWN COMMAND；忽略 CR/LF
#
# 仅 16 条 RV32I：add sub xor addi ori lui lw sw beq bne blt bge jal and or andi
# RAM：a[0..4] @ 0x00..0x10，last_case @ 0x14
# UART：TX 0x40000000 / STATUS +4 / RX +8
# 无 jalr：print_str / print_nums 用 s3 续延号返回
# ============================================================
    .text
    .globl main

main:
    lui  a0, 0x40000

# ---------------- 输出字符串写入 RAM（一字一字符，0 结尾） ----------------
# STR_MENU @ 0x40 'BIT CPU + UART DEMO\r\n1 - SORTED\r\n2 - REVERSE\r\n3 - DUPLICATES\r\n4 - RANDOM\r\nr - REPEAT\r\n'
    addi t0, x0, 0x42
    sw   t0, 64(x0)
    addi t0, x0, 0x49
    sw   t0, 68(x0)
    addi t0, x0, 0x54
    sw   t0, 72(x0)
    addi t0, x0, 0x20
    sw   t0, 76(x0)
    addi t0, x0, 0x43
    sw   t0, 80(x0)
    addi t0, x0, 0x50
    sw   t0, 84(x0)
    addi t0, x0, 0x55
    sw   t0, 88(x0)
    addi t0, x0, 0x20
    sw   t0, 92(x0)
    addi t0, x0, 0x2b
    sw   t0, 96(x0)
    addi t0, x0, 0x20
    sw   t0, 100(x0)
    addi t0, x0, 0x55
    sw   t0, 104(x0)
    addi t0, x0, 0x41
    sw   t0, 108(x0)
    addi t0, x0, 0x52
    sw   t0, 112(x0)
    addi t0, x0, 0x54
    sw   t0, 116(x0)
    addi t0, x0, 0x20
    sw   t0, 120(x0)
    addi t0, x0, 0x44
    sw   t0, 124(x0)
    addi t0, x0, 0x45
    sw   t0, 128(x0)
    addi t0, x0, 0x4d
    sw   t0, 132(x0)
    addi t0, x0, 0x4f
    sw   t0, 136(x0)
    addi t0, x0, 0xd
    sw   t0, 140(x0)
    addi t0, x0, 0xa
    sw   t0, 144(x0)
    addi t0, x0, 0x31
    sw   t0, 148(x0)
    addi t0, x0, 0x20
    sw   t0, 152(x0)
    addi t0, x0, 0x2d
    sw   t0, 156(x0)
    addi t0, x0, 0x20
    sw   t0, 160(x0)
    addi t0, x0, 0x53
    sw   t0, 164(x0)
    addi t0, x0, 0x4f
    sw   t0, 168(x0)
    addi t0, x0, 0x52
    sw   t0, 172(x0)
    addi t0, x0, 0x54
    sw   t0, 176(x0)
    addi t0, x0, 0x45
    sw   t0, 180(x0)
    addi t0, x0, 0x44
    sw   t0, 184(x0)
    addi t0, x0, 0xd
    sw   t0, 188(x0)
    addi t0, x0, 0xa
    sw   t0, 192(x0)
    addi t0, x0, 0x32
    sw   t0, 196(x0)
    addi t0, x0, 0x20
    sw   t0, 200(x0)
    addi t0, x0, 0x2d
    sw   t0, 204(x0)
    addi t0, x0, 0x20
    sw   t0, 208(x0)
    addi t0, x0, 0x52
    sw   t0, 212(x0)
    addi t0, x0, 0x45
    sw   t0, 216(x0)
    addi t0, x0, 0x56
    sw   t0, 220(x0)
    addi t0, x0, 0x45
    sw   t0, 224(x0)
    addi t0, x0, 0x52
    sw   t0, 228(x0)
    addi t0, x0, 0x53
    sw   t0, 232(x0)
    addi t0, x0, 0x45
    sw   t0, 236(x0)
    addi t0, x0, 0xd
    sw   t0, 240(x0)
    addi t0, x0, 0xa
    sw   t0, 244(x0)
    addi t0, x0, 0x33
    sw   t0, 248(x0)
    addi t0, x0, 0x20
    sw   t0, 252(x0)
    addi t0, x0, 0x2d
    sw   t0, 256(x0)
    addi t0, x0, 0x20
    sw   t0, 260(x0)
    addi t0, x0, 0x44
    sw   t0, 264(x0)
    addi t0, x0, 0x55
    sw   t0, 268(x0)
    addi t0, x0, 0x50
    sw   t0, 272(x0)
    addi t0, x0, 0x4c
    sw   t0, 276(x0)
    addi t0, x0, 0x49
    sw   t0, 280(x0)
    addi t0, x0, 0x43
    sw   t0, 284(x0)
    addi t0, x0, 0x41
    sw   t0, 288(x0)
    addi t0, x0, 0x54
    sw   t0, 292(x0)
    addi t0, x0, 0x45
    sw   t0, 296(x0)
    addi t0, x0, 0x53
    sw   t0, 300(x0)
    addi t0, x0, 0xd
    sw   t0, 304(x0)
    addi t0, x0, 0xa
    sw   t0, 308(x0)
    addi t0, x0, 0x34
    sw   t0, 312(x0)
    addi t0, x0, 0x20
    sw   t0, 316(x0)
    addi t0, x0, 0x2d
    sw   t0, 320(x0)
    addi t0, x0, 0x20
    sw   t0, 324(x0)
    addi t0, x0, 0x52
    sw   t0, 328(x0)
    addi t0, x0, 0x41
    sw   t0, 332(x0)
    addi t0, x0, 0x4e
    sw   t0, 336(x0)
    addi t0, x0, 0x44
    sw   t0, 340(x0)
    addi t0, x0, 0x4f
    sw   t0, 344(x0)
    addi t0, x0, 0x4d
    sw   t0, 348(x0)
    addi t0, x0, 0xd
    sw   t0, 352(x0)
    addi t0, x0, 0xa
    sw   t0, 356(x0)
    addi t0, x0, 0x72
    sw   t0, 360(x0)
    addi t0, x0, 0x20
    sw   t0, 364(x0)
    addi t0, x0, 0x2d
    sw   t0, 368(x0)
    addi t0, x0, 0x20
    sw   t0, 372(x0)
    addi t0, x0, 0x52
    sw   t0, 376(x0)
    addi t0, x0, 0x45
    sw   t0, 380(x0)
    addi t0, x0, 0x50
    sw   t0, 384(x0)
    addi t0, x0, 0x45
    sw   t0, 388(x0)
    addi t0, x0, 0x41
    sw   t0, 392(x0)
    addi t0, x0, 0x54
    sw   t0, 396(x0)
    addi t0, x0, 0xd
    sw   t0, 400(x0)
    addi t0, x0, 0xa
    sw   t0, 404(x0)
    sw   x0, 408(x0)
# STR_PROMPT @ 0x19c '>'
    addi t0, x0, 0x3e
    sw   t0, 412(x0)
    sw   x0, 416(x0)
# STR_UNK @ 0x1a4 '\r\nUNKNOWN COMMAND\r\n'
    addi t0, x0, 0xd
    sw   t0, 420(x0)
    addi t0, x0, 0xa
    sw   t0, 424(x0)
    addi t0, x0, 0x55
    sw   t0, 428(x0)
    addi t0, x0, 0x4e
    sw   t0, 432(x0)
    addi t0, x0, 0x4b
    sw   t0, 436(x0)
    addi t0, x0, 0x4e
    sw   t0, 440(x0)
    addi t0, x0, 0x4f
    sw   t0, 444(x0)
    addi t0, x0, 0x57
    sw   t0, 448(x0)
    addi t0, x0, 0x4e
    sw   t0, 452(x0)
    addi t0, x0, 0x20
    sw   t0, 456(x0)
    addi t0, x0, 0x43
    sw   t0, 460(x0)
    addi t0, x0, 0x4f
    sw   t0, 464(x0)
    addi t0, x0, 0x4d
    sw   t0, 468(x0)
    addi t0, x0, 0x4d
    sw   t0, 472(x0)
    addi t0, x0, 0x41
    sw   t0, 476(x0)
    addi t0, x0, 0x4e
    sw   t0, 480(x0)
    addi t0, x0, 0x44
    sw   t0, 484(x0)
    addi t0, x0, 0xd
    sw   t0, 488(x0)
    addi t0, x0, 0xa
    sw   t0, 492(x0)
    sw   x0, 496(x0)
# STR_CASE @ 0x1f4 '\r\nCASE '
    addi t0, x0, 0xd
    sw   t0, 500(x0)
    addi t0, x0, 0xa
    sw   t0, 504(x0)
    addi t0, x0, 0x43
    sw   t0, 508(x0)
    addi t0, x0, 0x41
    sw   t0, 512(x0)
    addi t0, x0, 0x53
    sw   t0, 516(x0)
    addi t0, x0, 0x45
    sw   t0, 520(x0)
    addi t0, x0, 0x20
    sw   t0, 524(x0)
    sw   x0, 528(x0)
# STR_COLON @ 0x214 ': '
    addi t0, x0, 0x3a
    sw   t0, 532(x0)
    addi t0, x0, 0x20
    sw   t0, 536(x0)
    sw   x0, 540(x0)
# STR_IN @ 0x220 'IN : '
    addi t0, x0, 0x49
    sw   t0, 544(x0)
    addi t0, x0, 0x4e
    sw   t0, 548(x0)
    addi t0, x0, 0x20
    sw   t0, 552(x0)
    addi t0, x0, 0x3a
    sw   t0, 556(x0)
    addi t0, x0, 0x20
    sw   t0, 560(x0)
    sw   x0, 564(x0)
# STR_OUT @ 0x238 'OUT: '
    addi t0, x0, 0x4f
    sw   t0, 568(x0)
    addi t0, x0, 0x55
    sw   t0, 572(x0)
    addi t0, x0, 0x54
    sw   t0, 576(x0)
    addi t0, x0, 0x3a
    sw   t0, 580(x0)
    addi t0, x0, 0x20
    sw   t0, 584(x0)
    sw   x0, 588(x0)
# STR_PASS @ 0x250 'PASS\r\n'
    addi t0, x0, 0x50
    sw   t0, 592(x0)
    addi t0, x0, 0x41
    sw   t0, 596(x0)
    addi t0, x0, 0x53
    sw   t0, 600(x0)
    addi t0, x0, 0x53
    sw   t0, 604(x0)
    addi t0, x0, 0xd
    sw   t0, 608(x0)
    addi t0, x0, 0xa
    sw   t0, 612(x0)
    sw   x0, 616(x0)
# STR_FAIL @ 0x26c 'FAIL\r\n'
    addi t0, x0, 0x46
    sw   t0, 620(x0)
    addi t0, x0, 0x41
    sw   t0, 624(x0)
    addi t0, x0, 0x49
    sw   t0, 628(x0)
    addi t0, x0, 0x4c
    sw   t0, 632(x0)
    addi t0, x0, 0xd
    sw   t0, 636(x0)
    addi t0, x0, 0xa
    sw   t0, 640(x0)
    sw   x0, 644(x0)
# STR_N1 @ 0x288 'SORTED\r\n'
    addi t0, x0, 0x53
    sw   t0, 648(x0)
    addi t0, x0, 0x4f
    sw   t0, 652(x0)
    addi t0, x0, 0x52
    sw   t0, 656(x0)
    addi t0, x0, 0x54
    sw   t0, 660(x0)
    addi t0, x0, 0x45
    sw   t0, 664(x0)
    addi t0, x0, 0x44
    sw   t0, 668(x0)
    addi t0, x0, 0xd
    sw   t0, 672(x0)
    addi t0, x0, 0xa
    sw   t0, 676(x0)
    sw   x0, 680(x0)
# STR_N2 @ 0x2ac 'REVERSE\r\n'
    addi t0, x0, 0x52
    sw   t0, 684(x0)
    addi t0, x0, 0x45
    sw   t0, 688(x0)
    addi t0, x0, 0x56
    sw   t0, 692(x0)
    addi t0, x0, 0x45
    sw   t0, 696(x0)
    addi t0, x0, 0x52
    sw   t0, 700(x0)
    addi t0, x0, 0x53
    sw   t0, 704(x0)
    addi t0, x0, 0x45
    sw   t0, 708(x0)
    addi t0, x0, 0xd
    sw   t0, 712(x0)
    addi t0, x0, 0xa
    sw   t0, 716(x0)
    sw   x0, 720(x0)
# STR_N3 @ 0x2d4 'DUPLICATES\r\n'
    addi t0, x0, 0x44
    sw   t0, 724(x0)
    addi t0, x0, 0x55
    sw   t0, 728(x0)
    addi t0, x0, 0x50
    sw   t0, 732(x0)
    addi t0, x0, 0x4c
    sw   t0, 736(x0)
    addi t0, x0, 0x49
    sw   t0, 740(x0)
    addi t0, x0, 0x43
    sw   t0, 744(x0)
    addi t0, x0, 0x41
    sw   t0, 748(x0)
    addi t0, x0, 0x54
    sw   t0, 752(x0)
    addi t0, x0, 0x45
    sw   t0, 756(x0)
    addi t0, x0, 0x53
    sw   t0, 760(x0)
    addi t0, x0, 0xd
    sw   t0, 764(x0)
    addi t0, x0, 0xa
    sw   t0, 768(x0)
    sw   x0, 772(x0)
# STR_N4 @ 0x308 'RANDOM\r\n'
    addi t0, x0, 0x52
    sw   t0, 776(x0)
    addi t0, x0, 0x41
    sw   t0, 780(x0)
    addi t0, x0, 0x4e
    sw   t0, 784(x0)
    addi t0, x0, 0x44
    sw   t0, 788(x0)
    addi t0, x0, 0x4f
    sw   t0, 792(x0)
    addi t0, x0, 0x4d
    sw   t0, 796(x0)
    addi t0, x0, 0xd
    sw   t0, 800(x0)
    addi t0, x0, 0xa
    sw   t0, 804(x0)
    sw   x0, 808(x0)

    addi t0, x0, 4
    sw   t0, 0x14(x0)
    addi s2, x0, 64
    addi s3, x0, 1
    jal  x0, print_str

print_prompt:
    addi s2, x0, 412
    addi s3, x0, 2
    jal  x0, print_str

wait_cmd:
    lw   t0, 4(a0)
    andi t0, t0, 2
    beq  t0, x0, wait_cmd
    lw   t0, 8(a0)
    addi t1, x0, 0x0D
    beq  t0, t1, wait_cmd
    addi t1, x0, 0x0A
    beq  t0, t1, wait_cmd
    addi t1, x0, 0x31
    beq  t0, t1, do_1
    addi t1, x0, 0x32
    beq  t0, t1, do_2
    addi t1, x0, 0x33
    beq  t0, t1, do_3
    addi t1, x0, 0x34
    beq  t0, t1, do_4
    addi t1, x0, 0x72
    beq  t0, t1, do_r
    addi s2, x0, 420
    addi s3, x0, 1
    jal  x0, print_str

do_r:
    lw   t0, 0x14(x0)
    addi t1, x0, 1
    beq  t0, t1, do_1
    addi t1, x0, 2
    beq  t0, t1, do_2
    addi t1, x0, 3
    beq  t0, t1, do_3
    jal  x0, do_4

do_1:
    addi t0, x0, 1
    sw   t0, 0x14(x0)
    addi t0, x0, 1
    sw   t0, 0(x0)
    addi t0, x0, 2
    sw   t0, 4(x0)
    addi t0, x0, 3
    sw   t0, 8(x0)
    addi t0, x0, 4
    sw   t0, 12(x0)
    addi t0, x0, 5
    sw   t0, 16(x0)
    jal  x0, run_case

do_2:
    addi t0, x0, 2
    sw   t0, 0x14(x0)
    addi t0, x0, 5
    sw   t0, 0(x0)
    addi t0, x0, 4
    sw   t0, 4(x0)
    addi t0, x0, 3
    sw   t0, 8(x0)
    addi t0, x0, 2
    sw   t0, 12(x0)
    addi t0, x0, 1
    sw   t0, 16(x0)
    jal  x0, run_case

do_3:
    addi t0, x0, 3
    sw   t0, 0x14(x0)
    addi t0, x0, 3
    sw   t0, 0(x0)
    addi t0, x0, 1
    sw   t0, 4(x0)
    addi t0, x0, 3
    sw   t0, 8(x0)
    addi t0, x0, 2
    sw   t0, 12(x0)
    addi t0, x0, 1
    sw   t0, 16(x0)
    jal  x0, run_case

do_4:
    addi t0, x0, 4
    sw   t0, 0x14(x0)
    addi t0, x0, 4
    sw   t0, 0(x0)
    addi t0, x0, 2
    sw   t0, 4(x0)
    addi t0, x0, 5
    sw   t0, 8(x0)
    addi t0, x0, 1
    sw   t0, 12(x0)
    addi t0, x0, 3
    sw   t0, 16(x0)
    jal  x0, run_case

run_case:
    addi s2, x0, 500
    addi s3, x0, 4
    jal  x0, print_str

send_digit:
    lw   s10, 0x14(x0)
    addi s10, s10, 0x30
send_digit_wait:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, send_digit_wait
    sw   s10, 0(a0)
    addi s2, x0, 532
    addi s3, x0, 5
    jal  x0, print_str

send_name:
    lw   t0, 0x14(x0)
    addi t1, x0, 1
    beq  t0, t1, name_1
    addi t1, x0, 2
    beq  t0, t1, name_2
    addi t1, x0, 3
    beq  t0, t1, name_3
    addi s2, x0, 776
    jal  x0, name_go
name_1:
    addi s2, x0, 648
    jal  x0, name_go
name_2:
    addi s2, x0, 684
    jal  x0, name_go
name_3:
    addi s2, x0, 724
name_go:
    addi s3, x0, 6
    jal  x0, print_str

print_in_label:
    addi s2, x0, 544
    addi s3, x0, 7
    jal  x0, print_str

print_nums_in:
    addi s3, x0, 10
    jal  x0, print_nums

do_sort:
    addi s0, x0, 0
outer_loop:
    addi t1, x0, 0
    addi s1, x0, 4
inner_loop:
    lw   t2, 0(t1)
    lw   t3, 4(t1)
    bge  t3, t2, no_swap
    sw   t3, 0(t1)
    sw   t2, 4(t1)
no_swap:
    addi t1, t1, 4
    addi s1, s1, -1
    bne  s1, x0, inner_loop
    addi s0, s0, 1
    addi t4, x0, 4
    bne  s0, t4, outer_loop
    addi s2, x0, 568
    addi s3, x0, 8
    jal  x0, print_str

print_nums_out:
    addi s3, x0, 11
    jal  x0, print_nums

do_check:
    addi t1, x0, 0
    addi s0, x0, 4
chk_loop:
    lw   t2, 0(t1)
    lw   t3, 4(t1)
    blt  t3, t2, is_fail
    addi t1, t1, 4
    addi s0, s0, -1
    bne  s0, x0, chk_loop
    addi s2, x0, 592
    addi s3, x0, 1
    jal  x0, print_str
is_fail:
    addi s2, x0, 620
    addi s3, x0, 1
    jal  x0, print_str

print_str:
    lw   s10, 0(s2)
    beq  s10, x0, print_str_done
print_str_wait:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, print_str_wait
    sw   s10, 0(a0)
    addi s2, s2, 4
    jal  x0, print_str
print_str_done:
    addi t0, x0, 1
    beq  s3, t0, print_prompt
    addi t0, x0, 2
    beq  s3, t0, wait_cmd
    addi t0, x0, 4
    beq  s3, t0, send_digit
    addi t0, x0, 5
    beq  s3, t0, send_name
    addi t0, x0, 6
    beq  s3, t0, print_in_label
    addi t0, x0, 7
    beq  s3, t0, print_nums_in
    addi t0, x0, 8
    beq  s3, t0, print_nums_out
    jal  x0, wait_cmd

print_nums:
    addi s7, x0, 0
    addi s8, x0, 5
print_nums_loop:
    lw   s10, 0(s7)
    addi s10, s10, 0x30
pn_wait:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, pn_wait
    sw   s10, 0(a0)
    addi s8, s8, -1
    beq  s8, x0, pn_cr
pn_sp:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, pn_sp
    addi t0, x0, 0x20
    sw   t0, 0(a0)
    addi s7, s7, 4
    jal  x0, print_nums_loop
pn_cr:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, pn_cr
    addi t0, x0, 0x0D
    sw   t0, 0(a0)
pn_lf:
    lw   t0, 4(a0)
    andi t0, t0, 1
    bne  t0, x0, pn_lf
    addi t0, x0, 0x0A
    sw   t0, 0(a0)
    addi t0, x0, 10
    beq  s3, t0, do_sort
    addi t0, x0, 11
    beq  s3, t0, do_check
    jal  x0, wait_cmd


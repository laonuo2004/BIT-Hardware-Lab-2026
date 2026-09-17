#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Huang's sort_uart.asm / .mem. Does not write 冯丽嘉's files."""
import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROG = HERE.parent / "programs"
ASM_PATH = PROG / "sort_uart.asm"
MEM_PATH = PROG / "sort_uart.mem"

FENG_TOOL = HERE.parent.parent / "冯丽嘉 提交文件" / "tools" / "rv32_tool.py"

STR_BASE = 0x40
STRINGS = [
    ("STR_MENU", "BIT CPU + UART DEMO\r\n"
                 "1 - SORTED\r\n"
                 "2 - REVERSE\r\n"
                 "3 - DUPLICATES\r\n"
                 "4 - RANDOM\r\n"
                 "s - CUSTOM\r\n"
                 "r - REPEAT\r\n"),
    ("STR_PROMPT", ">"),
    ("STR_UNK", "\r\nUNKNOWN COMMAND\r\n"),
    ("STR_CASE", "\r\nCASE "),
    ("STR_COLON", ": "),
    ("STR_IN", "IN : "),
    ("STR_OUT", "OUT: "),
    ("STR_PASS", "PASS\r\n"),
    ("STR_FAIL", "FAIL\r\n"),
    ("STR_N1", "SORTED\r\n"),
    ("STR_N2", "REVERSE\r\n"),
    ("STR_N3", "DUPLICATES\r\n"),
    ("STR_N4", "RANDOM\r\n"),
    ("STR_NS", "CUSTOM\r\n"),
    ("STR_DIGITS", "\r\nDIGITS:"),
    ("STR_BAD", "\r\nBAD DIGIT\r\n"),
]

addr = STR_BASE
STR = {}
for name, text in STRINGS:
    STR[name] = addr
    addr += 4 * (len(text) + 1)

RET_PROMPT = 1
RET_WAIT = 2
RET_DIGIT = 4
RET_NAME = 5
RET_INL = 6
RET_IN_NUMS = 7
RET_OUT_NUMS = 8
RET_AFTER_IN = 10
RET_AFTER_OUT = 11
RET_READ = 12


def generate_asm():
    lines = []
    A = lines.append
    A("# ============================================================")
    A("# sort_uart.asm — UART 交互式多数据集排序（黄奕晨）")
    A("#")
    A("#   1 已排序 1 2 3 4 5")
    A("#   2 逆序   5 4 3 2 1")
    A("#   3 重复   3 1 3 2 1")
    A("#   4 乱序   4 2 5 1 3")
    A("#   s 输入 5 个一位数字后排序")
    A("#   r 重复上一次（上电默认 4）")
    A("#   其它字符 UNKNOWN COMMAND；忽略 CR/LF")
    A("# RAM：a[0..4] @ 0x00，last_case @ 0x14，custom 备份 @ 0x20")
    A("# ============================================================")
    A("    .text")
    A("    .globl main")
    A("")
    A("main:")
    A("    lui  a0, 0x40000")
    A("")
    for name, text in STRINGS:
        base = STR[name]
        A(f"# {name} @ {base:#x} {text!r}")
        for i, ch in enumerate(text):
            A(f"    addi t0, x0, {ord(ch):#x}")
            A(f"    sw   t0, {base + 4 * i}(x0)")
        A(f"    sw   x0, {base + 4 * len(text)}(x0)")
    A("")
    A("    addi t0, x0, 4")
    A("    sw   t0, 0x14(x0)")
    A(f"    addi s2, x0, {STR['STR_MENU']}")
    A(f"    addi s3, x0, {RET_PROMPT}")
    A("    jal  x0, print_str")
    A("")
    A("print_prompt:")
    A(f"    addi s2, x0, {STR['STR_PROMPT']}")
    A(f"    addi s3, x0, {RET_WAIT}")
    A("    jal  x0, print_str")
    A("")
    A("wait_cmd:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 2")
    A("    beq  t0, x0, wait_cmd")
    A("    lw   t0, 8(a0)")
    A("    addi t1, x0, 0x0D")
    A("    beq  t0, t1, wait_cmd")
    A("    addi t1, x0, 0x0A")
    A("    beq  t0, t1, wait_cmd")
    A("    addi t1, x0, 0x31")
    A("    beq  t0, t1, do_1")
    A("    addi t1, x0, 0x32")
    A("    beq  t0, t1, do_2")
    A("    addi t1, x0, 0x33")
    A("    beq  t0, t1, do_3")
    A("    addi t1, x0, 0x34")
    A("    beq  t0, t1, do_4")
    A("    addi t1, x0, 0x73")
    A("    beq  t0, t1, do_s")
    A("    addi t1, x0, 0x72")
    A("    beq  t0, t1, do_r")
    A(f"    addi s2, x0, {STR['STR_UNK']}")
    A(f"    addi s3, x0, {RET_PROMPT}")
    A("    jal  x0, print_str")
    A("")
    A("do_r:")
    A("    lw   t0, 0x14(x0)")
    A("    addi t1, x0, 1")
    A("    beq  t0, t1, do_1")
    A("    addi t1, x0, 2")
    A("    beq  t0, t1, do_2")
    A("    addi t1, x0, 3")
    A("    beq  t0, t1, do_3")
    A("    addi t1, x0, 5")
    A("    beq  t0, t1, do_s_repeat")
    A("    jal  x0, do_4")
    A("")
    A("do_1:")
    A("    addi t0, x0, 1")
    A("    sw   t0, 0x14(x0)")
    A("    addi t0, x0, 1")
    A("    sw   t0, 0(x0)")
    A("    addi t0, x0, 2")
    A("    sw   t0, 4(x0)")
    A("    addi t0, x0, 3")
    A("    sw   t0, 8(x0)")
    A("    addi t0, x0, 4")
    A("    sw   t0, 12(x0)")
    A("    addi t0, x0, 5")
    A("    sw   t0, 16(x0)")
    A("    jal  x0, run_case")
    A("")
    A("do_2:")
    A("    addi t0, x0, 2")
    A("    sw   t0, 0x14(x0)")
    A("    addi t0, x0, 5")
    A("    sw   t0, 0(x0)")
    A("    addi t0, x0, 4")
    A("    sw   t0, 4(x0)")
    A("    addi t0, x0, 3")
    A("    sw   t0, 8(x0)")
    A("    addi t0, x0, 2")
    A("    sw   t0, 12(x0)")
    A("    addi t0, x0, 1")
    A("    sw   t0, 16(x0)")
    A("    jal  x0, run_case")
    A("")
    A("do_3:")
    A("    addi t0, x0, 3")
    A("    sw   t0, 0x14(x0)")
    A("    addi t0, x0, 3")
    A("    sw   t0, 0(x0)")
    A("    addi t0, x0, 1")
    A("    sw   t0, 4(x0)")
    A("    addi t0, x0, 3")
    A("    sw   t0, 8(x0)")
    A("    addi t0, x0, 2")
    A("    sw   t0, 12(x0)")
    A("    addi t0, x0, 1")
    A("    sw   t0, 16(x0)")
    A("    jal  x0, run_case")
    A("")
    A("do_4:")
    A("    addi t0, x0, 4")
    A("    sw   t0, 0x14(x0)")
    A("    addi t0, x0, 4")
    A("    sw   t0, 0(x0)")
    A("    addi t0, x0, 2")
    A("    sw   t0, 4(x0)")
    A("    addi t0, x0, 5")
    A("    sw   t0, 8(x0)")
    A("    addi t0, x0, 1")
    A("    sw   t0, 12(x0)")
    A("    addi t0, x0, 3")
    A("    sw   t0, 16(x0)")
    A("    jal  x0, run_case")
    A("")
    A("do_s:")
    A(f"    addi s2, x0, {STR['STR_DIGITS']}")
    A(f"    addi s3, x0, {RET_READ}")
    A("    jal  x0, print_str")
    A("")
    A("read_digits:")
    A("    addi s7, x0, 0")
    A("    addi s8, x0, 5")
    A("wait_digit:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 2")
    A("    beq  t0, x0, wait_digit")
    A("    lw   t0, 8(a0)")
    A("    addi t1, x0, 0x0D")
    A("    beq  t0, t1, wait_digit")
    A("    addi t1, x0, 0x0A")
    A("    beq  t0, t1, wait_digit")
    A("    addi t1, x0, 0x30")
    A("    blt  t0, t1, bad_digit")
    A("    addi t1, x0, 0x3A")
    A("    bge  t0, t1, bad_digit")
    A("    addi t0, t0, -48")
    A("    sw   t0, 0(s7)")
    A("    addi s7, s7, 4")
    A("    addi s8, s8, -1")
    A("    bne  s8, x0, wait_digit")
    A("    lw   t0, 0(x0)")
    A("    sw   t0, 0x20(x0)")
    A("    lw   t0, 4(x0)")
    A("    sw   t0, 0x24(x0)")
    A("    lw   t0, 8(x0)")
    A("    sw   t0, 0x28(x0)")
    A("    lw   t0, 12(x0)")
    A("    sw   t0, 0x2C(x0)")
    A("    lw   t0, 16(x0)")
    A("    sw   t0, 0x30(x0)")
    A("    addi t0, x0, 5")
    A("    sw   t0, 0x14(x0)")
    A("    jal  x0, run_case")
    A("")
    A("do_s_repeat:")
    A("    lw   t0, 0x20(x0)")
    A("    sw   t0, 0(x0)")
    A("    lw   t0, 0x24(x0)")
    A("    sw   t0, 4(x0)")
    A("    lw   t0, 0x28(x0)")
    A("    sw   t0, 8(x0)")
    A("    lw   t0, 0x2C(x0)")
    A("    sw   t0, 12(x0)")
    A("    lw   t0, 0x30(x0)")
    A("    sw   t0, 16(x0)")
    A("    jal  x0, run_case")
    A("")
    A("bad_digit:")
    A(f"    addi s2, x0, {STR['STR_BAD']}")
    A(f"    addi s3, x0, {RET_PROMPT}")
    A("    jal  x0, print_str")
    A("")
    A("run_case:")
    A(f"    addi s2, x0, {STR['STR_CASE']}")
    A(f"    addi s3, x0, {RET_DIGIT}")
    A("    jal  x0, print_str")
    A("")
    A("send_digit:")
    A("    lw   s10, 0x14(x0)")
    A("    addi t1, x0, 5")
    A("    beq  s10, t1, send_letter_s")
    A("    addi s10, s10, 0x30")
    A("    jal  x0, send_digit_wait")
    A("send_letter_s:")
    A("    addi s10, x0, 0x53")
    A("send_digit_wait:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 1")
    A("    bne  t0, x0, send_digit_wait")
    A("    sw   s10, 0(a0)")
    A(f"    addi s2, x0, {STR['STR_COLON']}")
    A(f"    addi s3, x0, {RET_NAME}")
    A("    jal  x0, print_str")
    A("")
    A("send_name:")
    A("    lw   t0, 0x14(x0)")
    A("    addi t1, x0, 1")
    A("    beq  t0, t1, name_1")
    A("    addi t1, x0, 2")
    A("    beq  t0, t1, name_2")
    A("    addi t1, x0, 3")
    A("    beq  t0, t1, name_3")
    A("    addi t1, x0, 5")
    A("    beq  t0, t1, name_s")
    A(f"    addi s2, x0, {STR['STR_N4']}")
    A("    jal  x0, name_go")
    A("name_1:")
    A(f"    addi s2, x0, {STR['STR_N1']}")
    A("    jal  x0, name_go")
    A("name_2:")
    A(f"    addi s2, x0, {STR['STR_N2']}")
    A("    jal  x0, name_go")
    A("name_3:")
    A(f"    addi s2, x0, {STR['STR_N3']}")
    A("    jal  x0, name_go")
    A("name_s:")
    A(f"    addi s2, x0, {STR['STR_NS']}")
    A("name_go:")
    A(f"    addi s3, x0, {RET_INL}")
    A("    jal  x0, print_str")
    A("")
    A("print_in_label:")
    A(f"    addi s2, x0, {STR['STR_IN']}")
    A(f"    addi s3, x0, {RET_IN_NUMS}")
    A("    jal  x0, print_str")
    A("")
    A("print_nums_in:")
    A(f"    addi s3, x0, {RET_AFTER_IN}")
    A("    jal  x0, print_nums")
    A("")
    A("do_sort:")
    A("    addi s0, x0, 0")
    A("outer_loop:")
    A("    addi t1, x0, 0")
    A("    addi s1, x0, 4")
    A("inner_loop:")
    A("    lw   t2, 0(t1)")
    A("    lw   t3, 4(t1)")
    A("    bge  t3, t2, no_swap")
    A("    sw   t3, 0(t1)")
    A("    sw   t2, 4(t1)")
    A("no_swap:")
    A("    addi t1, t1, 4")
    A("    addi s1, s1, -1")
    A("    bne  s1, x0, inner_loop")
    A("    addi s0, s0, 1")
    A("    addi t4, x0, 4")
    A("    bne  s0, t4, outer_loop")
    A(f"    addi s2, x0, {STR['STR_OUT']}")
    A(f"    addi s3, x0, {RET_OUT_NUMS}")
    A("    jal  x0, print_str")
    A("")
    A("print_nums_out:")
    A(f"    addi s3, x0, {RET_AFTER_OUT}")
    A("    jal  x0, print_nums")
    A("")
    A("do_check:")
    A("    addi t1, x0, 0")
    A("    addi s0, x0, 4")
    A("chk_loop:")
    A("    lw   t2, 0(t1)")
    A("    lw   t3, 4(t1)")
    A("    blt  t3, t2, is_fail")
    A("    addi t1, t1, 4")
    A("    addi s0, s0, -1")
    A("    bne  s0, x0, chk_loop")
    A(f"    addi s2, x0, {STR['STR_PASS']}")
    A(f"    addi s3, x0, {RET_PROMPT}")
    A("    jal  x0, print_str")
    A("is_fail:")
    A(f"    addi s2, x0, {STR['STR_FAIL']}")
    A(f"    addi s3, x0, {RET_PROMPT}")
    A("    jal  x0, print_str")
    A("")
    A("print_str:")
    A("    lw   s10, 0(s2)")
    A("    beq  s10, x0, print_str_done")
    A("print_str_wait:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 1")
    A("    bne  t0, x0, print_str_wait")
    A("    sw   s10, 0(a0)")
    A("    addi s2, s2, 4")
    A("    jal  x0, print_str")
    A("print_str_done:")
    A(f"    addi t0, x0, {RET_PROMPT}")
    A("    beq  s3, t0, print_prompt")
    A(f"    addi t0, x0, {RET_WAIT}")
    A("    beq  s3, t0, wait_cmd")
    A(f"    addi t0, x0, {RET_DIGIT}")
    A("    beq  s3, t0, send_digit")
    A(f"    addi t0, x0, {RET_NAME}")
    A("    beq  s3, t0, send_name")
    A(f"    addi t0, x0, {RET_INL}")
    A("    beq  s3, t0, print_in_label")
    A(f"    addi t0, x0, {RET_IN_NUMS}")
    A("    beq  s3, t0, print_nums_in")
    A(f"    addi t0, x0, {RET_OUT_NUMS}")
    A("    beq  s3, t0, print_nums_out")
    A(f"    addi t0, x0, {RET_READ}")
    A("    beq  s3, t0, read_digits")
    A("    jal  x0, wait_cmd")
    A("")
    A("print_nums:")
    A("    addi s7, x0, 0")
    A("    addi s8, x0, 5")
    A("print_nums_loop:")
    A("    lw   s10, 0(s7)")
    A("    addi s10, s10, 0x30")
    A("pn_wait:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 1")
    A("    bne  t0, x0, pn_wait")
    A("    sw   s10, 0(a0)")
    A("    addi s8, s8, -1")
    A("    beq  s8, x0, pn_cr")
    A("pn_sp:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 1")
    A("    bne  t0, x0, pn_sp")
    A("    addi t0, x0, 0x20")
    A("    sw   t0, 0(a0)")
    A("    addi s7, s7, 4")
    A("    jal  x0, print_nums_loop")
    A("pn_cr:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 1")
    A("    bne  t0, x0, pn_cr")
    A("    addi t0, x0, 0x0D")
    A("    sw   t0, 0(a0)")
    A("pn_lf:")
    A("    lw   t0, 4(a0)")
    A("    andi t0, t0, 1")
    A("    bne  t0, x0, pn_lf")
    A("    addi t0, x0, 0x0A")
    A("    sw   t0, 0(a0)")
    A(f"    addi t0, x0, {RET_AFTER_IN}")
    A("    beq  s3, t0, do_sort")
    A(f"    addi t0, x0, {RET_AFTER_OUT}")
    A("    beq  s3, t0, do_check")
    A("    jal  x0, wait_cmd")
    A("")
    if addr > 0x3FF:
        raise SystemExit(f"string RAM overflow {addr:#x}")
    ASM_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"asm {ASM_PATH} string_end={addr:#x} lines={len(lines)}")


def load_feng():
    spec = importlib.util.spec_from_file_location("feng_rv32", FENG_TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def case_text(label, name, inn, out):
    return (
        b"\r\nCASE " + label + b": " + name + b"\r\n"
        b"IN : " + inn + b"\r\n"
        b"OUT: " + out + b"\r\n"
        b"PASS\r\n>"
    )


def feed(sim, ch, steps=16000):
    start = len(sim.tx_bytes)
    sim.rx_data = ord(ch) if isinstance(ch, str) else ch
    sim.rx_valid = 1
    sim.run(steps)
    return bytes(sim.tx_bytes[start:])


def main():
    generate_asm()
    feng = load_feng()
    words, _ = feng.assemble(ASM_PATH.read_text(encoding="utf-8"))
    MEM_PATH.write_text("".join(f"{w:08X}\n" for w in words), encoding="ascii")
    print(f"mem {MEM_PATH} insns={len(words)}")
    if len(words) > 1024:
        print("[FAIL] ROM overflow")
        sys.exit(1)

    menu = (
        b"BIT CPU + UART DEMO\r\n"
        b"1 - SORTED\r\n"
        b"2 - REVERSE\r\n"
        b"3 - DUPLICATES\r\n"
        b"4 - RANDOM\r\n"
        b"s - CUSTOM\r\n"
        b"r - REPEAT\r\n"
        b">"
    )
    sim = feng.Sim(words)
    sim.run(25000)
    boot = bytes(sim.tx_bytes)
    if boot != menu:
        print(f"[FAIL] menu {boot!r}")
        sys.exit(1)

    custom1 = case_text(b"S", b"CUSTOM", b"2 3 6 5 4", b"2 3 4 5 6")
    prompt = feed(sim, "s")
    if prompt != b"\r\nDIGITS:":
        print(f"[FAIL] digits prompt {prompt!r}")
        sys.exit(1)
    acc = b""
    for ch in "23654":
        acc += feed(sim, ch)
    if acc != custom1:
        print(f"[FAIL] 23654 {acc!r} expected {custom1!r}")
        sys.exit(1)
    if [sim.ram.get(4 * i, 0) for i in range(5)] != [2, 3, 4, 5, 6]:
        print("[FAIL] RAM after 23654")
        sys.exit(1)

    again = feed(sim, "r")
    if again != custom1:
        print(f"[FAIL] repeat custom {again!r}")
        sys.exit(1)

    custom2 = case_text(b"S", b"CUSTOM", b"3 4 7 6 5", b"3 4 5 6 7")
    if feed(sim, "s") != b"\r\nDIGITS:":
        print("[FAIL] second digits prompt")
        sys.exit(1)
    acc = b""
    for ch in "34765":
        acc += feed(sim, ch)
    if acc != custom2:
        print(f"[FAIL] 34765 {acc!r}")
        sys.exit(1)

    if feed(sim, "s") != b"\r\nDIGITS:":
        print("[FAIL] third digits prompt")
        sys.exit(1)
    if feed(sim, "\r", 4000) or feed(sim, "\n", 4000):
        print("[FAIL] CR/LF during digits")
        sys.exit(1)
    bad = feed(sim, "x")
    if bad != b"\r\nBAD DIGIT\r\n>":
        print(f"[FAIL] bad digit {bad!r}")
        sys.exit(1)

    print("[PASS] custom 5-digit sort")


if __name__ == "__main__":
    main()

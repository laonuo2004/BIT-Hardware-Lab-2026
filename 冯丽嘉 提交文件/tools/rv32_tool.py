#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
rv32_tool.py — 冯丽嘉应用汇编的汇编器 + 逻辑仿真器 + 验证器

只支持本实训固定的 16 条 RV32I 指令：
  add sub xor addi ori lui lw sw beq bne blt bge jal and or andi

用途：
  1. 把 sort_uart.asm 汇编成机器码，写出 sort_uart.mem（供 system_env 的 $readmemh 加载）。
  2. 用一个顺序执行的模型 CPU + 简化的 UART 模型，端到端验证：
       排序结果、UART 输出字符串、收到 'r' 后重新运行。

运行：python rv32_tool.py （仅需 Python 3，无需 iverilog / RARS）
"""
import os
import sys

# ---------------- 寄存器名表 ----------------
ABI = {
    "zero": 0, "x0": 0, "ra": 1, "x1": 1, "sp": 2, "x2": 2, "gp": 3, "x3": 3,
    "tp": 4, "x4": 4, "t0": 5, "x5": 5, "t1": 6, "x6": 6, "t2": 7, "x7": 7,
    "s0": 8, "fp": 8, "x8": 8, "s1": 9, "x9": 9, "a0": 10, "x10": 10,
    "a1": 11, "x11": 11, "a2": 12, "x12": 12, "a3": 13, "x13": 13,
    "a4": 14, "x14": 14, "a5": 15, "x15": 15, "a6": 16, "x16": 16,
    "a7": 17, "x17": 17, "s2": 18, "x18": 18, "s3": 19, "x19": 19,
    "s4": 20, "x20": 20, "s5": 21, "x21": 21, "s6": 22, "x22": 22,
    "s7": 23, "x23": 23, "s8": 24, "x24": 24, "s9": 25, "x25": 25,
    "s10": 26, "x26": 26, "s11": 27, "x27": 27, "t3": 28, "x28": 28,
    "t4": 29, "x29": 29, "t5": 30, "x30": 30, "t6": 31, "x31": 31,
}


def reg(name):
    name = name.strip().lower()
    if name not in ABI:
        raise ValueError(f"未知寄存器: {name}")
    return ABI[name]


def sext(v, bits):
    v &= (1 << bits) - 1
    if v & (1 << (bits - 1)):
        v -= (1 << bits)
    return v


def s32(v):
    return v - (1 << 32) if v & 0x80000000 else v


def imm_parse(s):
    s = s.strip()
    return int(s, 16 if s.lower().startswith("0x") else 10)


# ---------------- 汇编器 ----------------
def assemble(asm_text):
    lines = []
    for raw in asm_text.splitlines():
        s = raw.split("#", 1)[0].strip()
        if not s:
            continue
        if s.startswith("."):  # 跳过 .text / .globl 等汇编伪指令
            continue
        lines.append(s)

    labels, body, pc = {}, [], 0
    for s in lines:
        if s.endswith(":"):
            name = s[:-1].strip()
            if name in labels:
                raise ValueError(f"重复标签: {name}")
            labels[name] = pc
        else:
            body.append(s)
            pc += 4

    words = []
    for s in body:
        parts = s.replace(",", " ").split()
        mnem = parts[0].lower()
        ops = parts[1:]
        w = None

        if mnem in ("add", "sub", "xor", "or", "and"):
            r_d, r_s1, r_s2 = reg(ops[0]), reg(ops[1]), reg(ops[2])
            f7 = 0x20 if mnem == "sub" else 0
            f3 = {"add": 0, "sub": 0, "xor": 4, "or": 6, "and": 7}[mnem]
            w = (f7 << 25) | (r_s2 << 20) | (r_s1 << 15) | (f3 << 12) | (r_d << 7) | 0x33

        elif mnem in ("addi", "ori", "andi"):
            r_d, r_s1 = reg(ops[0]), reg(ops[1])
            imm = imm_parse(ops[2]) & 0xFFF
            f3 = {"addi": 0, "ori": 6, "andi": 7}[mnem]
            w = (imm << 20) | (r_s1 << 15) | (f3 << 12) | (r_d << 7) | 0x13

        elif mnem == "lui":
            r_d = reg(ops[0])
            imm = imm_parse(ops[1]) & 0xFFFFF
            w = (imm << 12) | (r_d << 7) | 0x37

        elif mnem in ("lw", "sw"):
            mm = ops[1]
            off, base = mm.split("(")
            base = base.rstrip(")")
            imm = imm_parse(off) & 0xFFF
            if mnem == "lw":
                r_d, r_s1 = reg(ops[0]), reg(base)
                w = (imm << 20) | (r_s1 << 15) | (0x2 << 12) | (r_d << 7) | 0x03
            else:  # sw rs2, imm(rs1)
                r_s2, r_s1 = reg(ops[0]), reg(base)
                w = (((imm >> 5) & 0x7F) << 25) | (r_s2 << 20) | (r_s1 << 15) \
                    | (0x2 << 12) | ((imm & 0x1F) << 7) | 0x23

        elif mnem in ("beq", "bne", "blt", "bge"):
            r_s1, r_s2 = reg(ops[0]), reg(ops[1])
            target = labels[ops[2]]
            imm = target - (len(words) * 4)
            f3 = {"beq": 0, "bne": 1, "blt": 4, "bge": 5}[mnem]
            w = (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) \
                | (r_s2 << 20) | (r_s1 << 15) | (f3 << 12) \
                | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | 0x63

        elif mnem == "jal":
            r_d = reg(ops[0])
            target = labels[ops[1]]
            imm = target - (len(words) * 4)
            w = (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) \
                | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) \
                | (r_d << 7) | 0x6F

        else:
            raise ValueError(f"未支持的指令: {mnem}")

        words.append(w & 0xFFFFFFFF)
    return words, labels


# ---------------- 仿真器 + 简化 UART ----------------
class Sim:
    def __init__(self, words):
        self.rom = words
        self.regs = [0] * 32
        self.ram = {}
        self.pc = 0
        self.tx_bytes = []
        self.rx_valid = 0
        self.rx_data = 0

    def lw(self, addr):
        if addr & 3:
            raise RuntimeError(f"非对齐读 {addr:#x}")
        if addr < 0x400:
            return self.ram.get(addr, 0)
        if addr == 0x40000000:
            return 0
        if addr == 0x40000004:
            return 2 if self.rx_valid else 0  # bit1 = RX 有效，bit0 = 忙
        if addr == 0x40000008:
            if self.rx_valid:
                self.rx_valid = 0
                return self.rx_data & 0xFF
            return 0
        return 0

    def sw(self, addr, data):
        if addr & 3:
            raise RuntimeError(f"非对齐写 {addr:#x}")
        if addr < 0x400:
            self.ram[addr] = data & 0xFFFFFFFF
        elif addr == 0x40000000:
            self.tx_bytes.append(data & 0xFF)

    def step(self):
        if self.pc < 0 or self.pc >= len(self.rom) * 4 or (self.pc & 3):
            raise RuntimeError(f"PC 越界 {self.pc:#x}")
        inst = self.rom[self.pc // 4]
        pc = self.pc
        self.pc += 4

        opcode = inst & 0x7F
        rd = (inst >> 7) & 0x1F
        f3 = (inst >> 12) & 0x7
        rs1 = (inst >> 15) & 0x1F
        rs2 = (inst >> 20) & 0x1F
        f7 = (inst >> 25) & 0x7F

        def i_imm(): return sext(inst >> 20, 12)
        def s_imm(): return sext(((inst >> 25) << 5) | ((inst >> 7) & 0x1F), 12)
        def b_imm():
            return sext(((inst >> 31) & 1) << 12 | ((inst >> 7) & 1) << 11
                        | ((inst >> 25) & 0x3F) << 5 | ((inst >> 8) & 0xF) << 1, 13)
        def j_imm():
            return sext(((inst >> 31) & 1) << 20 | ((inst >> 12) & 0xFF) << 12
                        | ((inst >> 20) & 1) << 11 | ((inst >> 21) & 0x3FF) << 1, 21)

        a, b = self.regs[rs1], self.regs[rs2]

        if opcode == 0x33:
            if f3 == 0:
                r = a - b if f7 == 0x20 else a + b
            elif f3 == 4:
                r = a ^ b
            elif f3 == 6:
                r = a | b
            elif f3 == 7:
                r = a & b
            else:
                raise RuntimeError(f"非法 R 型 @ {pc:#x}")
            if rd:
                self.regs[rd] = r & 0xFFFFFFFF

        elif opcode == 0x13:
            imm = i_imm()
            r = (a + imm) if f3 == 0 else (a | imm) if f3 == 6 else (a & imm)
            if rd:
                self.regs[rd] = r & 0xFFFFFFFF

        elif opcode == 0x37:  # lui
            if rd:
                self.regs[rd] = inst & 0xFFFFF000

        elif opcode == 0x03:  # lw
            if rd:
                self.regs[rd] = self.lw(a + i_imm())

        elif opcode == 0x23:  # sw
            self.sw(a + s_imm(), b)

        elif opcode == 0x63:
            take = {0: a == b, 1: a != b, 4: s32(a) < s32(b), 5: s32(a) >= s32(b)}[f3]
            if take:
                self.pc = pc + b_imm()

        elif opcode == 0x6F:  # jal
            if rd:
                self.regs[rd] = pc + 4
            self.pc = pc + j_imm()

        else:
            raise RuntimeError(f"非法 opcode {opcode:#x} @ pc {pc:#x}")

    def run(self, n):
        for _ in range(n):
            self.step()


# ---------------- 验证 ----------------
def main():
    here = os.path.dirname(os.path.abspath(__file__))
    asm_path = os.path.join(here, "..", "programs", "sort_uart.asm")
    mem_path = os.path.join(here, "..", "programs", "sort_uart.mem")

    with open(asm_path, encoding="utf-8") as f:
        words, labels = assemble(f.read())

    with open(mem_path, "w", encoding="ascii") as f:
        for w in words:
            f.write(f"{w:08X}\n")

    expected = b"SORT: 1 2 3 4 5\r\n"

    sim = Sim(words)
    sim.run(4000)
    tx1 = bytes(sim.tx_bytes)
    ram1 = [sim.ram.get(4 * i, 0) for i in range(5)]

    sim.rx_data = ord('r')
    sim.rx_valid = 1
    sim.run(4000)
    tx2 = bytes(sim.tx_bytes[len(tx1):])
    ram2 = [sim.ram.get(4 * i, 0) for i in range(5)]

    print(f"指令条数: {len(words)}")
    print(f"第一轮输出: {tx1!r}")
    print(f"第二轮输出: {tx2!r}")
    print(f"排序后 RAM : {ram1}")
    print(f"重跑后 RAM : {ram2}")

    ok = (tx1 == expected and tx2 == expected
          and ram1 == [1, 2, 3, 4, 5] and ram2 == [1, 2, 3, 4, 5])
    if not ok:
        if tx1 != expected:
            print(f"[FAIL] 第一轮输出不符，期望 {expected!r}")
        if tx2 != expected:
            print(f"[FAIL] 第二轮输出不符，期望 {expected!r}")
        if ram1 != [1, 2, 3, 4, 5]:
            print(f"[FAIL] 排序结果错误: {ram1}")
        if ram2 != [1, 2, 3, 4, 5]:
            print(f"[FAIL] 重跑排序结果错误: {ram2}")
        sys.exit(1)

    print("[PASS] 全部验证通过")
    print(f"机器码已写出: {os.path.normpath(mem_path)}")


if __name__ == "__main__":
    main()

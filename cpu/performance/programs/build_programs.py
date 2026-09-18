"""Generate deterministic memory images for both F3 performance rounds."""

from pathlib import Path
import shutil

HERE = Path(__file__).resolve().parent
CPU = HERE.parents[1]


def check_reg(reg: int) -> None:
    if not 0 <= reg < 32:
        raise ValueError(f"invalid register x{reg}")


def check_signed(value: int, bits: int) -> None:
    if not -(1 << (bits - 1)) <= value < (1 << (bits - 1)):
        raise ValueError(f"{value} does not fit signed {bits}-bit immediate")


def addi(rd: int, rs1: int, imm: int) -> int:
    check_reg(rd)
    check_reg(rs1)
    check_signed(imm, 12)
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | 0x13


def ori(rd: int, rs1: int, imm: int) -> int:
    check_reg(rd)
    check_reg(rs1)
    check_signed(imm, 12)
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (0b110 << 12) | (rd << 7) | 0x13


def xor(rd: int, rs1: int, rs2: int) -> int:
    check_reg(rd)
    check_reg(rs1)
    check_reg(rs2)
    return (rs2 << 20) | (rs1 << 15) | (0b100 << 12) | (rd << 7) | 0x33


def lw(rd: int, rs1: int, imm: int) -> int:
    check_reg(rd)
    check_reg(rs1)
    check_signed(imm, 12)
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (0b010 << 12) | (rd << 7) | 0x03


def sw(rs2: int, rs1: int, imm: int) -> int:
    check_reg(rs1)
    check_reg(rs2)
    check_signed(imm, 12)
    value = imm & 0xFFF
    return (((value >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (0b010 << 12) | ((value & 0x1F) << 7) | 0x23


def branch(rs1: int, rs2: int, offset: int, funct3: int) -> int:
    check_reg(rs1)
    check_reg(rs2)
    check_signed(offset, 13)
    if offset & 1:
        raise ValueError("branch offset must be two-byte aligned")
    value = offset & 0x1FFF
    return (((value >> 12) & 1) << 31) | (((value >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((value >> 1) & 0xF) << 8) | (((value >> 11) & 1) << 7) | 0x63


def blt(rs1: int, rs2: int, offset: int) -> int:
    return branch(rs1, rs2, offset, 0b100)


def bge(rs1: int, rs2: int, offset: int) -> int:
    return branch(rs1, rs2, offset, 0b101)


def jal(rd: int, offset: int) -> int:
    check_reg(rd)
    check_signed(offset, 21)
    if offset & 1:
        raise ValueError("jal offset must be two-byte aligned")
    value = offset & 0x1FFFFF
    return (((value >> 20) & 1) << 31) | (((value >> 1) & 0x3FF) << 21) | (((value >> 11) & 1) << 20) | (((value >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F


def write_mem(path: Path, words: list[int], size: int = 256) -> None:
    if len(words) > size:
        raise ValueError(f"{path.name}: {len(words)} words exceed {size}-word ROM")
    padded = words + [0x00000013] * (size - len(words))
    path.write_text("".join(f"{word:08x}\n" for word in padded), encoding="ascii")


def write_data(path: Path, words: list[int], size: int = 256) -> None:
    if len(words) > size:
        raise ValueError(f"{path.name}: {len(words)} words exceed {size}-word RAM")
    padded = words + [0] * (size - len(words))
    path.write_text("".join(f"{word & 0xFFFFFFFF:08x}\n" for word in padded), encoding="ascii")


def write_asm(name: str, text: str) -> None:
    (HERE / f"{name}.asm").write_text(text.rstrip() + "\n", encoding="utf-8")


# Round 1 remains reproducible and its archived results are never overwritten.
independent = [addi(rd, 0, rd) for rd in range(1, 21)] + [jal(0, 0)]
dependency = [addi(1, 0, 1)] + [addi(1, 1, 1)] * 19 + [jal(0, 0)]
write_mem(HERE / "independent_text.mem", independent)
write_data(HERE / "independent_data.mem", [])
write_mem(HERE / "dependency_text.mem", dependency)
write_data(HERE / "dependency_data.mem", [])
shutil.copyfile(CPU / "pipeline" / "programs" / "text.mem", HERE / "sort_text.mem")
shutil.copyfile(CPU / "pipeline" / "programs" / "data.mem", HERE / "sort_data.mem")


independent_long = []
independent_asm = ["# 240 independent addi instructions; END_PC = 0x3c0."]
for i in range(1, 241):
    rd = ((i - 1) % 30) + 1
    imm = ((i - 1) % 31) + 1
    independent_long.append(addi(rd, 0, imm))
    independent_asm.append(f"addi x{rd}, x0, {imm}")
independent_long.append(jal(0, 0))
independent_asm.extend(["finished:", "jal x0, finished"])
write_mem(HERE / "independent_long_text.mem", independent_long)
write_data(HERE / "independent_long_data.mem", [])
write_asm("independent_long", "\n".join(independent_asm))


dependency_long = [addi(1, 0, 1)] + [addi(1, 1, 1)] * 127 + [jal(0, 0)]
dependency_asm = [
    "# 128 writes to x1 with continuous RAW dependencies; END_PC = 0x200.",
    "addi x1, x0, 1",
    "# Repeat the following instruction 127 times:",
    *(["addi x1, x1, 1"] * 127),
    "finished:",
    "jal x0, finished",
]
write_mem(HERE / "dependency_long_text.mem", dependency_long)
write_data(HERE / "dependency_long_data.mem", [])
write_asm("dependency_long", "\n".join(dependency_asm))


btfnt_loop = [
    addi(1, 0, 0),
    addi(2, 0, 256),
    addi(1, 1, 1),
    blt(1, 2, -4),
    jal(0, 0),
]
write_mem(HERE / "btfnt_loop_text.mem", btfnt_loop)
write_data(HERE / "btfnt_loop_data.mem", [])
write_asm(
    "btfnt_loop",
    """# 256-iteration BTFNT loop; END_PC = 0x10.
addi x1, x0, 0
addi x2, x0, 256
loop:
addi x1, x1, 1
blt  x1, x2, loop
finished:
jal  x0, finished""",
)


sort32_reverse = [
    addi(0, 0, 0),
    xor(7, 7, 7),
    addi(8, 7, 128),
    ori(5, 7, 0),
    jal(1, 44),
    addi(6, 7, 124),
    jal(1, 28),
    lw(10, 6, 0),
    lw(11, 6, -4),
    bge(10, 11, 12),
    sw(11, 6, 0),
    sw(10, 6, -4),
    addi(6, 6, -4),
    blt(5, 6, -24),
    addi(5, 5, 4),
    blt(5, 8, -40),
    jal(0, 0),
]
write_mem(HERE / "sort32_reverse_text.mem", sort32_reverse)
write_data(HERE / "sort32_reverse_data.mem", list(range(32, 0, -1)))
write_asm(
    "sort32_reverse",
    """# 32-element reverse bubble sort; END_PC = 0x40.
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
jal  x0,finished""",
)

print("F3_PROGRAMS_BUILT round1=3 round2=4")

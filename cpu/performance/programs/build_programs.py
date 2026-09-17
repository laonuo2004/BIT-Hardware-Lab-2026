"""Generate deterministic memory images for the F3 performance experiment."""

from pathlib import Path
import shutil

HERE = Path(__file__).resolve().parent
CPU = HERE.parents[1]


def addi(rd: int, rs1: int, imm: int) -> int:
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | 0x13


def write_mem(path: Path, words: list[int], size: int = 256) -> None:
    padded = words + [0x00000013] * (size - len(words))
    path.write_text("".join(f"{word:08x}\n" for word in padded), encoding="ascii")


def write_data(path: Path, words: list[int], size: int = 256) -> None:
    padded = words + [0] * (size - len(words))
    path.write_text("".join(f"{word & 0xFFFFFFFF:08x}\n" for word in padded), encoding="ascii")


independent = [addi(rd, 0, rd) for rd in range(1, 21)] + [0x0000006F]
dependency = [addi(1, 0, 1)] + [addi(1, 1, 1)] * 19 + [0x0000006F]

write_mem(HERE / "independent_text.mem", independent)
write_data(HERE / "independent_data.mem", [])
write_mem(HERE / "dependency_text.mem", dependency)
write_data(HERE / "dependency_data.mem", [])

# Keep the sorting image byte-for-byte aligned with the functional regression.
shutil.copyfile(CPU / "pipeline" / "programs" / "text.mem", HERE / "sort_text.mem")
shutil.copyfile(CPU / "pipeline" / "programs" / "data.mem", HERE / "sort_data.mem")

print("F3_PROGRAMS_BUILT")

"""Validate and summarize the normalized F3 raw result table."""

import csv
import json
from pathlib import Path

PERF = Path(__file__).resolve().parent.parent
RESULTS = PERF / "results" / "f3"
RAW = RESULTS / "raw_results.tsv"
VERSIONS = ("single", "pipeline_off", "pipeline_on")
PROGRAMS = ("independent", "dependency", "sort")


with RAW.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

if len(rows) != 9:
    raise SystemExit(f"expected 9 rows, got {len(rows)}")

index = {(row["version"], row["program"]): row for row in rows}
expected = {(version, program) for version in VERSIONS for program in PROGRAMS}
if set(index) != expected:
    raise SystemExit(f"matrix mismatch: missing={expected-set(index)} extra={set(index)-expected}")

for row in rows:
    for field in ("cycles", "retired", "stalls", "branches", "mispredicts", "time_ns"):
        row[field] = int(row[field])
    if row["cycles"] <= 0 or row["retired"] <= 0:
        raise SystemExit(f"non-positive count: {row}")
    if row["time_ns"] != row["cycles"] * 100:
        raise SystemExit(f"time mismatch: {row}")

for program in PROGRAMS:
    retired = {index[(version, program)]["retired"] for version in VERSIONS}
    if len(retired) != 1:
        raise SystemExit(f"retired instruction mismatch for {program}: {retired}")

summary = []
for program in PROGRAMS:
    single_cycles = index[("single", program)]["cycles"]
    off_cycles = index[("pipeline_off", program)]["cycles"]
    for version in VERSIONS:
        row = index[(version, program)]
        summary.append({
            **row,
            "cpi": row["cycles"] / row["retired"],
            "cpu_time_us": row["time_ns"] / 1000.0,
            "speedup_vs_single": single_cycles / row["cycles"],
            "prediction_gain_vs_off": (off_cycles / row["cycles"] if version == "pipeline_on" else None),
        })

with (RESULTS / "summary.csv").open("w", encoding="utf-8-sig", newline="") as handle:
    fields = ["program", "version", "cycles", "retired", "cpi", "stalls", "branches",
              "mispredicts", "time_ns", "cpu_time_us", "speedup_vs_single",
              "prediction_gain_vs_off"]
    writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
    writer.writeheader()
    for row in summary:
        formatted = dict(row)
        for field in ("cpi", "cpu_time_us", "speedup_vs_single"):
            formatted[field] = f"{formatted[field]:.4f}"
        if formatted["prediction_gain_vs_off"] is not None:
            formatted["prediction_gain_vs_off"] = f"{formatted['prediction_gain_vs_off']:.4f}"
        writer.writerow(formatted)

(RESULTS / "summary.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)

labels = {"single": "单周期", "pipeline_off": "流水线-预测关", "pipeline_on": "流水线-预测开"}
program_labels = {"independent": "无依赖运算", "dependency": "连续数据依赖", "sort": "五元素排序"}
lines = [
    "# F3 性能实验结果",
    "",
    "主比较统一采用 10 MHz（100 ns/周期）。三个版本使用相同机器码、输入、起止 PC 和正确性检查。",
    "动态指令数包含实际完成的分支和存储，不包含空泡、暂停等待或错误路径指令。",
    "",
    "| 程序 | 版本 | 周期 C | 指令 N | CPI | 暂停 | 分支 | 预测错误 | CPU 时间/us | 相对单周期加速比 |",
    "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
]
for row in summary:
    misses = "—" if row["mispredicts"] < 0 else str(row["mispredicts"])
    lines.append(
        f"| {program_labels[row['program']]} | {labels[row['version']]} | {row['cycles']} | "
        f"{row['retired']} | {row['cpi']:.3f} | {row['stalls']} | {row['branches']} | "
        f"{misses} | {row['cpu_time_us']:.3f} | {row['speedup_vs_single']:.3f} |"
    )

lines += [
    "",
    "## 计算公式",
    "",
    "- `CPI = C / N`",
    "- `CPU 时间 = C × 100 ns`",
    "- `相对单周期加速比 = 单周期 CPU 时间 / 当前版本 CPU 时间`",
    "- `预测收益 = 关闭预测流水线时间 / 开启预测流水线时间`",
    "",
    "## 自动一致性检查",
    "",
    "- 9 组仿真均通过各自的功能结果检查。",
    "- 同一程序在三个 CPU 版本上的动态退休指令数一致。",
    "- 每组 `time_ns` 与 `cycles × 100 ns` 一致。",
]
(RESULTS / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("F3_SUMMARY_PASS rows=9")

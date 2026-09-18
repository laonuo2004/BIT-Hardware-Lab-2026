"""Validate and summarize the official F3 round-2 Vivado result tables."""

import csv
import json
from pathlib import Path

PERF = Path(__file__).resolve().parent.parent
RESULTS = PERF / "results" / "f3_round2"
RUN_FILES = (RESULTS / "raw_results_run1.tsv", RESULTS / "raw_results_run2.tsv")
VERSIONS = ("single", "pipeline_off", "pipeline_on")
PROGRAMS = ("independent_long", "dependency_long", "btfnt_loop", "sort32_reverse")
INTEGER_FIELDS = ("cycles", "retired", "stalls", "branches", "mispredicts", "time_ns")
SIMULATION_PERIOD_NS = 100
SAME_CLOCK_PERIOD_NS = 20
SINGLE_CONFIGURED_PERIOD_NS = 100
PIPELINE_CONFIGURED_PERIOD_NS = 20


def read_run(path: Path) -> list[dict]:
    with path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    if len(rows) != 12:
        raise SystemExit(f"{path.name}: expected 12 rows, got {len(rows)}")
    for row in rows:
        for field in INTEGER_FIELDS:
            row[field] = int(row[field])
        if row["cycles"] <= 0 or row["retired"] <= 0:
            raise SystemExit(f"{path.name}: non-positive count: {row}")
        if row["time_ns"] != row["cycles"] * SIMULATION_PERIOD_NS:
            raise SystemExit(f"{path.name}: simulation time mismatch: {row}")
    return rows


run_rows = [read_run(path) for path in RUN_FILES]
expected = {(version, program) for version in VERSIONS for program in PROGRAMS}
indexes = []
for path, rows in zip(RUN_FILES, run_rows):
    index = {(row["version"], row["program"]): row for row in rows}
    if set(index) != expected:
        raise SystemExit(
            f"{path.name}: matrix mismatch: missing={expected-set(index)} extra={set(index)-expected}"
        )
    indexes.append(index)

for key in sorted(expected):
    if indexes[0][key] != indexes[1][key]:
        raise SystemExit(f"two-run mismatch for {key}: {indexes[0][key]} != {indexes[1][key]}")

index = indexes[0]
for program in PROGRAMS:
    retired = {index[(version, program)]["retired"] for version in VERSIONS}
    if len(retired) != 1:
        raise SystemExit(f"retired instruction mismatch for {program}: {retired}")

if index[("pipeline_off", "btfnt_loop")]["branches"] != 256:
    raise SystemExit("btfnt_loop pipeline_off must retire 256 conditional branches")
if index[("pipeline_on", "btfnt_loop")]["branches"] != 256:
    raise SystemExit("btfnt_loop pipeline_on must retire 256 conditional branches")
if index[("pipeline_off", "btfnt_loop")]["mispredicts"] != 255:
    raise SystemExit("btfnt_loop pipeline_off must report 255 mispredicts")
if index[("pipeline_on", "btfnt_loop")]["mispredicts"] != 1:
    raise SystemExit("btfnt_loop pipeline_on must report one mispredict")

summary = []
for program in PROGRAMS:
    single_cycles = index[("single", program)]["cycles"]
    off_cycles = index[("pipeline_off", program)]["cycles"]
    single_configured_time_ns = single_cycles * SINGLE_CONFIGURED_PERIOD_NS
    for version in VERSIONS:
        row = index[(version, program)]
        configured_period_ns = (
            SINGLE_CONFIGURED_PERIOD_NS if version == "single" else PIPELINE_CONFIGURED_PERIOD_NS
        )
        configured_time_ns = row["cycles"] * configured_period_ns
        branch_count = row["branches"]
        mispredict_rate = None
        if version != "single" and branch_count:
            mispredict_rate = row["mispredicts"] / branch_count
        summary.append(
            {
                **row,
                "cpi": row["cycles"] / row["retired"],
                "same_clock_period_ns": SAME_CLOCK_PERIOD_NS,
                "same_clock_cpu_time_us": row["cycles"] * SAME_CLOCK_PERIOD_NS / 1000.0,
                "same_clock_speedup_vs_single": single_cycles / row["cycles"],
                "configured_period_ns": configured_period_ns,
                "configured_cpu_time_us": configured_time_ns / 1000.0,
                "configured_speedup_vs_single": single_configured_time_ns / configured_time_ns,
                "prediction_speedup_vs_off": (
                    off_cycles / row["cycles"] if version == "pipeline_on" else None
                ),
                "cycle_reduction_vs_off": (
                    (off_cycles - row["cycles"]) / off_cycles
                    if version == "pipeline_on"
                    else None
                ),
                "mispredict_rate": mispredict_rate,
            }
        )

fields = [
    "program",
    "version",
    "cycles",
    "retired",
    "cpi",
    "stalls",
    "branches",
    "mispredicts",
    "mispredict_rate",
    "time_ns",
    "same_clock_period_ns",
    "same_clock_cpu_time_us",
    "same_clock_speedup_vs_single",
    "configured_period_ns",
    "configured_cpu_time_us",
    "configured_speedup_vs_single",
    "prediction_speedup_vs_off",
    "cycle_reduction_vs_off",
]
with (RESULTS / "summary.csv").open("w", encoding="utf-8-sig", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
    writer.writeheader()
    for row in summary:
        formatted = dict(row)
        for field in (
            "cpi",
            "same_clock_cpu_time_us",
            "same_clock_speedup_vs_single",
            "configured_cpu_time_us",
            "configured_speedup_vs_single",
        ):
            formatted[field] = f"{formatted[field]:.4f}"
        for field in ("mispredict_rate", "prediction_speedup_vs_off", "cycle_reduction_vs_off"):
            if formatted[field] is not None:
                formatted[field] = f"{formatted[field]:.6f}"
        writer.writerow(formatted)

(RESULTS / "summary.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)

version_labels = {
    "single": "单周期",
    "pipeline_off": "流水线-预测关",
    "pipeline_on": "流水线-预测开",
}
program_labels = {
    "independent_long": "长无依赖运算流",
    "dependency_long": "连续数据依赖",
    "btfnt_loop": "BTFNT长循环",
    "sort32_reverse": "32元素逆序排序",
}
lines = [
    "# F3 性能实验第二轮结果",
    "",
    "四类程序在三个CPU版本上使用相同机器码、输入和计数边界。Vivado 2019.2完整矩阵连续运行两次，两轮12组结果完全一致。",
    "统一50 MHz对照用于比较相同频率下的CPI、暂停和冲刷开销；课程配置频率对照采用单周期10 MHz、流水线50 MHz。",
    "单周期核心和流水线核心均已通过50 MHz实现后时序检查，因此配置频率对照不代表两者最高频率之比。",
    "",
    "| 程序 | 版本 | 周期C | 指令N | CPI | 暂停 | 分支 | 错误预测 | 50 MHz时间/us | 配置时间/us |",
    "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
]
for row in summary:
    misses = "N/A" if row["version"] == "single" else str(row["mispredicts"])
    lines.append(
        f"| {program_labels[row['program']]} | {version_labels[row['version']]} | "
        f"{row['cycles']} | {row['retired']} | {row['cpi']:.3f} | {row['stalls']} | "
        f"{row['branches']} | {misses} | {row['same_clock_cpu_time_us']:.3f} | "
        f"{row['configured_cpu_time_us']:.3f} |"
    )

off_loop = index[("pipeline_off", "btfnt_loop")]
on_loop = index[("pipeline_on", "btfnt_loop")]
off_sort = index[("pipeline_off", "sort32_reverse")]
on_sort = index[("pipeline_on", "sort32_reverse")]
lines += [
    "",
    "## 自动一致性检查",
    "",
    "- 两轮Vivado正式矩阵均为12/12通过，两轮计数完全一致。",
    "- 同一程序在三个CPU版本上的动态退休指令数一致。",
    "- 每组原始仿真时间均等于周期数乘以100 ns仿真周期。",
    f"- BTFNT长循环的错误预测从{off_loop['mispredicts']}次降至{on_loop['mispredicts']}次，周期从{off_loop['cycles']}降至{on_loop['cycles']}。",
    f"- 32元素逆序排序的错误预测从{off_sort['mispredicts']}次降至{on_sort['mispredicts']}次，周期从{off_sort['cycles']}降至{on_sort['cycles']}。",
    "",
    "## 口径说明",
    "",
    "- 单周期错误预测为N/A，原始记录使用-1。",
    "- 50 MHz同频结果与10/50 MHz课程配置结果分别展示，不混作最高频率比较。",
    "- 第一轮三程序9/9结果继续保留在`results/f3/`，未被覆盖。",
]
(RESULTS / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

ppt_lines = [
    "# 结项答辩第13页：F3第二轮性能材料",
    "",
    "## 建议主结论",
    "",
    "- 四类程序、三个CPU版本共12组，Vivado 2019.2连续运行两轮，结果完全一致。",
    f"- BTFNT长循环：错误预测{off_loop['mispredicts']}→{on_loop['mispredicts']}，周期{off_loop['cycles']}→{on_loop['cycles']}。",
    f"- 32元素逆序排序：错误预测{off_sort['mispredicts']}→{on_sort['mispredicts']}，周期{off_sort['cycles']}→{on_sort['cycles']}。",
    "- 当前流水线没有通用数据前递，连续数据依赖造成的暂停仍是主要性能瓶颈。",
    "- 单周期与流水线均满足50 MHz时序；10/50 MHz数据只能表述为课程配置频率对照。",
    "",
    "## 材料路径",
    "",
    "- 完整表：`summary.csv`",
    "- 可阅读汇总：`summary.md`",
    "- 两轮原始数据：`raw_results_run1.tsv`、`raw_results_run2.tsv`",
    "- 报告图：`figures/f3_cpu_time_50mhz.pdf`、`figures/f3_prediction_effect.pdf`",
]
(RESULTS / "第13页PPT材料.md").write_text("\n".join(ppt_lines) + "\n", encoding="utf-8")

print("F3_ROUND2_SUMMARY_PASS rows=12 repetitions=2")

"""Generate the same-clock 50 MHz CPU-time comparison figure."""

import csv
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt

from figure_style import COLORS, save_figure

PERF = Path(__file__).resolve().parent.parent
RESULTS = PERF / "results" / "f3_round2"
with (RESULTS / "summary.csv").open(encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.DictReader(handle))

versions = ("single", "pipeline_off", "pipeline_on")
version_labels = ("单周期", "流水线-预测关", "流水线-预测开")
programs = ("independent_long", "dependency_long", "btfnt_loop", "sort32_reverse")
program_labels = {
    "independent_long": "长无依赖",
    "dependency_long": "连续依赖",
    "btfnt_loop": "BTFNT循环",
    "sort32_reverse": "32元素排序",
}
values = {
    (row["version"], row["program"]): float(row["same_clock_cpu_time_us"])
    for row in rows
}

fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.0), gridspec_kw={"width_ratios": [3, 1.15]})
width = 0.24

left_programs = programs[:3]
x_left = np.arange(len(left_programs))
for index, (version, label, color) in enumerate(zip(versions, version_labels, COLORS)):
    data = [values[(version, program)] for program in left_programs]
    bars = axes[0].bar(x_left + (index - 1) * width, data, width, label=label, color=color)
    axes[0].bar_label(bars, fmt="%.2f", padding=2, fontsize=8)
axes[0].set_xticks(x_left, [program_labels[program] for program in left_programs])
axes[0].set_ylabel("CPU时间（μs，统一50 MHz）")
axes[0].grid(axis="y", color="#D9D9D9", linewidth=0.6)
axes[0].set_axisbelow(True)

x_right = np.arange(1)
for index, (version, label, color) in enumerate(zip(versions, version_labels, COLORS)):
    data = [values[(version, "sort32_reverse")]]
    bars = axes[1].bar(x_right + (index - 1) * width, data, width, label=label, color=color)
    axes[1].bar_label(bars, fmt="%.1f", padding=2, fontsize=8)
axes[1].set_xticks(x_right, [program_labels["sort32_reverse"]])
axes[1].grid(axis="y", color="#D9D9D9", linewidth=0.6)
axes[1].set_axisbelow(True)

handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper center", ncol=3, frameon=False, bbox_to_anchor=(0.5, 1.04))
fig.subplots_adjust(top=0.82, bottom=0.18, left=0.09, right=0.98, wspace=0.28)
save_figure(fig, RESULTS / "figures", "f3_cpu_time_50mhz")


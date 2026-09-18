"""Generate the BTFNT cycle and misprediction comparison figure."""

import csv
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt

from figure_style import COLORS, save_figure

PERF = Path(__file__).resolve().parent.parent
RESULTS = PERF / "results" / "f3_round2"
with (RESULTS / "summary.csv").open(encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.DictReader(handle))

versions = ("pipeline_off", "pipeline_on")
version_labels = ("预测关闭", "预测开启")
programs = ("btfnt_loop", "sort32_reverse")
program_labels = ("BTFNT长循环", "32元素逆序排序")
index = {(row["version"], row["program"]): row for row in rows}
x = np.arange(len(programs))
width = 0.32

fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.0))
for version_index, (version, label, color) in enumerate(zip(versions, version_labels, COLORS[1:])):
    positions = x + (version_index - 0.5) * width
    cycles = [int(index[(version, program)]["cycles"]) for program in programs]
    misses = [int(index[(version, program)]["mispredicts"]) for program in programs]
    cycle_bars = axes[0].bar(positions, cycles, width, label=label, color=color)
    miss_bars = axes[1].bar(positions, misses, width, label=label, color=color)
    axes[0].bar_label(cycle_bars, fmt="%d", padding=2, fontsize=8)
    axes[1].bar_label(miss_bars, fmt="%d", padding=2, fontsize=8)

axes[0].set_xticks(x, program_labels)
axes[0].set_ylabel("执行周期")
axes[1].set_xticks(x, program_labels)
axes[1].set_ylabel("错误预测次数")
for axis in axes:
    axis.grid(axis="y", color="#D9D9D9", linewidth=0.6)
    axis.set_axisbelow(True)

handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper center", ncol=2, frameon=False, bbox_to_anchor=(0.5, 1.04))
fig.subplots_adjust(top=0.82, bottom=0.2, left=0.09, right=0.98, wspace=0.3)
save_figure(fig, RESULTS / "figures", "f3_prediction_effect")


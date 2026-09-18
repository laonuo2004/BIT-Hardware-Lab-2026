# F3 性能实验

比较三个版本：单周期 CPU、关闭 BTFNT 的流水线、开启 BTFNT 的流水线。

第一轮三类程序、9 组正式结果保留在 `results/f3/`。第二轮按[执行方案](F3_TEST_PLAN.md)扩展为长无依赖运算流、连续数据依赖、BTFNT 长循环和 32 元素逆序冒泡排序；四类程序、三个 CPU 版本的 12 组矩阵在 Vivado 2019.2 中连续运行两次，**24/24 次执行通过且两轮计数完全一致**。第二轮结果位于 `results/f3_round2/`，没有覆盖第一轮归档。

周期数、动态指令数和 CPI 来自 Vivado 2019.2 仿真。第二轮同时提供统一 50 MHz 对照和课程配置频率对照，后者采用单周期10 MHz、流水线50 MHz。单周期核心和流水线核心均满足50 MHz实现后时序，配置频率不能解释为最高频率之比。

## 计数边界

- 起点：复位释放后，PC=0 的第一条测试指令开始执行；流水线从该指令首次取指计时。
- 终点：指定结束标记指令完成；流水线以 `retire_valid && retire_pc==END_PC` 为准。
- 动态指令数包含实际完成的分支、存储和写 x0 指令，不包含空泡、暂停等待及错误路径指令。
- 各程序的结束地址记录在 `programs/cases.tsv`；第二轮四项依次为 `0x3C0`、`0x200`、`0x10` 和 `0x40`。
- 单周期没有预测器，预测错误记为不适用，而不是零。
- 单周期核心在50 MHz约束下也通过布局布线，`WNS=+6.080 ns`。因此10/50 MHz是配置频率对比，不能表述为两种CPU各自最高频率的公平对比。
- 50 MHz流水线bit流已经生成；由于本次JTAG未识别到开发板，只能表述为“布局布线时序通过”，暂不能表述为“50 MHz板上功能已验证”。
- 完整频率证据见 [frequency_check](results/frequency_check/README.md)。

## 复跑

先生成程序镜像：

```powershell
python cpu/performance/programs/build_programs.py
```

使用 Vivado 2019.2 先运行冒烟测试，再执行两轮正式矩阵：

```powershell
vivado -mode batch -source cpu/performance/scripts/run_f3_round2_smoke.tcl
vivado -mode batch -source cpu/performance/scripts/run_f3_vivado.tcl
python cpu/performance/scripts/summarize_results.py
python cpu/performance/scripts/generate_f3_time_figure.py
python cpu/performance/scripts/generate_f3_prediction_figure.py
```

第二轮正式结果位于 `results/f3_round2`。`raw/run1` 和 `raw/run2` 保存两轮完整日志，`summary.csv`、`summary.json` 和 `summary.md` 保存核对后的结果，两张报告图位于 `figures/`。

第二轮正式运行结果为每轮 **12/12 通过**，两轮合计 **24/24**。完整数字见[第二轮汇总表](results/f3_round2/summary.md)，交给第13页和实验报告制作者的精简口径见[第二轮第13页材料](results/f3_round2/第13页PPT材料.md)。第一轮[9/9汇总](results/f3/summary.md)继续作为基线保留。

现有单周期 `cpu_sort_tb.v` 的固定 `#1200` 只用于功能检查，不参与 F3 性能计算。

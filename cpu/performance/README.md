# F3 性能实验

比较三个版本：单周期 CPU、关闭 BTFNT 的流水线、开启 BTFNT 的流水线。运行无依赖运算、连续数据依赖和五元素排序三类程序。

周期数、动态指令数和 CPI 来自 Vivado 2019.2 仿真。时间主视图采用课程展示的配置频率：单周期基线为10 MHz（100 ns），流水线为50 MHz（20 ns）。流水线完整整机已在50 MHz约束下完成布局布线，`WNS=+6.527 ns`；统一10 MHz的同频时间仍保留在结果CSV中，用于区分时钟频率收益与暂停开销。

## 计数边界

- 起点：复位释放后，PC=0 的第一条测试指令开始执行；流水线从该指令首次取指计时。
- 终点：指定结束标记指令完成；流水线以 `retire_valid && retire_pc==END_PC` 为准。
- 动态指令数包含实际完成的分支、存储和写 x0 指令，不包含空泡、暂停等待及错误路径指令。
- 排序结束标记为 `0x40`；两个人工程序结束标记为 `0x50`。
- 单周期没有预测器，预测错误记为不适用，而不是零。
- 单周期核心在50 MHz约束下也通过布局布线，`WNS=+6.080 ns`。因此10/50 MHz是配置频率对比，不能表述为两种CPU各自最高频率的公平对比。
- 50 MHz流水线bit流已经生成；由于本次JTAG未识别到开发板，只能表述为“布局布线时序通过”，暂不能表述为“50 MHz板上功能已验证”。
- 完整频率证据见 [frequency_check](results/frequency_check/README.md)。

## 复跑

先生成程序镜像：

```powershell
python cpu/performance/programs/build_programs.py
```

使用 Vivado 2019.2 执行正式 9 组矩阵：

```powershell
vivado -mode batch -source cpu/performance/scripts/run_f3_vivado.tcl
python cpu/performance/scripts/summarize_results.py
```

正式结果位于 `results/f3`。`summary.csv` 供制图，`summary.md` 供报告和答辩核对，`raw` 保存每组 Vivado 原始记录。

本次正式运行结果为 **9/9 通过**。完整数字见 [汇总表](results/f3/summary.md)，交给第 13 页制作者的精简口径见 [第13页PPT材料](results/f3/第13页PPT材料.md)。

现有单周期 `cpu_sort_tb.v` 的固定 `#1200` 只用于功能检查，不参与 F3 性能计算。

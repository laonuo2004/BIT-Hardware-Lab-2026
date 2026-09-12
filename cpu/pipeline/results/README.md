# M2 自检结果

环境：Vivado 2019.2，目标器件 `xc7a35tcsg324-1`。

- 完整排序：`PIPE_SORT_PASS`，结果 `1,2,3,4,5`，176 周期，73 条有效完成指令。
- 定向相关性测试：`HAZARD_PASS writes=3`。
- 覆盖：ALU 依赖、load-use、store 数据依赖、分支依赖、分支冲刷、JAL 冲刷。
- 错误路径内存写入被抑制；三条预期 store 各执行一次。
- 综合：902 Slice LUT（4.34%），1451 Slice Registers（3.49%），0 BRAM，0 DSP。
- 独立 CPU 尚未施加板级时钟约束；系统顶层接入 10 MHz 时钟后再做时序验收。

复跑：在 `cpu/pipeline` 下分别执行 `scripts/run_sort_sim.tcl`、`scripts/run_hazard_sim.tcl` 和 `scripts/run_synth.tcl`。

后续 M3 的实际结果见 [M3 功能验证与交接](m3/README.md)，本页保留刘兆钰 M2 阶段原记录。

结项阶段新增的复杂相关、RAM 边界和四类排序输入结果见 [F1 CPU 扩展回归](f1/README.md)。

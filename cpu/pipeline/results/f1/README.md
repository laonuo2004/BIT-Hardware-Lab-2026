# F1 CPU 扩展回归

2026-09-12 使用 Vivado 2019.2 执行 `scripts/run_m3_sim.tcl`，原有 19 项与新增 2 项测试合计 **21/21 通过**。

## 新增覆盖

`f1_extended_tb`：

- 两个源寄存器同时相关；
- 连续写同一个目的寄存器；
- 存储地址、存储数据和加载结果相关；
- 分支操作数相关及错误路径存储抑制；
- RAM 最后一个合法对齐字地址 `0x000003FC` 的读写。

`sort_variants_tb` 使用与原流水线排序测试相同的机器码，复位后分别运行：

| 输入 | 结果 |
| --- | --- |
| `1,2,3,4,5` | `1,2,3,4,5` |
| `5,4,3,2,1` | `1,2,3,4,5` |
| `3,1,3,2,1` | `1,1,2,3,3` |
| `-1,3,-5,2,0` | `-5,-1,0,2,3` |

故障发生时旧指令完成、年轻指令取消，以及未对齐和未映射地址，继续由原有 `fault_tb`、`m3_integration_tb` 和 `address_guard_tb` 覆盖。

## 复跑

在仓库根目录的 Vivado 2019.2 Tcl Console 中执行：

```tcl
source {仓库绝对路径/cpu/pipeline/scripts/run_m3_sim.tcl}
```

通过标记：

```text
Vivado regression: 21/21 passed.
```

新增用例的关键输出保存在 [evidence](evidence/) 中。完整临时日志位于 `cpu/pipeline/build/vivado_regression`，该目录不提交。

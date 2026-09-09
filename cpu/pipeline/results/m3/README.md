# M3 功能验证与交接

2026-09-09，功能与测试版本 `f207e908671fd47c263c6c1afecf03faf43dec54`。在干净工作区运行 Icarus Verilog 13.0，**19/19 项按预期通过**，包括一项预期触发非法指令错误的测试。[汇总](summary.json)记录实际版本及各项状态，[源文件 SHA-256](source_sha256.json)用于核对后续文档提交中的代码是否一致。

已完成 `ori/andi` 修复、三个 M3 功能的 CPU 内部接入、组合回归及真实 system_env 状态读取。**Vivado 仿真、综合、板级时序和上板尚未验证。** 本机没有可调用的 Vivado/xsim，所提供 Vivado 脚本只完成了静态检查，不能作为其已运行证据。UART 排序与接收 r 的闭环仍需 M6 完成。

## 复跑

仓库根目录执行：

```sh
python3 cpu/pipeline/scripts/run_tests.py --waves
```

需要 Python 3、iverilog 和 vvp。默认输出到 `cpu/pipeline/build/regression`；失败、超时、缺少通过标记或非预期警告均返回失败。`cases.tsv` 为两种仿真环境共享的测试清单。

Vivado 2019.2 环境在 Tcl Console 执行（仓库路径含空格，请用大括号包住实际绝对路径）：

```tcl
source {仓库绝对路径/cpu/pipeline/scripts/run_m3_sim.tcl}
```

该入口依次调用 xvlog、xelab、xsim，不依赖 Python；需使用 Vivado 的命令环境，保证三个程序可被找到。结果写入 `cpu/pipeline/build/vivado_regression`。命令行选项参照 [AMD UG900](https://docs.amd.com/r/2020.2-English/ug900-vivado-logic-simulation/xelab-xvhdl-and-xvlog-xsim-Command-Options)，2019.2 的实际运行仍须验证。

单独综合可运行 `cpu/pipeline/scripts/run_synth.tcl`。目标器件 `xc7a35tcsg324-1`，CPU 时钟约束为 100 ns。结果在 `cpu/pipeline/build/synthesis`。CPU 独立综合与板级实现、布线后时序是不同阶段。

## 关键结果

| 项目 | 实测 |
| --- | --- |
| 立即数反例 | ori=31、andi=2，通过 |
| ISA 回归 | 16 指令执行结果、21 次预期退休 PC 顺序、x0、链接寄存器，通过 |
| 故障 | 不对齐/未映射、旧 WB 保留、年轻指令取消、20 拍停机稳定与复位，通过 |
| 溢出 | add/sub/addi、x0 目的、错误路径与地址加法排除，通过 |
| 状态读取 | 溢出 WB 与下一条状态 load MEM 同周期，读到 1；只读写入无效，通过 |
| 三次回跳，预测开 | 分支 3，错误 1，28 周期 |
| 三次回跳，预测关 | 分支 3，错误 2，28 周期 |
| 规范后排序，预测开 | 1,2,3,4,5；223 周期、94 次退休 |
| 规范后排序，预测关 | 1,2,3,4,5；226 周期、94 次退休 |

排序统计从解除复位后的第一个有效时钟沿，到 PC=0x40 结束循环的首次退休，包含启动与结束标记。之前的 176/73 以数组提前达到有序状态作为结束条件，两者不能直接比较。这些数据是功能测试记录，正式性能比较仍按 F3 统一区间重新测量。

## 日志与波形

[evidence](evidence/) 中保存全部 19 项日志，包括合法成功、预期非法失败及预测开关。原始波形可用 GTKWave 等 VCD 查看器打开。

| 波形 | 重点观察 |
| --- | --- |
| [故障停机](waves/09_fault_tb.vcd) | fault_valid/PC/addr/reason；故障时 dv=0，之后 rv=0；复位恢复 |
| [三功能组合](waves/00_m3_integration_tb.vcd) | MEM 故障与更老 WB 溢出并存，年轻分支不增加计数 |
| [预测开启](waves/04_prediction_tb.vcd) / [预测关闭](waves/05_prediction_tb.vcd) | 开头三次回跳；branch_count、mispredict_count、stall、redirect |
| [紧邻状态读取](waves/06_status_mmio_tb.vcd) | rpc=0x24，MEM PC=0x28，fixture_rdata=1，overflow_flag=1 |

这些波形来自本次仿真运行，没有手工修改信号或补画结果。

## 给系统连接同学

使用 `cpu/pipeline/src` 中全部四个 Verilog 文件，CPU 顶层是 `PipelineCPU`。端口说明见 [CPU README](../../../README.md)。溢出输出连接到 B 组环境，其他新增输出用于仿真或调试，可在板级具名例化时暂不连接。

仿真 ROM 只能使用已支持的 16 指令；硬件测试不使用 ecall。程序要自行初始化 B 组 RAM，ROM 其余部分使用 NOP。故障后须复位才能重新运行。

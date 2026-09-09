# 冯丽嘉 提交文件

B 组（外设与系统运行环境）——我负责的部分：应用汇编、UART 测试、系统测试、结果整理。这里只放我本人写的东西，UART RTL / 板卡文件在 [黄奕晨 提交文件](../黄奕晨%20提交文件/) 里，我不改它们。

## 目录

```
冯丽嘉 提交文件/
├── programs/
│   ├── sort_uart.asm     # 应用汇编源码（排序 + UART 输出 + 收 'r' 重跑）
│   └── sort_uart.mem     # 机器码（由 rv32_tool.py 生成，供 system_env 的 ROM_FILE 加载）
├── sim/
│   └── uart_mmio_tb.v    # 我自己的 UART 测试台（M4，14 个场景，iverilog+Vivado 全过）
├── tools/
│   └── rv32_tool.py      # 只支持 16 条指令的汇编器 + 顺序仿真器 + 端到端验证
└── README.md
```

另外在 `cpu/system/` 下（与刘兆钰的系统集成测试同目录）：

- `cpu/system/programs/sort_uart.mem` — 应用 ROM 副本
- `cpu/system/sim/sort_uart_tb.v` — 排序应用系统集成测试（CPU+UART 闭环，含收 `r` 重跑）

## 应用汇编 sort_uart.asm 做了什么

复位后（程序入口 PC=0）：

1. 向数据 RAM `0x00000000` 起写入 `4, 2, 5, 1, 3`
2. 冒泡排序（4 轮 × 4 次相邻比较，`lw/sw` + `bge`）
3. 轮询 UART STATUS `0x40000004` 的 bit0（忙），逐字节发送 `SORT: 1 2 3 4 5\r\n`
4. 轮询 STATUS bit1（RX 有效），读到 `r`(0x72) 就跳回 init 重新运行，其它字符忽略

**只用 16 条指令**（`add sub xor addi ori lui lw sw beq bne blt bge jal and or andi`），无 `ecall`/`jalr`/移位。

## 验证方法与结果

**① Python 逻辑验证**（无需任何 EDA 工具）：

```sh
python tools/rv32_tool.py
```

断言：排序后 RAM = `[1,2,3,4,5]`；输出 = `SORT: 1 2 3 4 5\r\n`；注入 `r` 后重新初始化并再输出一遍。同时（重新）生成 `programs/sort_uart.mem`。

**② iverilog 真实 RTL 验证**（应用跑在真实 PipelineCPU + system_env 上）：

```sh
iverilog -g2012 -o sort_uart_tb.vvp \
  cpu/pipeline/src/*.v "黄奕晨 提交文件/rtl/uart_mmio.v" \
  "黄奕晨 提交文件/rtl/system_env.v" \
  cpu/system/src/cpu_system.v cpu/system/sim/sort_uart_tb.v
# 在 cpu/system/programs/ 目录下运行 vvp（$readmemh 相对该目录）
vvp sort_uart_tb.vvp
```

实测结果（2026-09-09）：
`SORT_UART_SYSTEM_PASS text=SORT_1_2_3_4_5_CRLF rounds=2` —— 复位后输出一遍，收 `r` 后再输出一遍，无故障/溢出/发送错误。
**iverilog 11.0 与 Vivado 2019.2 xsim 双环境通过**（Vivado 入口：`cpu/system/scripts/run_sort_uart_sim.tcl`）。

**③ 我的 UART 测试台**（M4，14 个场景全过，iverilog + Vivado 双通过；做过 4 项变异测试，注入的 4 种 UART 缺陷全部被测试台抓住）：

```sh
iverilog -g2012 -o uart_mmio_tb.vvp \
  "黄奕晨 提交文件/rtl/uart_mmio.v" "黄奕晨 提交文件/rtl/system_env.v" \
  冯丽嘉 提交文件/sim/uart_mmio_tb.v
vvp uart_mmio_tb.vvp   # 通过标记 UART_MMIO_TB_PASS all=14
```

Vivado 入口：`冯丽嘉 提交文件/scripts/run_uart_mmio_sim.tcl`（`vivado -mode batch -source` 运行）。

## 怎么接到系统

- `system_env` 例化时传 `ROM_FILE` 指向 `programs/sort_uart.mem`，CPU 顶层接 `system_env`。
- ROM 未用区域已由 `system_env` 默认填 NOP，程序本身是死循环（收 `r` 重跑），不会跑出 ROM。
- 数据 RAM 复位不清零，数组由程序自己写入（符合约定）。

## 还没做的（我的待办）

- [x] 应用汇编 + 机器码（`sort_uart.asm` / `sort_uart.mem`）
- [x] UART 测试台（`sim/uart_mmio_tb.v`，10 个场景全过）
- [x] 系统闭环测试（`cpu/system/sim/sort_uart_tb.v`，两轮输出全过）
- [ ] 结项 F1 扩展回归、F3 性能运行记录、F4 材料
- [ ] 个人：两门在线考试 + 每日日志
- [ ] 上板验证（需要 Vivado / 精工板，见组内安排）

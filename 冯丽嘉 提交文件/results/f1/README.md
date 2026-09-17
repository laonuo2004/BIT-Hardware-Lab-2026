# F1 UART 与系统测试记录（冯丽嘉）

2026-09-17 对 main 最新版本（`774f7cf`，含黄奕晨板级包装与 IP 封装后的 RTL）复跑全部测试。
UART 核心 RTL（`uart_mmio.v`、`system_env.v`）自 9/9 起未改动，板级工程直接复用本组应用 ROM（MD5 一致）。

## 运行环境与命令

- iverilog 11.0（conda-forge）：
  `iverilog -g2012 -o uart_tb.vvp 黄奕晨\ 提交文件/rtl/uart_mmio.v 黄奕晨\ 提交文件/rtl/system_env.v 冯丽嘉\ 提交文件/sim/uart_mmio_tb.v && vvp uart_tb.vvp`
- Vivado 2019.2（batch）：
  `vivado -mode batch -source 冯丽嘉\ 提交文件/scripts/run_uart_mmio_sim.tcl`

## 结果

| 测试 | iverilog 11.0 | Vivado 2019.2 | 日志 |
| --- | --- | --- | --- |
| UART 测试台 15 场景 | 15/15 通过 | 15/15 通过 | [uart_mmio_tb_iverilog.txt](uart_mmio_tb_iverilog.txt) / [uart_mmio_tb_vivado.txt](uart_mmio_tb_vivado.txt) |
| 排序应用系统闭环（4 轮输出、3 次 `r` 命令） | 通过 | 9/10 已通过（同版本 RTL） | [sort_uart_system_iverilog.txt](sort_uart_system_iverilog.txt) |

## 场景与 F1 清单对应关系

| F1 清单项 | 场景 | 说明与次数 |
| --- | --- | --- |
| 连续收发 | S2、S3 | TX 连续 0x55/0x00/0xFF；RX 连续 0x55/0x00/0xFF/`r` |
| 发送中复位 | S12 | TX 帧传一半复位：TX 回高、状态清零、复位后正常发送 |
| 接收中复位 | S15（本次新增） | RX 帧传一半复位：状态清零、残留帧尾不阻塞通信、复位后正常接收 |
| 缓冲未读取时的新字节 | S6 | overrun 置位、保留旧字节、新字节丢弃 |
| 同周期消费旧字节并收到新字节 | S7 | 同沿消费+到达，新字节被保存、无 overrun |
| 发送忙时再次写入 | S4 | 只发第一个字节、tx_error 置位、写 1 清除 |
| 错误帧后的恢复 | S5 + 后续 S6/S7 正常收发 | 错误停止位丢弃、bit3 清除后继续正常收发 |
| 重复命令与反复复位 | S14 | 复位+发送命令循环 3 次，全部正确 |

# CPU 与系统环境连接

`src/cpu_system.v` 将 `PipelineCPU` 与黄奕晨交付的 `system_env` 按统一总线直接连接，不修改 UART 内部实现。输入时钟必须已经是 10 MHz；板上 100 MHz 到 10 MHz 的处理仍由板级包装完成。

最小程序 `programs/send_a.mem` 对 UART TX 地址 `0x40000000` 写入字符 `A`，对应 M6 的第一步。Vivado 2019.2 运行：

```tcl
source {仓库绝对路径/cpu/system/scripts/run_send_a_sim.tcl}
```

通过标记为 `CPU_SYSTEM_SEND_A_PASS data=41`。

第二步使用 `programs/send_string.mem`。程序在每次写 TX 前轮询 STATUS bit0，发送 `UART_OK\r\n`；自动测试还会检查完整字节序列、CPU 故障、溢出和 UART 忙时重复写错误：

```tcl
source {仓库绝对路径/cpu/system/scripts/run_send_string_sim.tcl}
```

通过标记为 `CPU_SYSTEM_STRING_PASS text=UART_OK_CRLF`。后续取得应用组 ROM 后，只需通过 `ROM_FILE` 参数替换程序，再依次验证排序输出和接收 `r` 重启。

应用组ROM现已接入 `programs/sort_uart.mem`。`scripts/run_sort_uart_sim.tcl` 会核对初始输出以及连续三次输入 `r` 后的四轮完整串口文本；通过标记为 `SORT_UART_SYSTEM_PASS text=SORT_1_2_3_4_5_CRLF rounds=4 commands=3`。

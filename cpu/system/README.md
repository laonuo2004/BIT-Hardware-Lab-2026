# CPU 与系统环境连接

`src/cpu_system.v` 将 `PipelineCPU` 与黄奕晨交付的 `system_env` 按统一总线直接连接，不修改 UART 内部实现。输入时钟必须已经是 10 MHz；板上 100 MHz 到 10 MHz 的处理仍由板级包装完成。

当前最小程序 `programs/send_a.mem` 对 UART TX 地址 `0x40000000` 写入字符 `A`，对应 M6 的第一步。Vivado 2019.2 运行：

```tcl
source {仓库绝对路径/cpu/system/scripts/run_send_a_sim.tcl}
```

通过标记为 `CPU_SYSTEM_SEND_A_PASS data=41`。后续取得应用组 ROM 后，只需通过 `ROM_FILE` 参数替换程序，再依次验证固定字符串、排序输出和接收 `r` 重启。

# UART MMIO IP（Vivado 2019.2）

封装对象是已有模块 `uart_mmio`，没有改 RTL。默认 `BIT_CYCLES=87`（10 MHz、115200 8N1）。

- VLNV：`bit.lab:user:uart_mmio:1.0`
- 器件族：Artix-7
- 本机封装目录：`C:/Users/34556/Desktop/bgroup/b_group/ip/uart_mmio`

## 在新工程里使用

1. 打开 Vivado 2019.2，新建工程，器件 `xc7a35tcsg324-1`。
2. Tools → Settings → IP → Repository，添加上面的 `ip` 目录（包含 `uart_mmio` 的上一级）。
3. IP Catalog 中选 UART MMIO，Create IP。参数 `BIT_CYCLES` 保持 87（板上 10 MHz）。
4. 例化该 IP 的端口与原来的 `uart_mmio` 相同：`clk`、`resetn`（低有效）、`valid`、`write`、`addr[3:0]`、`wdata`、`rdata`、`rx`、`tx`。

不要把原测试工程的中文路径写进 IP。接 CPU 时仍例化 `system_env`；`system_env` 内部继续例化 `uart_mmio`。本 IP 用于独立交付和汇编课封装要求。

## 自检（已跑过）

新工程不直接引用 `b_group/rtl/uart_mmio.v`，只使用本目录 `src/uart_mmio.v`，再加上 `system_env.v` 与冯丽嘉的 `uart_mmio_tb.v`。Vivado 2019.2 xsim：

```text
UART_MMIO_TB_PASS all=14
```

本机重建：

```text
F:\xilinx\Vivado\2019.2\bin\vivado.bat -mode batch -source C:/Users/34556/Desktop/bgroup/b_group/package_uart_ip.tcl
```

必须在英文路径下运行。不要把 `uart_ip_pack_build` 推进 GitHub。

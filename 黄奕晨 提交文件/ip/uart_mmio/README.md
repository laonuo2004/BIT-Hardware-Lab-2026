# UART MMIO IP（Vivado 2019.2）

封装对象是已有模块 `uart_mmio`，没有改 RTL。默认 `BIT_CYCLES=87`（10 MHz、115200 8N1）。

- VLNV：`bit.lab:user:uart_mmio:1.0`
- 器件族：Artix-7
- 本目录即为 IP 包（与本 README 同级）

## 在新工程里使用

1. 打开 Vivado 2019.2，新建工程，器件 `xc7a35tcsg324-1`。
2. Tools → Settings → IP → Repository，添加本文件夹的上一级 `ip/`（即与 `clk_wiz_0` 同级的目录）。
3. IP Catalog 中选 UART MMIO，Create IP。参数 `BIT_CYCLES` 保持 87（板上 10 MHz）。
4. 例化该 IP 的端口与原来的 `uart_mmio` 相同：`clk`、`resetn`（低有效）、`valid`、`write`、`addr[3:0]`、`wdata`、`rdata`、`rx`、`tx`。

不要把测试工程的绝对路径写进 IP。接 CPU 时仍例化 `system_env`；`system_env` 内部继续例化 `uart_mmio`。本 IP 用于独立交付和汇编课封装要求。

## 自检（已跑过）

验证时使用本目录 `src/uart_mmio.v`，再加上 `system_env.v` 与冯丽嘉的 `uart_mmio_tb.v`（仓库内用相对路径查找）。Vivado 2019.2 xsim：

```text
UART_MMIO_TB_PASS all=14
```

在「黄奕晨 提交文件」目录下重建：

```text
vivado -mode batch -source package_uart_ip.tcl
```

不要把 `uart_ip_pack_build` 推进 GitHub。

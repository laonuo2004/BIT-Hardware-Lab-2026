# 提交文件说明（黄奕晨）

本文件夹是给组内 GitHub 用的源码副本。整夹都可以上传；**每个人实际只用其中一部分**。下面按人列出：必须拿走哪些文件、不要用哪些、拿去干什么。

约定（四人都要知道，不必每人复制一遍 RTL）：

- 板卡 EES-338，器件 `xc7a35tcsg324-1`，Vivado 2019.2
- 板上时钟 100 MHz；CPU 和 UART 工作时钟 10 MHz
- UART：115200、8N1、无流控；10 MHz 下每位 87 周期
- 接 CPU 时例化 `system_env`，不要只接 `uart_mmio`

---

## 先看这张表（按人领文件）

| 人 | 必须使用的文件 | 可以看、但不要当作业交 | 不用拿 |
| --- | --- | --- | --- |
| **冯丽嘉** | `rtl/uart_mmio.v`、`rtl/system_env.v`、本 README 的地址表 | `sim/env_tb.v`（黄奕晨自检，不是她的测试台） | 全部 `board_*.v`、约束、`ip/`、根目录 Tcl |
| **刘兆钰** | `rtl/system_env.v`、本 README 的总线表和地址表 | `rtl/uart_mmio.v`（了解外设即可，不要改） | `board_*.v`、约束、`ip/`、`sim/env_tb.v`、板上 Tcl |
| **左逸龙** | 本 README 的地址表（溢出在 `0x4000000C`） | `rtl/system_env.v`（看溢出如何接到外设） | UART 板上工程、冒烟、Clocking Wizard |
| **黄奕晨** | 本文件夹全部（本人备份/上板） | — | 不要把 Vivado 的 `.runs` 再塞进 GitHub |

GitHub 上建议保留整个「提交文件」，避免有人漏下 `system_env`。组员克隆后按上表只用自己那几份。

---

## 冯丽嘉：UART 测试、模拟总线、排序应用

职责：写 UART 测试、模拟 CPU 发总线请求、写排序汇编并在系统测试里跑。不要改 UART 内部。

**必须复制到你自己的工程：**

1. `rtl/uart_mmio.v` — UART 与 TX/STATUS/RX 寄存器
2. `rtl/system_env.v` — RAM、译码、UART、溢出映射；用模拟总线测时例化它
3. 本文「地址」一节 — 读写这些地址，不要另编一套

**可以打开看一眼：**

- `sim/env_tb.v` — 黄奕晨已经自检通过的激励。只能当「总线怎么打」的例子。你要自己写测试台和应用，不要把这份改改当交付。

**不要用：**

- `rtl/board_smoke.v`、`rtl/board_clk.v`、`rtl/board_uart_ok.v`
- `constraints/`、`ip/clk_wiz_0/`
- 根目录 `build_*.tcl`、`exec_smoke.tcl` 等（板上脚本）

测出问题告诉黄奕晨再改 UART。未消费 RX、忙时再写、停止位错误等场景按主计划由你覆盖。

---

## 刘兆钰：流水线 CPU 与系统连接

职责：CPU 接上 B 组环境。不要改 `uart_mmio` 来迁就 CPU。

**必须复制到你自己的工程：**

1. `rtl/system_env.v` — 唯一对接模块。CPU 顶层例化它。
2. 本文「CPU 接 system_env 的端口」和「地址」两节

**建议看、不要改：**

- `rtl/uart_mmio.v` — 已被 `system_env` 例化，你不必再例化一份

**不要用：**

- `sim/env_tb.v`（那是外设自检，不是 CPU testbench）
- 全部 `board_*.v`、约束、`ip/`、板上 Tcl

`system_env` 的 `clk` 必须是 **10 MHz**。100 MHz 分频在板级包装里做，不是 CPU 里做。ROM 默认 NOP；排序机器码由冯丽嘉提供后，用参数 `ROM_FILE` 配置。RAM 复位不清零，程序必须自己写数组。

### CPU 接 system_env 的端口

方向相对 CPU：

| 信号 | 方向 | 接法 |
| --- | --- | --- |
| `clk` | CPU 输入 | 10 MHz |
| `resetn` | CPU 输入 | 低有效 |
| `imem_addr[31:0]` | CPU 输出 | 接到 `system_env.imem_addr` |
| `imem_rdata[31:0]` | CPU 输入 | 来自 `system_env.imem_rdata` |
| `dmem_valid` | CPU 输出 | 一次有效数据访问 |
| `dmem_write` | CPU 输出 | 1 写、0 读 |
| `dmem_addr[31:0]` | CPU 输出 | 数据字节地址 |
| `dmem_wdata[31:0]` | CPU 输出 | 写数据 |
| `dmem_rdata[31:0]` | CPU 输入 | 来自 `system_env.dmem_rdata` |
| `overflow_flag` | CPU 输出 | 接到 `system_env.overflow_flag`，映射到 `0x4000000C` bit0 |

板级再把 `uart_rx`/`uart_tx` 接到 N5/T4。联调前仿真里可以把 RX 拉高。

---

## 左逸龙：附加功能、进度、溢出口径

职责：溢出检测、预测、故障记录、性能；不写 UART。

**必须看：**

- 本文「地址」：溢出只读 `0x4000000C` bit0，不是 UART 寄存器

**可以看：**

- `rtl/system_env.v` 里对 `overflow_flag` 的映射（约最后几行）

**不要用：** 板上冒烟、Clocking Wizard、`uart_mmio` 实现、`env_tb`。

---

## 黄奕晨：本人备份与板上工程

整夹都是你的工作副本。上板相关文件只有你需要经常动：

| 文件 | 用途 |
| --- | --- |
| `rtl/uart_mmio.v` | UART，已仿真通过，无组员反馈前不要重写 |
| `rtl/system_env.v` | 交给冯、刘对接的环境 |
| `sim/env_tb.v` | 你的自检；Restart 后只 Run All 一次 |
| `rtl/board_smoke.v` + `constraints/ees338_smoke.xdc` | LED 冒烟 |
| `rtl/board_clk.v` + `ip/clk_wiz_0/` | 100 MHz → 10 MHz |
| `rtl/board_uart_ok.v` + `constraints/ees338_uart.xdc` | 上板发 `UART_OK` |
| 根目录 Tcl | 你本机英文路径下的重建/下载脚本，组员一般不跑 |

---

## 地址（冯丽嘉、刘兆钰都要用）

| 地址 | 功能 |
| --- | --- |
| `0x00000000–0x000003FF` | 1 KiB 数据 RAM |
| `0x40000000` | UART TX，写低 8 位启动发送；读返回 0 |
| `0x40000004` | UART STATUS |
| `0x40000008` | UART RX，读低 8 位并消费 |
| `0x4000000C` | CPU 溢出，只读 bit0 |

STATUS：bit0 忙，bit1 RX 有效，bit2 overrun，bit3 帧错误，bit4 忙时再写。错误位写 1 清除。必须 4 字节对齐。

---

## 引脚（主要给黄奕晨上板；接系统时刘兆钰按此连 UART）

| 信号 | 脚 |
| --- | --- |
| 100 MHz | T5 |
| `resetn` | P15 |
| LED0 | K2 |
| FPGA `uart_tx` | T4 |
| FPGA `uart_rx` | N5 |

---

## 不要推进 GitHub 的

- `b_group` 里的 `build`、`smoke_build`、`clk_build`、`uart_ok_build`
- bitstream、`.cache`、`.runs`、`.Xil`
- `资源-20260909.zip`、往年参考、厂商实验
- 个人日志（按课程要求另交）

# CPU 子系统

M1/M2 主体由刘兆钰交付；左逸龙在 `codex/zuo-m3` 完成基础修复和 M3 接入。当前本机功能回归 19/19 通过，Vivado 与板级验证待完成。具体版本、日志、波形见 [M3 结果](pipeline/results/m3/README.md)。原始大三资料继续保留在参考资料目录。

## 使用与复跑

在仓库根目录执行 `python3 cpu/pipeline/scripts/run_tests.py --waves`。需要 Python 3 和 Icarus Verilog；运行路径不影响初始化文件定位。Vivado 2019.2 运行入口为 `pipeline/scripts/run_m3_sim.tcl`，具体方法见结果页。

例化顶层 `PipelineCPU`，加入 `pipeline/src` 下四个源文件。采用具名端口；参数 `PREDICT_EN` 默认为 1，设为 0 可关闭 BTFNT。保持五级流水线和暂停，无通用寄存器前递。单周期基线在独立目录，测试时不与流水线文件混作一个顶层。

## 系统连接

`system/src/cpu_system.v` 是 CPU 与 B 组 `system_env` 的组合顶层，保持 10 MHz 时钟域并连接指令总线、数据总线和 `overflow_flag`。运行：

```tcl
source {仓库绝对路径/cpu/system/scripts/run_send_a_sim.tcl}
```

Vivado 2019.2 会执行第一阶段端到端检查：CPU 经 UART MMIO 发送字符 `A`，通过标记为 `CPU_SYSTEM_SEND_A_PASS data=41`。后续将 `ROM_FILE` 替换为应用组程序，按固定字符串、排序结果、接收 `r` 的顺序继续 M6。

## 接口与时序

| 接口 | 方向 | 含义 |
| --- | --- | --- |
| clk / resetn | 输入 | 系统 10 MHz，低有效复位 |
| imem_addr / imem_rdata | 输出 / 输入，32 位 | 指令字节地址、组合读数据 |
| dmem_valid / dmem_write | 输出，1 位 | 有效数据请求、有效写入；每次请求一个周期 |
| dmem_addr / dmem_wdata / dmem_rdata | 输出 / 输出 / 输入，32 位 | 数据字节地址、写数据、组合读数据 |
| retire_valid / retire_pc | 输出，1 / 32 位 | 当前 WB 有效指令，在上升沿完成；包含分支、存储和写 x0 指令 |
| retire_reg_write / retire_rd / retire_wdata | 输出，1 / 5 / 32 位 | 真实寄存器写回；rd=0 时写使能为 0 |
| overflow_flag | 输出，1 位 | sticky 或当前有效 WB 溢出事件，供较年轻 MEM 状态读使用 |
| fault_valid / fault_pc / fault_addr / fault_reason | 输出，1 / 32 / 32 / 2 位 | 首故障记录；原因 1 不对齐、2 未映射 |
| branch_count / mispredict_count | 输出，各 32 位 | 有效退休条件分支数及预测错误数，复位清零 |

RAM 合法地址为 0～0x3FF；MMIO 为 0x40000000/04/08/0C，均要求四字节对齐。最后一个地址由 system_env 映射为只读溢出状态。合法只读地址写入由外设忽略，不触发权限故障。

MEM 故障发生前即抑制总线请求，取消故障指令及年轻指令，更老 WB 正常完成。fault_valid 置位后停止运行，PC 保持；只有复位恢复。数据地址检查不覆盖指令地址，也不构成完整异常系统。

add/sub/addi 只记录有符号溢出，结果仍为低 32 位；地址加法不参与。只有有效退休的算术事件才更新状态；写 x0 的算术指令也可产生事件。overflow_flag 中的当前 WB 事件用于避免紧邻状态读取采到旧值。

BTFNT 在 ID 实际发射时预测负偏移条件分支跳转，EX 比较实际与预测下一 PC。jal 在 EX 处理且不进入条件统计。控制优先级为复位、停机/故障、EX 纠正、数据暂停、ID 预测、顺序执行。所有统计按 WB 的有效退休更新。

仿真实际发射未知指令会报错；被冲刷的未知指令不报错。相关检查用 synthesis translate_off 排除于综合，未增加硬件非法指令陷阱。

## 板级交接

连接 B 组的 system_env，overflow_flag 接同名输入。板卡与引脚以黄奕晨提供并核实的 EES-338 资料为准，器件为 xc7a35tcsg324-1；不能根据先前 EGo1 名称选择约束。CPU 本轮没有完成 UART 排序、上板或时序验收。

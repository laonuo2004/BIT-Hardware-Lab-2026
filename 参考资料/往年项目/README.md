# 北理工小学期硬件实验参考资料

检索与下载日期：2026-09-08。已对照当前目录的《实验说明.md》和《参考资料/时间安排.png》。

本次收集围绕“计算机组成原理课程设计”和“汇编与接口技术课程设计”，优先选择北理工大四小学期的流水线 CPU、外设接口、报告和答辩材料。共克隆 13 个仓库，另下载 1 个 Release 工程压缩包。仓库保留原目录、原文件和 Git 来源，克隆采用默认分支的浅克隆，不包含全部历史分支。

## 先看这几份

| 优先级 | 资料 | 已核对的内容 | 对本周中期的用途 |
| --- | --- | --- | --- |
| 1 | [2023 CPU 汇报](01_往年完整项目/cangtianhuang__BIT-pipelined-cpu/提交材料/CPU/汇报PPT/CPU汇报.pptx) / [接口汇报](01_往年完整项目/cangtianhuang__BIT-pipelined-cpu/提交材料/接口/汇报PPT/汇编汇报.pptx) | 分别为 36 页、15 页，封面日期 2023/9/8；CPU 涵盖项目简介、单周期、流水线、总结；接口部分为 VGA | 参考两门课分别讲什么、如何展示模块和测试；页数不适合照搬到 15 分钟汇报 |
| 2 | [2022 四人组综合答辩](01_往年完整项目/ChiZhang-bit__BIT-MIPS-CPU_Design/团队/1120191600.pptx) | 26 页，封面日期 2022.9.2；包含四人分工、17 条 MIPS 指令、流水线相关性、VGA、仿真与下板 | 与你们四人小组更接近，适合参考汇报内容如何分配 |
| 3 | [2022 流水线与 UART 图文材料](01_往年完整项目/InkosiZhong__BIT-Hardware-Experiment/flow-line-cpu/README.md) | 本地配图包含指令、模块、数据通路、相关性、UART、计算器和仿真 | 如果想看 VGA 以外的接口方向，优先看这里 |
| 4 | [2019 流水线实验报告](03_教程与原理图/zan-pu__documentation/README.md) / [可编辑原理图目录](03_教程与原理图/zan-pu__diagram) | Markdown 报告，以及单周期、基础流水线、含冒险处理的数据通路 PNG / drawio | 理解报告结构与数据通路；报告中的外链图片未打包，原理图仓库里的图片已在本地 |

上面几份 PPT 均未明确标注“中期”。它们包含完成后的实验成果，应当视为往年答辩参考，不是今年中期验收的官方模板。本次只核对了 PPT 页数、文本和目录，并未逐页评审版式，也没有验证作者声称的仿真或上板结果。

## 分类与项目说明

### 01_往年完整项目

- **[cangtianhuang/BIT-pipelined-cpu](https://github.com/cangtianhuang/BIT-pipelined-cpu)**：2023 年材料。优先看 `提交材料/CPU` 和 `提交材料/接口`，两边均有实验报告及汇报 PPT，另有 Verilog 工程与数据通路资料。文件名为学号的 PPT 与具名 PPT 存在相似版本，保留原样，不重复计为独立项目。
- **[ChiZhang-bit/BIT-MIPS-CPU_Design](https://github.com/ChiZhang-bit/BIT-MIPS-CPU_Design)**：仓库建立于 2023 年，但 PPT 封面为 2022.9.2，按 2022 年材料理解。作者说明这是当时乐学提交物，包含四人团队 PPT、CPU 和接口报告，以及个人单周期和汇编材料。`团队` 下同时存在上板成功与未成功两类报告，应按实际内容辨别版本。
- **[I-Rinka/build-cpu-within-20days](https://github.com/I-Rinka/build-cpu-within-20days)**：README 明确为 2021 年小学期，包含单周期和流水线工程、测试、机器码、`流水线CPU.pdf`。作者报告已实现斐波那契数列下板显示，但明确提醒仓库版流水线工程不能仿真。其补充发布包放在 `04_发布版补充`；“可运行”是作者描述，本次未复现。README 中的 CPI 声明也不能替代你们自己的测量。
- **[InkosiZhong/BIT-Hardware-Experiment](https://github.com/InkosiZhong/BIT-Hardware-Experiment)**：2022 年仓库及配图，明确为北理工大四小学期硬件实验。包含单周期、流水线、UART 相关内容；README 中旧任务与今年的两门课高度对应。单周期说明要求调整 `$readmemh` 的本地路径。旧任务中的分数、联系人和个人任务不沿用到今年。

### 02_往年代码补充

- **[ripplesaround/BIT_miniCPU](https://github.com/ripplesaround/BIT_miniCPU)**：2020 年仓库，简介明确为北京理工大学大四小学期计算机组成原理部分，主要代码位于 `flow_CPU`。
- **[Serenos/BIT_CPU](https://github.com/Serenos/BIT_CPU)**：2020 年仓库，简介标注北理工 2017 级计算机小学期，含多个 CPU 工程目录和 `flowCpu_mips32`，适合补充查看代码组织。
- **[zsnoob/BIT-PIPELINE-CPU](https://github.com/zsnoob/BIT-PIPELINE-CPU)**：2023 年仓库，明确为北理计科大四小学期。默认分支主要目录实际名为 `single_cycle`，README 很简短，未发现报告或 PPT；不能仅凭仓库名称判断流水线完成程度。
- **[SwingM/BIT_CS_-_Assembly](https://github.com/SwingM/BIT_CS_-_Assembly)**：2021 年创建，README 标注北理工计科汇编／体系小学期。根目录有 CPU、VGA、数据加载等 Verilog 文件及 `single_cycle.zip`，说明较少，作为代码补充。

本节年份来自仓库建立时间，不等于已确认的课程开课年份；有明确材料日期的项目已在上面单独说明。

### 03_教程与原理图

- **[zan-pu/documentation](https://github.com/zan-pu/documentation)**：2019 年小学期流水线 CPU 团队报告，适合读总体设计与冒险处理的叙述。属于学生报告，技术细节仍应自行核验。
- **[zan-pu/pipelined-zanpu](https://github.com/zan-pu/pipelined-zanpu)**：配套五级流水线 CPU 工程与测试代码。
- **[zan-pu/diagram](https://github.com/zan-pu/diagram)**：数据通路 PNG 和 drawio 源文件。
- **[bit-mips/bitmips_experiments_doc](https://github.com/bit-mips/bitmips_experiments_doc)**：面向北理工 MIPS 实验的参考手册，覆盖单周期、简单流水线、Cache、IP 和工具使用；本地从 `lab3`、`lab5`、`others` 看起。属于教学参考，不是某一组往年答辩成果。
- **[bit-mips/bitmips_experiments](https://github.com/bit-mips/bitmips_experiments)**：上面手册链接的配套教学工程。是实验起点，不能默认已经完成所有任务。
- **[Build Your PC 在线教程](https://zanpu.spencerwoo.com/)**：明确对应 2019 年 BIT 大四小学期两门课程，覆盖 Vivado、单周期、流水线、冒险、分支预测、IP 封装和外设。网页未整站下载；相关 ZanPU 报告、代码、原理图三个仓库已下载。

### 04_发布版补充

[2021 工程发布包](04_发布版补充/I-Rinka__build-cpu-within-20days/v1.0.0/pipline_cpu.zip)来自 [Release 1.0.0](https://github.com/I-Rinka/build-cpu-within-20days/releases/tag/1.0.0)。保留原始 ZIP，校验压缩包完整性，不自动运行工程。下载地址、文件大小和 SHA-256 记录在同目录的 `来源.json`。

## 对今年要求的提醒

时间安排图第二周周五为中期验收，第三周周五为验收答辩，对应 9 月 11 日和 9 月 18 日。实验说明要求 9 月 18 日 24:00 前提交全部材料。

当前《实验说明.md》已有答辩通用评分比例：创新与特色 40%、工作难度 40%、完成质量（演示与讲）20%。未见单独的中期评分说明，不能认定这就是中期专用标准。

今年明确要求流水线处理器不少于 16 条指令，覆盖运算、传送、控制三类，并说明数据、结构、控制相关的处理。尤其新增／强调了性能量化和与组内成员大三单周期 CPU 的真实实验数据比较。往年报告不能覆盖这部分新增要求；他人的单周期性能也不能作为指定的组内基准。

若用于准备中期，建议先参考资料里的总体方案、分工、模块结构和测试表达，把你们已经完成的证据、尚未完成的内容和后续计划讲清楚。这是根据当前任务作出的准备建议，并非老师公布的中期内容要求。

## 额外线索与未收录项

- [Neon246760/CPU-Course-Design](https://github.com/Neon246760/CPU-Course-Design)：2026-08-31 创建，本次检索时仍在更新，包含中期与最终汇报范围、性能比较等文档。属于当届资料，未作为“往年项目”下载；同学自写的范围划分也不是官方评分要求。
- [muxinyu1/interface-and-assemble](https://github.com/muxinyu1/interface-and-assemble)：简介为汇编与接口小学期大作业，但本次没有充分确认学校信息，未优先收录。
- [HereIsXiao/BIT_CPU_STREAM](https://github.com/HereIsXiao/BIT_CPU_STREAM)：简介符合，但检索时仓库大小为 0，未下载。
- [123445edh/BIT-senior-primarysemester](https://github.com/123445edh/BIT-senior-primarysemester)：2026 年新仓库，目录出现后端和特征工程，未据名称归为本次硬件课程。
- Qt 聊天、Hadoop、信电／集电模拟电路和其他高校 CPU 项目未混入本目录。

检索使用了 GitHub 仓库搜索 API、网页搜索和作者仓库页面。关键词从“BIT／北京理工大学／北理工 + 小学期／大四”逐步收窄到“硬件、CPU、流水线、汇编与接口、计算机组成原理课程设计、中期答辩”，也补查了 Gitee 相关公开搜索结果。本次未找到可以确认属于往年、并明确标注中期的专用 PPT，不表示公开网络上绝不存在。

## 下载核验

各仓库来源、下载日期和提交号见 [下载清单.json](下载清单.json)。核验覆盖 Git 工作树、文件清单和主要文档格式，不包括 Vivado 仿真、综合、时序验证或开发板复现。保留原作者署名和许可证，参考时按课程规定使用；本次未向外上传本地课程材料。

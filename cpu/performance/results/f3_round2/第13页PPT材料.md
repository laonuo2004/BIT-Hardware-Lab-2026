# 结项答辩第13页：F3第二轮性能材料

## 建议主结论

- 四类程序、三个CPU版本共12组，Vivado 2019.2连续运行两轮，结果完全一致。
- BTFNT长循环：错误预测255→1，周期1799→1546。
- 32元素逆序排序：错误预测528→33，周期7840→7378。
- 当前流水线没有通用数据前递，连续数据依赖造成的暂停仍是主要性能瓶颈。
- 单周期与流水线均满足50 MHz时序；10/50 MHz数据只能表述为课程配置频率对照。

## 材料路径

- 完整表：`summary.csv`
- 可阅读汇总：`summary.md`
- 两轮原始数据：`raw_results_run1.tsv`、`raw_results_run2.tsv`
- 报告图：`figures/f3_cpu_time_50mhz.pdf`、`figures/f3_prediction_effect.pdf`

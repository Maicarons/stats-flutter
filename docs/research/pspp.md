# PSPP 2.1.2 研究纪要 → Flutter 功能映射

来源：`_ref/pspp-2.1.2`（源码 + texinfo 文档）

## 1. PSPP 界面组成（Psppire GUI）

| 界面 | 源码 | Flutter 对应 |
|------|------|--------------|
| 数据编辑器（Data/Variable 双视图） | `psppire-data-editor.c`, `psppire-data-sheet.c`, `psppire-variable-sheet.c` | `features/data_editor` |
| 变量字典 / 值标签 / 缺失值 | `psppire-dict.c`, `val-labs-dialog`, `missing-val-dialog` | 变量属性编辑器 |
| 语法编辑器 | `psppire-syntax-window.c` | `features/syntax`（规划） |
| 输出查看器 | `psppire-output-window.c`, `psppire-output-view.c` | `features/output` |
| 导入向导（文本/表格） | `psppire-import-assistant.c` | CSV/TSV 导入 |
| 分析对话框（约 40 个 .ui） | `*.ui` + `pspp-dialog-action-*.c` | `features/analysis` 对话框 |
| 查找/定位/排序/拆分/加权 | `find-dialog`, `goto-case`, `sort.ui`, `split-file.ui`, `weight.ui` | 数据操作 |

## 2. 统计过程（doc/statistics.texi + language/commands）

### 描述与探索
- DESCRIPTIVES：N、均值、标准差、方差、最小/最大、全距、偏度、峰度、SE
- FREQUENCIES：频数表、百分比、累计百分比、众数、中位数、分位数
- EXAMINE：Q-Q、茎叶、箱线、极值、正态性

### 图形
- HISTOGRAM / BAR CHART / SCATTERPLOT

### 相关与关联
- CORRELATIONS：Pearson / Spearman / Kendall
- CROSSTABS：列联表、卡方、Cramer's V

### 比较均值
- T-TEST：单样本 / 独立样本 / 配对样本
- ONEWAY ANOVA：F、事后多重比较、Levene
- MEANS：分层均值表

### 回归与预测
- LINEAR REGRESSION、LOGISTIC REGRESSION

### 降维与聚类
- FACTOR、QUICK CLUSTER（K-Means）

### 非参数（NPAR TESTS）
- BINOMIAL、CHISQUARE、KRUSKAL-WALLIS、MANN-WHITNEY、WILCOXON 等

### 信度
- RELIABILITY：Cronbach α

## 3. 对原程序的优化点
1. 移动优先布局：底部导航 + 卡片式分析入口
2. 分析向导化与即时报告
3. 学习 + 测试模块
4. 原生 fl_chart 可视化
5. 离线纯 Dart 统计内核（statkit）
6. 主题 / 多语言 / 可编辑表格

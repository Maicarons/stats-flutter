# statkit

纯 Dart 统计分析内核，零 Flutter 依赖，可在 VM / Flutter / Web 复用。
功能对齐 GNU PSPP 常用统计过程，并做数值稳定性优化。

## 能力

| 模块 | 内容 |
|------|------|
| 描述 | N/均值/SD/方差/偏度/峰度/分位数/CI/众数 |
| 分布 | 正态、t、χ²、F 的 CDF/PDF/临界值/ p 值 |
| 频率 | 频数表、百分比、累计 |
| 检验 | 单样本/独立/配对 t 检验，单因素 ANOVA，卡方拟合与独立性 |
| 相关 | Pearson / Spearman |
| 回归 | 简单与多元线性回归、系数表、ANOVA 表 |
| 非参数 | Mann-Whitney、Wilcoxon、Kruskal-Wallis、Friedman、符号、游程、KS |
| 信度 | Cronbach α |
| 聚类 | K-Means |
| 方差齐性 | Levene / Brown-Forsythe |

## 用法

```dart
import 'package:statkit/statkit.dart';

void main() {
  final d = Descriptives.compute([1.0, 2, 3, 4, 5]);
  print(d.mean); // 3.0

  final t = TTest.oneSample([2.1, 2.5, 2.8, 2.3, 2.6], mu0: 2.0);
  print(t.t, t.pTwoTail);
}
```

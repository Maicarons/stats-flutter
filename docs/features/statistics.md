# 统计过程

StatLab 的计算由独立包 [`statkit`](/api/statkit) 完成，纯 Dart 实现，无 Flutter 依赖。

## 描述统计

```dart
final d = Descriptives.compute([1.0, 2, 3, 4, 5]);
// d.mean, d.sd, d.skewness, d.ciLower95 …
```

提供：N、均值、样本标准差、方差、极值、全距、中位数、Q1/Q3/IQR、偏度、超额峰度、标准误、95% 置信区间。

## 假设检验

| 函数 | 说明 |
|------|------|
| `TTest.oneSample` | 单样本 t |
| `TTest.independentSamples` | 独立样本 t（自动 Levene → 合并/Welch） |
| `TTest.paired` | 配对样本 t |
| `OnewayAnova.compute` | 单因素 ANOVA |
| `leveneTest` | Levene / Brown-Forsythe |
| `ChiSquareTest.goodnessOfFit` | 拟合优度 |
| `ChiSquareTest.independence` | 列联表独立性 |

## 相关与回归

- `Correlation.pearson` / `Correlation.spearman`
- `Correlation.matrix` 相关矩阵
- `Regression.simple` / `Regression.multiple`（含 VIF、DW、标准化 β）

## 非参数

`Nonparametric.mannWhitney` / `wilcoxon` / `kruskalWallis` / `friedman` / `signTest` / `runsTest` / `kolmogorovSmirnovNormal`

## 信度与聚类

- `Reliability.cronbachAlpha`
- `KMeans.cluster`（k-means++ 初始化）

## 分布函数

`normCdf` `tTwoTail` `chiSquareSf` `fSf` `tCritical` `chiSquareCritical` `fCritical` `betaInc` `lnGamma` 等。

数值实现细节：

- 正态 CDF 使用 Abramowitz & Stegun 逼近
- 不完全 Gamma：级数 + Lentz 连分式（正则化）
- 不完全 Beta：连分式
- Gamma：Lanczos 近似

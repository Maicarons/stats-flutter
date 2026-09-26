# 统计过程

计算由纯 Dart 包 [`statkit`](/api/statkit) 完成。

## 对照表

| 类别 | 入口 API |
|------|----------|
| 描述 | `Descriptives.compute` |
| 频率 | `Frequencies.compute` / `histogramBins` |
| t 检验 | `TTest.oneSample` / `independentSamples` / `paired` |
| ANOVA | `OnewayAnova.compute`、`tukeyHsd` |
| 相关 | `Correlation.pearson` / `spearman` / `matrix` |
| 回归 | `Regression.simple` / `multiple` |
| 逻辑回归 | `logisticRegression` |
| 因子 | `factorPca` |
| 卡方 | `ChiSquareTest.goodnessOfFit` / `independence` |
| 非参数 | `Nonparametric.mannWhitney` / `wilcoxon` / `kruskalWallis` … |
| 信度 | `Reliability.cronbachAlpha` |
| 聚类 | `KMeans.cluster` |
| ROC | `rocCurve` |
| 正态性 | `normalityTest` |
| 均值表 | `meansTable` |

## 数值实现

- 正态 CDF：Abramowitz & Stegun
- 不完全 Gamma：级数 + Lentz 连分式
- 不完全 Beta：连分式
- Gamma：Lanczos
- 回归：高斯消元 / 约当求逆

## 测试

```bash
cd packages/statkit && dart test
```

13 组用例覆盖描述、分布、t、ANOVA、相关、回归、非参数、信度、K-Means。

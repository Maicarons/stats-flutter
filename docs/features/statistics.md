# 统计过程

计算由纯 Dart 包 [`statkit`](/api/statkit) 完成（不依赖 Flutter）。

## 对照表

| 类别 | 入口 API |
|------|----------|
| 描述 | `Descriptives.compute` |
| 频率 | `Frequencies.compute` / `histogramBins` |
| t 检验 | `TTest.oneSample` / `independentSamples` / `paired` |
| ANOVA | `OnewayAnova.compute`、`tukeyHsd` |
| 多元方差 | `oneWayManova`（Wilks / Pillai / Hotelling-Lawley / Roy，v0.7.0） |
| 协方差分析 | `ancova`（Type III 平方和） |
| 置换检验 | `Permutation.random` / `Permutation.exact`、`twoSampleMeanDifference`、`pairedDifference` |
| 相关 | `Correlation.pearson` / `spearman` / `matrix` |
| 回归 | `Regression.simple` / `multiple`、`stepwiseRegression` |
| 逻辑回归 | `logisticRegression` / `logisticRegressionFull`（二元）、`multinomialLogistic`（多分类） |
| 因子 | `factorPca` |
| 卡方 | `ChiSquareTest.goodnessOfFit` / `independence` |
| 非参数 | `Nonparametric.mannWhitney` / `wilcoxon` / `kruskalWallis` / `jonckheereTerpstra` / `lillieforsP`、`NparExtended.kendallW` / `ksExact` / `exactKolmogorovCdf` |
| 信度 | `Reliability.cronbachAlpha` |
| 聚类 | `KMeans.cluster` |
| ROC | `rocCurve` |
| 正态性 | `normalityTest` |
| 均值表 | `meansTable` |

v1.8.0 起，应用侧新增**多元方差分析 MANOVA** 页面（多因变量 + 分组变量，完整个案口径），statkit 0.7.0 的 `oneWayManova` 与 statsmodels 0.15 对拍一致（Wilks / Pillai / Hotelling-Lawley / Roy 四检验的值、F 与自由度）。

v1.7.0 起，`NparExtended.kendallW` 与 `NparExtended.ksExact` 同时在应用侧开放：分析中心的 **Kendall W 一致性**（多选变量 = 评委、个案 = 对象，任一评委缺失整行剔除）与 **KS 精确检验**（均匀 U(0,1) / 正态 N(μ,σ) / 指数 Exp(λ) 三种完全指定分布，参数手填而非由样本估计）。

statkit **0.6.0** 新增：`NparExtended.kendallW`（Kendall 一致性系数 W，Friedman χ² 的规范化形式）与 `NparExtended.ksExact` / `exactKolmogorovCdf`（单样本 KS **精确** p，Marsaglia–Tsang–Wang 2003 Durbin 矩阵法，适用于完全指定的连续分布；参数由样本估计时仍用 Lilliefors）。

statkit **0.5.0** 新增的过程（Jonckheere-Terpstra 有序趋势检验、置换检验、Lilliefors 校正、多项 logistic 回归、ANCOVA）标注为 `@experimental`：接口可能在次版本里调整。

## v1.4.0 修正与对齐的口径

- **二元 logistic 回归**：IRLS 迭代此前在两点之间振荡（工作响应权重写错），截距标准误又取了标准化尺度 —— 现在系数、OR、SE、p 都来自真正的极大似然点。
- **Levene 方差齐性**：改为以组**均值**为中心（PSPP / SPSS 的 ONEWAY、T-TEST、GLM 口径），`useMean: false` 仍可取 Brown-Forsythe。
- **Mann-Whitney U**：渐近方差补上**结校正**，p 用 `2·Φ(z)`（PSPP 的 Asymp. Sig.（双尾））；连续性校正后的 Z / p（SPSS、R 口径）另存于 `extra['zContinuityCorrected']` / `extra['pContinuityCorrected']`。
- **KS 正态性检验**：参数由样本估计时改用 **Lilliefors** 校正的 p（原先前一种口径几乎不会拒绝）。
- **取数口径**：用户缺失值 / 系统缺失、成对删除与整行删除的适用范围见[缺失值口径](/guide/missing-values)。

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

111 个用例覆盖描述、分布、t、ANOVA / ANCOVA、相关、回归、logistic、非参数与置换、信度、K-Means 等。与 PSPP 2.1.2 的对拍用例在应用侧 `test/pspp_parity_test.dart`，随 CI 一同运行。

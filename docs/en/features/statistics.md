# Statistical Procedures

Computation lives in the pure-Dart package `statkit` (no Flutter dependency).

## Highlights

- `Descriptives.compute`
- `TTest.oneSample` / `independentSamples` / `paired`
- `OnewayAnova.compute` with Levene
- `Correlation.pearson` / `spearman`
- `Regression.simple` / `multiple` (VIF, DW)
- `ChiSquareTest.goodnessOfFit` / `independence`
- `Nonparametric.*` (Mann-Whitney, Wilcoxon, Kruskal-Wallis, …)
- `Reliability.cronbachAlpha`
- `KMeans.cluster`
- Distribution helpers: `normCdf`, `tTwoTail`, `chiSquareSf`, `fSf`, …

See the [statkit API](/en/api/statkit) for full reference.

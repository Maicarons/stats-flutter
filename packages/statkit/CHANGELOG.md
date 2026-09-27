# Changelog

## 0.4.0

Modeling enhancements.

### Added
- logisticRegressionFull: IRLS, Wald SE, OR 95% CI, classification table, Hosmer-Lemeshow
- glmOneWay / glmTwoWay fixed-effects ANOVA (A, B, A×B, partial eta²)
- stepwiseRegression (forward / backward / both)
- crosstabSummary CTABLES-lite (count / mean / sum / sd / min / max / median)

### Tests
- statkit_v04_test.dart

## 0.3.0

Exploratory analysis: EXAMINE suite, chart data, enhanced normality and factor analysis.

### Added
- examine()\ — descriptives, percentiles, extremes, box plot, stem-and-leaf, Q-Q, D'Agostino-Pearson
- \percentiles\, \extremes\, \oxPlot\, \oxPlotGroups\, \stemAndLeaf- ormalQQPoints\ / ormalQQPointsStandardized- \errorBarsFromGroups- \dagostinoPearson\ normality test
- Factor: \arimax\, \kmo\, \artlettSphericity\, \actorAnalyze
### Tests
- \statkit_v03_test.dart\ (examine, charts, KMO/Bartlett, varimax)

## 0.2.0

Weighted estimation, SPLIT FILE helpers, complete NPAR set additions, and exact tests.

### Added
- `WeightedDescriptives` — frequency-weighted mean, variance, SE, CI
- `WeightedTTest.oneSample` / `independent`
- `WeightedCorrelation.pearson`
- `weightedSimpleRegression`
- `splitGroups()` / `applyWeights()` for SPLIT FILE & WEIGHT CASES semantics
- `exactBinomial`, `exactSignTest`, `fisherExact` (2×2)
- `NparExtended.binomial`, `kendallTau`, `mcnemar`, `cochranQ`, `medianTest`, `friedman`

### Tests
- New `statkit_v02_test.dart` covering weights, split, exact tests, NPAR extensions

## 0.1.0

Initial release of `statkit`, a pure-Dart statistics kernel inspired by GNU PSPP.

### Modules

- **Distributions**: normal, Student's t, chi-square, F, incomplete beta/gamma, binomial
- **Descriptives**: mean, SD, variance, skewness, kurtosis, quartiles, CI
- **Frequencies**: frequency tables, histogram binning
- **Hypothesis**: one-sample / independent / paired t-tests, Oneway ANOVA, Levene, chi-square
- **Correlation**: Pearson, Spearman, correlation matrices
- **Regression**: simple and multiple linear regression (VIF, Durbin-Watson)
- **Nonparametric**: Mann-Whitney, Wilcoxon, Kruskal-Wallis, Friedman, sign, runs, KS
- **Reliability**: Cronbach's alpha
- **Clustering**: k-means (k-means++ init)
- **Extra**: means tables, normality test, ROC/AUC, Tukey HSD, PCA factor analysis, logistic regression

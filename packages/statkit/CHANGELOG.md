# Changelog

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

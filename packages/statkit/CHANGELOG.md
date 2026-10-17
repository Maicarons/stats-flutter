# Changelog

## 0.5.0

Statistical capability upgrade: ordered-alternative and permutation tests,
Lilliefors normality, multinomial logistic regression, and ANCOVA. Two
correctness defects in binary logistic regression are fixed (see *Fixed*).

Entries added in this release are annotated `@experimental`; see "Versioning"
in [README.md](README.md) for what that promises.

### Added
- `NparExtended.jonckheereTerpstra` — Jonckheere-Terpstra ordered-alternative
  trend test: pair counting in O(n log n), tie-corrected variance, frequency
  weights, one-tailed p in `extra['pOneTail']`
- `Permutation.random` / `Permutation.exact`, `twoSampleMeanDifference`,
  `pairedDifference` — permutation framework with `(1 + #{|s| ≥ |obs|}) / (1 + B)`
  p-values (Phipson & Smyth 2010), a fixed default seed, and an exact enumeration
  mode for small sample sizes
- `Nonparametric.lillieforsP` — Lilliefors correction for the one-sample KS test
  with parameters estimated from the sample (Dallal & Wilkinson 1986; same
  approximation as R `nortest::lillie.test` and statsmodels
  `pvalmethod='approx'`)
- `multinomialLogistic` + `MultinomialResult` / `MultinomialWald` — softmax
  regression by Newton-Raphson on the analytic multinomial information;
  selectable reference category (default: the highest level, as SPSS NOMREG);
  per-equation Wald χ², odds ratios with 95% CI, likelihood-ratio χ²,
  McFadden pseudo-R², classification table, raw-scale covariance matrix
- `ancova` + `AncovaResult` / `AnovaTerm` / `AncovaSlope` / `AncovaMean` —
  analysis of covariance, `y ~ A [* B] + covariates`, with **type III** sums of
  squares (model-comparison definition: SAS-compatible, invariant to unequal
  cell counts), covariate slopes on the original scale with t/CI, and adjusted
  means (EMM) with standard errors and 95% CI
- `LogisticFullResult.iterations` / `LogisticFullResult.converged`
- `normalQuantile` — inverse standard normal CDF Φ⁻¹(p) (Acklam approximation,
  |error| < 1.15e-9), the inverse of `normCdf`; used for normal scores and
  Blom plotting positions (the Q-Q plot now shares it instead of a private copy)

### Fixed
- `logisticRegressionFull`: the IRLS step dropped the working weight of the work
  response (`z + residual / w` instead of `w * z + residual`), so the iteration
  oscillated between two points instead of reaching the maximum-likelihood
  estimate. Coefficients, odds ratios, standard errors and p-values came from a
  non-converged point — the intercept-only model with 12 ones and 9 zeros
  returned 0.5053020 instead of `log(12/9) = 0.2876821`, at a worse
  log-likelihood (−14.4614 vs −14.3411).
- `logisticRegressionFull`: the intercept standard error was read off the
  standardized scale instead of being transformed back with `A·cov·Aᵀ`.
- `logisticRegression` (`factor_logistic.dart`): was a fixed-step batch gradient
  descent that never reached the MLE. It now delegates to the corrected IRLS;
  returned fields and their meaning are unchanged.
- `Nonparametric.kolmogorovSmirnovNormal`: reported the plain Kolmogorov
  asymptotic p under a "Lilliefors" label even though mean and SD were
  estimated, which made the test almost never reject. `D` is now computed with
  signed `D+`/`D−` and the Lilliefors p is the primary p; the plain asymptotic
  value is kept in `extra['pKolmogorovAsymptotic']`.
- `leveneTest`: the default centre was the group **median** (Brown-Forsythe)
  while PSPP 2.1.2 and SPSS centre Levene's test on the group **mean** in
  ONEWAY `/STATISTICS=homogeneity`, T-TEST and GLM (PSPP `src/math/levene.c`,
  where `t_bar = Σ value·weight / n`). `useMean` now defaults to `true`;
  the median-centred Brown-Forsythe remains available as `useMean: false`.
  On PSPP's `oneway.at` example this changes F from 0.1176 to 0.0917
  (PSPP prints `.09`), which also feeds the equal/unequal-variance choice of
  `TTest.independentSamples`.
- `Nonparametric.mannWhitney`: the asymptotic variance of the *U* statistic
  ignored ties, so Z and p were wrong whenever the pooled sample had repeated
  values (`σ² = n1·n2·(n+1)/12` instead of
  `n1·n2·[(n+1)/12 − Σ(t³−t)/(12·n·(n−1))]`, which is PSPP's
  `(n³−n)/12 − Σ(t³−t)/12` after scaling, and what SPSS and R use). On PSPP's
  `npar.at` Mann-Whitney example the corrected Z is −0.6020 (PSPP prints
  `-.6020`, p `.547`) where the old variance gave −0.6014. `p` is now
  `2·Φ(z)` with no continuity correction — PSPP's "Asymp. Sig. (2-tailed)" —
  and the continuity-corrected `Z` / `p` (SPSS, R `correct = TRUE`) moved to
  `extra['zContinuityCorrected']` / `extra['pContinuityCorrected']`; the
  reported `z` and `p` are now consistent with each other. `extra` also gains
  `rankSum1`, `rankSum2` and `tieTerm`.

### Changed
- `normalityTest` now decides on the Lilliefors p, i.e. a strictly more
  conservative criterion for the same data (estimating the parameters makes the
  p smaller). The skewness/kurtosis guard (`|skewness| < 1.5`, `|kurtosis| < 3`)
  is unchanged. The previous Kolmogorov asymptotic p remains available as
  `NormalityResult.pKolmogorovAsymptotic`.
- `logisticRegressionFull` also adds `iterations` / `converged`; on complete
  separation it now returns the last finite iterate with `converged == false`
  instead of failing.

### Tests
- `statkit_v05_test.dart` (new): Jonckheere-Terpstra (hand-verified trends,
  frequency weights, ties), permutation (exact enumeration vs random, monotone
  statistic), Lilliefors (closed-form and Monte-Carlo cross-checks),
  multinomial logistic (intercept-only and saturated closed forms, binary
  degeneracy, reference-category shift), ANCOVA (FWL residualization,
  `glmTwoWay` agreement in balanced designs, hand-computed type III SS,
  adjusted-mean identity, confounding)
- `statkit_v04_test.dart`: closed-form checks for the corrected binary IRLS

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
- `examine()` — descriptives, percentiles, extremes, box plot, stem-and-leaf, Q-Q, D'Agostino-Pearson
- `percentiles`, `extremes`, `boxPlot`, `boxPlotGroups`, `stemAndLeaf`,
  `normalQQPoints` / `normalQQPointsStandardized`, `errorBarsFromGroups`,
  `dagostinoPearson` normality test
- Factor: `varimax`, `kmo`, `bartlettSphericity`, `factorAnalyze`

### Tests
- `statkit_v03_test.dart` (examine, charts, KMO/Bartlett, varimax)

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

Initial release of `statkit`, a pure-Dart statistics kernel.

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

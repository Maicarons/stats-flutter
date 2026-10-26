# Statistical Procedures

Computation lives in the pure-Dart package `statkit` (no Flutter dependency).

## Highlights

- `Descriptives.compute`
- `TTest.oneSample` / `independentSamples` / `paired`
- `OnewayAnova.compute` with Levene, `tukeyHsd`
- `ancova` — analysis of covariance, Type III sums of squares
- `Permutation.random` / `Permutation.exact`, `twoSampleMeanDifference`, `pairedDifference`
- `Correlation.pearson` / `spearman` / `matrix`
- `Regression.simple` / `multiple` (VIF, DW), `stepwiseRegression`
- `logisticRegression` / `logisticRegressionFull` (binary), `multinomialLogistic`
- `factorPca`
- `ChiSquareTest.goodnessOfFit` / `independence`
- `Nonparametric.*` (Mann-Whitney, Wilcoxon, Kruskal-Wallis, Jonckheere-Terpstra, Lilliefors, …) and `NparExtended.kendallW` / `ksExact` / `exactKolmogorovCdf`
- `Reliability.cronbachAlpha`
- `KMeans.cluster`
- Distribution helpers: `normCdf`, `tTwoTail`, `chiSquareSf`, `fSf`, …

Since v1.9.0, the CTABLES-lite page supports **multiple summary
statistics** (count / percent / mean tables in one run, numeric ones backed
by a value variable) and a **layer variable** (one table per level); `.dta`
import gains **value labels**; and **ODS (LibreOffice) import** is added.

Since v1.8.0, the app gains a **one-way MANOVA** page (multiple dependent
variables + grouping variable, complete-case convention); statkit 0.7.0's
`oneWayManova` matches statsmodels 0.15 on all four statistics (values, F,
degrees of freedom).

Since v1.7.0, `NparExtended.kendallW` and `NparExtended.ksExact` are also
exposed in the app: **Kendall's W** (multiple selected variables = judges,
cases = objects; cases with any missing judge are dropped) and **KS exact**
(Uniform U(0,1) / Normal N(μ,σ) / Exponential Exp(λ) — fully specified
distributions whose parameters you enter, not estimate).

statkit **0.6.0** adds `NparExtended.kendallW` (Kendall's coefficient of concordance W, the normalized form of the Friedman χ²) and `NparExtended.ksExact` / `exactKolmogorovCdf` (one-sample KS with an **exact** p-value via the Marsaglia–Tsang–Wang 2003 Durbin matrix method, for a fully specified continuous distribution; use Lilliefors when parameters are estimated from the sample).

Procedures added in statkit **0.5.0** (Jonckheere-Terpstra trend, permutation tests, Lilliefors, multinomial logistic regression, ANCOVA) are marked `@experimental`: their signature may change in a minor release.

## Conventions fixed and aligned in v1.4.0

- **Binary logistic regression**: the IRLS iteration used to oscillate between two points (the working response weight was wrong) and the intercept standard error came off the standardized scale. Coefficients, odds ratios, SEs and p-values now come from the actual maximum-likelihood point.
- **Levene's test** is centred on the group **mean** (the PSPP / SPSS convention for ONEWAY, T-TEST and GLM); `useMean: false` still gives Brown-Forsythe.
- **Mann-Whitney U** gained the tie correction in its asymptotic variance, with `p = 2·Φ(z)` (PSPP's Asymp. Sig. (2-tailed)); the continuity-corrected Z / p (SPSS, R) stay available as `extra['zContinuityCorrected']` / `extra['pContinuityCorrected']`.
- **KS normality test**: with parameters estimated from the sample it now reports the **Lilliefors**-corrected p (the plain asymptotic p almost never rejected).
- **Which cases enter a procedure** — user-missing values, pairwise versus row-wise deletion — is spelled out in [Missing values](/en/guide/missing-values).

## Tests

```bash
cd packages/statkit && dart test
```

111 cases cover descriptives, distributions, t tests, ANOVA / ANCOVA, correlation, regression, logistic, nonparametric and permutation tests, reliability and K-means. The PSPP 2.1.2 parity cases live in `test/pspp_parity_test.dart` on the app side and run with CI.

See the [statkit API](/en/api/statkit) for the full reference.

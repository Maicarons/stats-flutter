# statkit

Pure Dart statistics kernel: descriptives, hypothesis tests, correlation,
regression, ANOVA / ANCOVA, nonparametric tests, reliability, clustering,
ROC, PCA and logistic regression (binary and multinomial).

- **Zero Flutter dependency** — works in Dart VM, Flutter, and web. The only
  runtime dependency is `package:meta` (for the `@experimental` marker).
- Numerically robust (Lanczos gamma, incomplete beta/gamma, Welch t-test).
- Used by [Stats-flutter](https://github.com/Maicarons/stats-flutter).

## Install

```yaml
dependencies:
  statkit: ^0.5.1
```

## Quick start

```dart
import 'package:statkit/statkit.dart';

void main() {
  final data = [2.1, 2.5, 2.8, 2.3, 2.6];

  final d = Descriptives.compute(data);
  print('mean=${d.mean}  sd=${d.sd}  95% CI=[${d.ciLower95}, ${d.ciUpper95}]');

  final t = TTest.oneSample(data, mu0: 2.0);
  print('t=${t.t}  p=${formatP(t.pTwoTail)}');

  final r = Regression.simple([1.0, 2, 3, 4, 5], [2.0, 4, 6, 8, 10]);
  print('R²=${r.r2}  slope=${r.coefficients[1].beta}');
}
```

## Example

[`example/statkit_example.dart`](example/statkit_example.dart) is a runnable
tour of the kernel — descriptives, t tests, one-way ANOVA with Levene,
correlation, regression, chi-square, Mann-Whitney U, a permutation test,
normality, Cronbach alpha and k-means:

```bash
dart run example/statkit_example.dart
```

## API overview

| Module | Entry points |
|--------|----------------|
| Descriptives | `Descriptives.compute`, `percentile`, `modes` |
| Frequencies | `Frequencies.compute`, `Frequencies.histogramBins` |
| t-tests | `TTest.oneSample` / `independentSamples` / `paired` |
| ANOVA / ANCOVA | `OnewayAnova.compute`, `leveneTest`, `tukeyHsd`, `glmOneWay`, `glmTwoWay`, `ancova` |
| Correlation | `Correlation.pearson` / `spearman` / `matrix` |
| Regression | `Regression.simple` / `multiple`, `logisticRegression`, `logisticRegressionFull`, `multinomialLogistic` |
| Chi-square | `ChiSquareTest.goodnessOfFit` / `independence` |
| Nonparametric | `Nonparametric.mannWhitney` / `wilcoxon` / `kruskalWallis` / `lillieforsP` / … |
| Permutation | `Permutation.random` / `exact` / `twoSampleMeanDifference` / `pairedDifference` |
| Trend tests | `NparExtended.jonckheereTerpstra` |
| Reliability | `Reliability.cronbachAlpha` |
| Clustering | `KMeans.cluster` |
| ROC / Normality | `rocCurve`, `normalityTest` |
| Factor analysis | `factorPca`, `factorAnalyze`, `kmo`, `bartlettSphericity`, `varimax` |
| Distributions | `normCdf`, `tTwoTail`, `chiSquareSf`, `fSf`, `lnGamma`, … |
| Format | `formatNum`, `formatP`, `significanceStars` |

## Versioning

statkit follows [semantic versioning](https://semver.org), with the usual
pre-1.0 caveat that the **minor** version may contain breaking changes:

- **patch** (`0.5.0` → `0.5.1`): bug fixes only. Correcting a wrong number is a
  patch — the fix to `logisticRegressionFull` in `0.5.0` changes coefficients,
  odds ratios and p-values and is still a bug-fix release — but no public
  signature is removed or renamed.
- **minor** (`0.5.0` → `0.6.0`): new entry points and, while the version stays
  below `1.0.0`, possibly breaking changes to signatures, field names and
  defaults. Every such change is listed under `### Changed` / `### Removed` in
  [CHANGELOG.md](CHANGELOG.md).
- **major** (`1.0.0`): the public API freezes; breaking changes move to the
  next major.

Entries annotated `@experimental` (from `package:meta`) are the part of the
surface most likely to move: their *numbers* are covered by tests, but their
names, signatures and the shape of their result types may change in any
**minor** release. Dropping the annotation later is the signal that the entry
has stabilised.

This repository's app depends on statkit by path, so an app release and the
statkit version it shipped are listed together in the app's release notes
(app `1.4.0` shipped statkit `0.5.0`; `0.5.1` is the packaging patch that
followed it).

## Testing

```bash
dart pub get
dart test
```

## License

GNU Affero General Public License v3.0 (AGPL-3.0) — see [LICENSE](LICENSE).

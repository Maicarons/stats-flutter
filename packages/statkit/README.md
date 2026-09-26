# statkit

Pure Dart statistics kernel: descriptives, hypothesis tests, correlation,
regression, nonparametric tests, reliability, clustering, ROC, PCA and
logistic regression.

- **Zero Flutter dependency** — works in Dart VM, Flutter, and web.
- Numerically robust (Lanczos gamma, incomplete beta/gamma, Welch t-test).
- Used by [Stats-flutter](https://github.com/Maicarons/stats-flutter).

## Install

```yaml
dependencies:
  statkit: ^0.1.0
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

## API overview

| Module | Entry points |
|--------|----------------|
| Descriptives | `Descriptives.compute`, `percentile`, `modes` |
| Frequencies | `Frequencies.compute`, `Frequencies.histogramBins` |
| t-tests | `TTest.oneSample` / `independentSamples` / `paired` |
| ANOVA | `OnewayAnova.compute`, `leveneTest`, `tukeyHsd` |
| Correlation | `Correlation.pearson` / `spearman` / `matrix` |
| Regression | `Regression.simple` / `multiple` |
| Chi-square | `ChiSquareTest.goodnessOfFit` / `independence` |
| Nonparametric | `Nonparametric.mannWhitney` / `wilcoxon` / `kruskalWallis` / … |
| Reliability | `Reliability.cronbachAlpha` |
| Clustering | `KMeans.cluster` |
| ROC / Normality | `rocCurve`, `normalityTest` |
| PCA / Logistic | `factorPca`, `logisticRegression` |
| Distributions | `normCdf`, `tTwoTail`, `chiSquareSf`, `fSf`, `lnGamma`, … |
| Format | `formatNum`, `formatP`, `significanceStars` |

## Testing

```bash
dart pub get
dart test
```

## License

GNU Affero General Public License v3.0 (AGPL-3.0) — see [LICENSE](LICENSE).

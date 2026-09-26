# statkit API

Pure Dart statistics kernel at `packages/statkit`.

```dart
import 'package:statkit/statkit.dart';

void main() {
  final d = Descriptives.compute([1.0, 2, 3, 4, 5]);
  final t = TTest.oneSample([2.1, 2.5, 2.8], mu0: 2.0);
  print(formatP(t.pTwoTail));
}
```

## Modules

| Module | Entry points |
|--------|----------------|
| Descriptives | `Descriptives.compute`, `percentile`, `modes` |
| Hypothesis | `TTest.*`, `OnewayAnova.compute`, `ChiSquareTest.*`, `leveneTest` |
| Correlation | `Correlation.pearson` / `spearman` / `matrix` |
| Regression | `Regression.simple` / `multiple` |
| Nonparametric | `Nonparametric.mannWhitney` / `wilcoxon` / `kruskalWallis` / … |
| Reliability | `Reliability.cronbachAlpha` |
| Clustering | `KMeans.cluster` |
| Distributions | `normCdf`, `tTwoTail`, `chiSquareSf`, `fSf`, `lnGamma`, … |
| Format | `formatNum`, `formatP`, `significanceStars` |

```bash
cd packages/statkit && dart test
```

# statkit API

`statkit` 是纯 Dart 统计内核包，路径 `packages/statkit`，可独立发布到 pub.dev。

## 安装

```yaml
dependencies:
  statkit:
    path: packages/statkit
    # 或: ^0.1.0
```

## 快速示例

```dart
import 'package:statkit/statkit.dart';

void main() {
  final data = [2.1, 2.5, 2.8, 2.3, 2.6];

  final d = Descriptives.compute(data);
  print('mean=${d.mean} sd=${d.sd}');

  final t = TTest.oneSample(data, mu0: 2.0);
  print('t=${t.t} p=${formatP(t.pTwoTail)}');
}
```

## API 一览

### Descriptives
`Descriptives.compute(List<double>) → Descriptives`

字段：`n mean sd variance min max range median q1 q3 iqr skewness kurtosis se sum sumSquares ciLower95 ciUpper95 sorted`

辅助：`percentile(sorted, p)`、`modes(values)`

### TTest
- `oneSample(data, {mu0})`
- `independentSamples(g1, g2, {autoWelch})`
- `paired(a, b)`

### OnewayAnova
`compute(groups, {labels}) → AnovaResult`  
含 `f p ssBetween ssWithin etaSquared omegaSquared levene groups`

### ChiSquareTest
- `goodnessOfFit(observed, {expected})`
- `independence(observedMatrix)`

### Correlation
- `pearson(x, y)` / `spearman(x, y)`
- `matrix(columns)` / `nMatrix(columns)`

### Regression
- `simple(x, y, {xName, yName})`
- `multiple(xs, y, {predictorNames})`

### Nonparametric
`mannWhitney` `wilcoxon` `kruskalWallis` `friedman` `signTest` `runsTest` `kolmogorovSmirnovNormal`

### Reliability
`cronbachAlpha(items, {names}) → ReliabilityResult`

### KMeans
`cluster(points, {k, maxIter, seed, variableNames}) → KMeansResult`

### Distributions
`normCdf` `normPdf` `normTwoTail` `tCdf` `tTwoTail` `tCritical`  
`chiSquareCdf` `chiSquareSf` `chiSquareCritical`  
`fCdf` `fSf` `fCritical` `betaInc` `lnGamma` `gammaFn`  
`binomialPmf` `binomialSf` `combinations`

### Format
`formatNum` `formatP` `significanceStars`

## 测试

```bash
cd packages/statkit
dart pub get
dart test
```

当前覆盖：描述、分布、t 检验、ANOVA、相关、回归、非参数、信度、K-Means（13 组用例）。

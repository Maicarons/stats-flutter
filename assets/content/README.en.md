# Stats-flutter

A mobile-first statistical analysis suite inspired by [GNU PSPP](https://www.gnu.org/software/pspp/), rewritten in Flutter with **Learn** and **Quiz** modules.

## Features

- **Data editor**: data / variable views, double-click editing, add/edit/delete value labels, missing values
- **Transforms**: COMPUTE, RECODE, COUNT, RANK, SORT, SELECT IF, AGGREGATE, FLIP
- **Descriptives & Explore**: descriptives, frequencies, histogram, bar, scatter, normality tests
- **Compare means**: one-sample / independent / paired t-tests, Oneway ANOVA, Means, Tukey HSD
- **Association & prediction**: Pearson/Spearman, linear regression, crosstabs chi-square, K-Means, ROC
- **Nonparametric & reliability**: Mann-Whitney, Wilcoxon, Kruskal-Wallis, Cronbach α
- **Learn**: 8 concept lessons with core formulas
- **Quiz**: 20-question bank, instant scoring, answer review
- **CSV import/export**, share reports
- **Theme**: light / dark / system + 8 seed colors
- **i18n**: Chinese / English, switch instantly

## Stats kernel

Computation lives in the pure-Dart package [`packages/statkit`](packages/statkit) — no Flutter dependency, reusable anywhere.

```dart
import 'package:statkit/statkit.dart';

final d = Descriptives.compute([1, 2, 3, 4, 5]);
final t = TTest.oneSample(data, mu0: 70);
```

## Getting started

```bash
flutter pub get
flutter run -d windows   # or chrome / macos / linux
```

## Build mirrors

- Gradle distribution: `https://mirrors.cloud.tencent.com/gradle/`
- Maven: Aliyun `maven.aliyun.com`

## License

- Source code in this repo: MIT
- PSPP research reference: GNU PSPP is GPL; this is an independent implementation

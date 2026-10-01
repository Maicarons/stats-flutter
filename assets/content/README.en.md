# Stats-flutter

A **project-based** statistical analysis suite written in Flutter with Learn & Quiz modules.

**GitHub**: https://github.com/Maicarons/stats-flutter

**Docs site:** https://maicarons.github.io/stats-flutter/


## Navigation

```
Splash → Global tabs
  ├─ Projects   ← multi-project dataset manager (home)
  ├─ Learn      ← 8 lessons
  ├─ Quiz       ← 20-question bank
  └─ Settings   ← theme / language / about

Open project → Workspace
  ├─ Data       ← editable grid, variables, CSV
  ├─ Analysis   ← full statistical procedures
  └─ Transform  ← COMPUTE / RECODE / SORT …
```

## Features

- **Projects**: create/open/rename/duplicate/delete, JSON persistence
- **Data**: double-click edit, value-label CRUD, missing values, CSV
- **Transforms**: COMPUTE, RECODE, COUNT, RANK, SORT, SELECT IF, AGGREGATE, FLIP
- **Stats**: descriptives, t-tests, ANOVA, correlation, regression, logistic, chi-square, nonparametric, reliability, clustering, ROC, PCA
- **Syntax editor**: executable syntax command subset
- **Learn & Quiz** as global modules
- **i18n** zh/en, theme colors, unified brand logo

## Stats kernel

Pure Dart package `packages/statkit` (13 test groups):

```dart
import 'package:statkit/statkit.dart';
final d = Descriptives.compute([1, 2, 3, 4, 5]);
```

## Quick start

```bash
flutter pub get
flutter run -d windows
```

## License

AGPL-3.0

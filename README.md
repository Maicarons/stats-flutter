# Stats-flutter

**Project-based statistical analysis suite** written in Flutter with Learn & Quiz modules.

[![CI](https://github.com/Maicarons/stats-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/Maicarons/stats-flutter/actions/workflows/ci.yml)
[![Docs](https://github.com/Maicarons/stats-flutter/actions/workflows/deploy-docs.yml/badge.svg)](https://maicarons.github.io/stats-flutter/)
[![Release](https://img.shields.io/github/v/release/Maicarons/stats-flutter)](https://github.com/Maicarons/stats-flutter/releases)

**📖 Documentation:** https://maicarons.github.io/stats-flutter/  
**中文文档 / Chinese README:** [README_zh.md](./README_zh.md)

## Navigation

```
Splash → Global tabs
  ├─ Projects   ← multi-project dataset manager (home)
  ├─ Learn      ← 8 concept lessons
  ├─ Quiz       ← 20-question bank
  └─ Settings   ← theme / language / about

Open a project → Workspace
  ├─ Data       ← editable grid, variables, CSV
  ├─ Analysis   ← statistical procedures
  └─ Transform  ← COMPUTE / RECODE / SORT …
```

Learn / Quiz / Settings are **global**. Data / Analysis / Transform live **inside a project**.

## Features

### Project management
- Create (blank / demo), open, rename, duplicate, delete
- JSON persistence under `documents/stats_flutter_projects/`

### Data editing
- Double-click to edit; Enter / Tab / Esc navigation
- Variable view: type, measure, label, decimals
- **Value-label CRUD**, missing values
- Value labels **hidden by default** (toggle in toolbar)
- CSV import/export, **SPSS `.sav` export** (uncompressed system file, readable by PSPP / SPSS), weight cases, split file, find

### Transforms
COMPUTE · RECODE · COUNT · RANK · SORT CASES · SELECT IF · AGGREGATE · FLIP

### Statistical procedures
| Area | Procedures |
|------|------------|
| Describe | descriptives, frequencies, histogram, bar, scatter, normality |
| Means | one-sample / independent / paired t-tests, Oneway ANOVA, MEANS, Tukey |
| Association | Pearson/Spearman, crosstabs chi-square |
| Predict | linear regression, logistic regression, ROC, K-Means, PCA |
| Nonparametric | Mann-Whitney, Wilcoxon, Kruskal-Wallis |
| Reliability | Cronbach α |

### Syntax editor
Executable subset: `DESCRIPTIVES` `FREQUENCIES` `T-TEST` `CORRELATIONS` `COMPUTE` `RECODE` `RANK` `SORT` `SELECT IF` `LIST` `HELP`

Language layer: PSPP comment semantics (`*` / `COMMENT`), macros (`DEFINE`, positional & keyword arguments, `!LET` / `!IF` / `!DO`, `!CONCAT` …), `INCLUDE` with relative paths and cycle protection, per-command error locations, `.sps` round-trip (BOM stripping, invalid bytes → U+FFFD)

New in v1.6.0: `SAVE OUTFILE='x.sav'` writes an SPSS system file; `SPLIT FILE BY …` / `OFF` repeats every analysis per split-variable combination (one report card per group)

New in v1.7.0: program flow `DO IF / ELSE IF / ELSE`, `LOOP / BREAK`, `VECTOR` (per-case conditions with `< > <= >= = ~= AND OR NOT`); the analysis center gains **Kendall's W** and **KS exact** (fully specified distributions) pages

New in v1.8.0: syntax `TEMPORARY.` (temporary transformations expire after the next procedure); a **one-way MANOVA** page (Wilks / Pillai / Hotelling-Lawley / Roy, validated against statsmodels); **Stata `.dta` (117/118/119) import**

New in v1.9.0: CTABLES-lite upgrade — pivot tables gain **multiple summary statistics** (count / percent / mean / sum / sd / min / max / median, multi-select) and a **layer variable** (one table per level); `.dta` import gains **value labels**; **ODS (LibreOffice) import** added

New in v1.10.0: **statkit 1.0.0** (public API frozen, `@experimental` removed); syntax `DO REPEAT / END REPEAT` textual substitution macro; CTABLES-lite accepts **MRSETS multiple-response sets** as row/column variables

### Output & export
- Session output tree: one card per run, newest first, newest expanded
- Per card: copy, share, delete, export; "Export all" merges every card of the procedure
- **PDF** (bundled CJK subset font, running header, page x / y), **HTML**, **Markdown**
- Shared table styling: numeric columns right-aligned, p-value stars and colours, variable / value labels

### Platform
- i18n: English / 中文 (flutter gen-l10n)
- Theme: light / dark / system + 8 seed colors
- Unified brand logo (splash / launcher / docs)
- CJK text: bundled Noto Sans SC subset renamed `StatsSansSC` (OFL-1.1, reproducible via `tools/subset_cjk_font.py`); Latin uses Inter

## Stats kernel — `packages/statkit`

Pure Dart, no Flutter dependency. 13 test groups.

```dart
import 'package:statkit/statkit.dart';

final d = Descriptives.compute([1, 2, 3, 4, 5]);
final t = TTest.oneSample(data, mu0: 70);
final r = Regression.simple(x, y);
```

## Quick start

```bash
git clone https://github.com/Maicarons/stats-flutter.git
cd stats-flutter
flutter pub get
flutter run -d windows   # or macos / linux
```

### Tests

```bash
cd packages/statkit && dart test
cd ../.. && flutter test
```

### Docs site (local)

```bash
cd docs && npm install && npm run docs:dev
```

Published at: https://maicarons.github.io/stats-flutter/

## Build mirrors (China)

- Gradle distribution: `https://mirrors.cloud.tencent.com/gradle/`
- Maven: Aliyun `maven.aliyun.com`

## Project layout

```
stats-flutter/
├── packages/statkit/     # reusable pure-Dart stats kernel
├── lib/
│   ├── core/             # models / transforms / syntax / theme
│   ├── l10n/             # ARB (en / zh)
│   ├── features/
│   │   ├── projects/     # project list + workspace
│   │   ├── data_editor/
│   │   ├── analysis/
│   │   ├── transform/
│   │   ├── syntax/
│   │   ├── learn/  quiz/
│   │   └── settings/
│   └── shared/           # stores + BrandLogo
├── docs/                 # VitePress (zh / en)
└── android/              # Tencent Gradle + Aliyun Maven
```

## Publishing statkit

Tag a release and GitHub Actions publishes `packages/statkit` to pub.dev automatically.

```bash
# bump version in packages/statkit/pubspec.yaml + CHANGELOG
git tag v0.2.0
git push origin main v0.2.0
```

Workflow: `.github/workflows/publish.yml` · Guide: [docs/guide/publish-statkit.md](docs/guide/publish-statkit.md)

One-time: enable **Automated publishing from GitHub Actions** on [pub.dev/packages/statkit/admin](https://pub.dev/packages/statkit/admin).

## License

- Source code in this repository: AGPL-3.0

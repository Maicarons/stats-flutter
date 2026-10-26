/// v1.9.0 M2：CTABLES-lite 升级 — 多汇总指标（计数 / 百分比 / 均值…）
/// 与层变量（每层一张表）。走真实路径：参数区 → 运行 → 报告。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_catalog.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
import 'package:stats_flutter/features/output/output_store.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';

const _seed = Color(0xFF2F6FED);

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
    );

Dataset _ds() {
  // gender(1/2) × site(A/B)，score 随 site 抬升
  final cases = <List<Object?>>[
    [1.0, 'A', 10.0],
    [2.0, 'A', 12.0],
    [1.0, 'A', 14.0],
    [2.0, 'B', 20.0],
    [1.0, 'B', 22.0],
    [2.0, 'B', 24.0],
  ];
  return Dataset(name: 'ct', variables: [
    Variable(name: 'gender', decimals: 0),
    Variable(name: 'site', type: VarType.string),
    Variable(name: 'score'),
  ], cases: cases);
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    OutputStore.clear('ctables');
    datasetStore.replace(_ds());
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(560, 4200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(AnalysisRunner(
      analysisId: 'ctables',
      title: analysisById('ctables')!.title(l10n),
    )));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, int index, String value) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  testWidgets('多汇总指标：count + percent + mean（带汇总变量）',
      (tester) async {
    await open(tester);
    await pick(tester, 0, 'gender');
    await pick(tester, 1, 'site');
    await pick(tester, 2, 'score'); // 汇总变量
    // 勾选 percent / mean 芯片
    await tester.tap(find.widgetWithText(FilterChip, l10n.sumNamePercent));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, l10n.sumNameMean));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();

    // 三个汇总表各自带 caption
    expect(find.text(l10n.sumNameCount), findsWidgets);
    expect(find.text(l10n.sumNamePercent), findsWidgets);
    expect(find.text(l10n.sumNameMean), findsWidgets);
  });

  testWidgets('层变量：每层一张表（site = A / site = B）', (tester) async {
    await open(tester);
    await pick(tester, 0, 'gender');
    await pick(tester, 1, 'site');
    await pick(tester, 2, 'score'); // 汇总变量（占位，可不清空）
    await pick(tester, 3, 'site'); // 层变量
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();

    expect(find.textContaining('site = A'), findsWidgets);
    expect(find.textContaining('site = B'), findsWidgets);
  });
}

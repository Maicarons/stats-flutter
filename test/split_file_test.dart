/// SPLIT FILE 语义（v1.6.0 M2）：拆分变量非空时，分析运行层按变量值组合
/// 分组、逐组运行，每组一张报告卡片，标题带「var = value」组标签。
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
  final vars = [
    Variable(name: 'g', label: 'Group', decimals: 0)
      ..valueLabels.addAll({1: 'A', 2: 'B'}),
    Variable(name: 'x', label: 'X'),
  ];
  final cases = <List<Object?>>[
    [1.0, 10.0],
    [1.0, 12.0],
    [2.0, 20.0],
    [2.0, 24.0],
    [2.0, 26.0],
  ];
  return Dataset(name: 'split_demo', variables: vars, cases: cases);
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    OutputStore.clear('descriptives');
    datasetStore.replace(_ds());
  });

  testWidgets('SPLIT FILE: per-group report cards with group labels',
      (tester) async {
    datasetStore.data.splitVariable = 'g';
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(560, 3200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(AnalysisRunner(
      analysisId: 'descriptives',
      title: analysisById('descriptives')!.title(l10n),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();

    // 两组各自一张卡片，标题带组标签（用值标签显示）
    expect(find.textContaining('g = A'), findsWidgets);
    expect(find.textContaining('g = B'), findsWidgets);
  });

  testWidgets('SPLIT FILE cleared: single report card', (tester) async {
    datasetStore.data.splitVariable = null;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(560, 3200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(AnalysisRunner(
      analysisId: 'descriptives',
      title: analysisById('descriptives')!.title(l10n),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();

    expect(find.textContaining('g = A'), findsNothing);
    expect(find.textContaining('g = B'), findsNothing);
  });
}

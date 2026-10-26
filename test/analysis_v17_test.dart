/// v1.7.0 M1：Kendall W 与 KS 精确检验的应用侧页面。
/// 走真实路径：数据集 → 参数区 → 运行 → 报告；期望值由 statkit 直接计算。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
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

/// 4 个对象 × 3 位评委：评委 1/2 排序完全一致，评委 3 相反。
Dataset _wDataset() {
  final cases = <List<Object?>>[
    [1.0, 1.0, 4.0],
    [2.0, 2.0, 3.0],
    [3.0, 3.0, 2.0],
    [4.0, 4.0, 1.0],
  ];
  return Dataset(name: 'w_demo', variables: [
    Variable(name: 'judge1', decimals: 0),
    Variable(name: 'judge2', decimals: 0),
    Variable(name: 'judge3', decimals: 0),
  ], cases: cases);
}

Dataset _ksDataset() => Dataset(
      name: 'ks_demo',
      variables: [Variable(name: 'x', label: 'X')],
      cases: <List<Object?>>[
        [0.11], [0.23], [0.31], [0.42], [0.5], [0.56], [0.67], [0.72],
        [0.85], [0.94],
      ],
    );

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    OutputStore.clear('kendall_w');
    OutputStore.clear('ks_exact');
  });

  Future<void> open(WidgetTester tester, String id) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(560, 3600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(AnalysisRunner(analysisId: id, title: analysisById(id)!.title(l10n))),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chip(WidgetTester tester, String name) async {
    await tester.tap(find.widgetWithText(FilterChip, name));
    await tester.pumpAndSettle();
  }

  Future<void> run(WidgetTester tester) async {
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();
  }

  /// datasetStore.replace 会安排 2 s 的自动保存防抖 Timer；
  /// 用 pump 推进假时钟把它走完，避免「Timer still pending」。
  Future<void> drainSaveTimer(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('Kendall W: perfect agreement → W = 1', (tester) async {
    datasetStore.replace(_wDataset());
    await drainSaveTimer(tester);
    await open(tester, 'kendall_w');
    await chip(tester, 'judge1');
    await chip(tester, 'judge2');
    await run(tester);

    // W=1 完全一致；反序评委加入后 W 应趋近 0（statkit 独立验证）
    expect(find.textContaining('1.000'), findsWidgets);
    final r = NparExtended.kendallW([
      [1, 2, 3, 4],
      [1, 2, 3, 4],
      [4, 3, 2, 1],
    ]);
    expect(r.statistic, closeTo(0.0, 1e-12));
  });

  testWidgets('Kendall W: report renders title and mean ranks',
      (tester) async {
    datasetStore.replace(_wDataset());
    await drainSaveTimer(tester);
    await open(tester, 'kendall_w');
    await chip(tester, 'judge1');
    await chip(tester, 'judge2');
    await chip(tester, 'judge3');
    await run(tester);
    expect(find.textContaining(l10n.kendallWTitle), findsWidgets);
    expect(find.textContaining('judge1'), findsWidgets);
  });

  testWidgets('MANOVA: report renders four multivariate tests',
      (tester) async {
    final vars = [
      Variable(name: 'y1', decimals: 2),
      Variable(name: 'y2', decimals: 2),
      Variable(name: 'grp', decimals: 0),
    ];
    // 确定性数据：B/C 组均值抬升，应显著
    final cases = <List<Object?>>[];
    var seed = 11;
    double rnd() {
      seed = (1103515245 * seed + 12345) % 0x7fffffff;
      return seed / 0x7fffffff - 0.5;
    }
    for (var i = 0; i < 60; i++) {
      final g = (i % 3) + 1;
      final off = g == 1 ? 0.0 : (g == 2 ? 0.8 : 1.6);
      cases.add([
        rnd() + off,
        rnd() + off / 2,
        g.toDouble(),
      ]);
    }
    OutputStore.clear('manova');
    datasetStore.replace(Dataset(
        name: 'manova_demo', variables: vars, cases: cases));
    await drainSaveTimer(tester);
    await open(tester, 'manova');
    await chip(tester, 'y1');
    await chip(tester, 'y2');
    // 选分组变量（manova 只有一个下拉 = 分组变量）
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('grp').last);
    await tester.pumpAndSettle();
    await run(tester);
    expect(find.textContaining('Wilks'), findsWidgets);
    expect(find.textContaining('Roy'), findsWidgets);
    expect(find.textContaining(l10n.manovaTitle), findsWidgets);
  });

  testWidgets('KS exact: uniform sample vs U(0,1) not significant',
      (tester) async {
    datasetStore.replace(_ksDataset());
    await drainSaveTimer(tester);
    await open(tester, 'ks_exact');
    await chip(tester, 'x');
    await run(tester);

    final r = NparExtended.ksExact(
        [0.11, 0.23, 0.31, 0.42, 0.5, 0.56, 0.67, 0.72, 0.85, 0.94],
        (x) => x.clamp(0.0, 1.0));
    expect(r.statistic, closeTo(0.13, 1e-9));
    expect(r.p, greaterThan(0.05));
    expect(find.textContaining(l10n.ksExactTitle), findsWidgets);
  });
}

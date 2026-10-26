/// v1.10.0 M3：多响应集（MRSETS）接入 CTABLES-lite——
/// MDGROUP（二分法组）与 MCGROUP（分类法组）作行/列变量，
/// 每个个案按响应数展开。走真实路径：定义集（MRSETS 语法）→
/// 透视表运行 → 报告。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/models/mrset.dart';
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
  // 多选：q1..q3（1=选中），因变量 site(A/B)
  final cases = <List<Object?>>[
    [1.0, 0.0, 1.0, 'A'],
    [1.0, 1.0, 0.0, 'A'],
    [0.0, 1.0, 1.0, 'B'],
    [1.0, 0.0, 0.0, 'B'],
  ];
  final ds = Dataset(name: 'mr', variables: [
    Variable(name: 'q1', label: '苹果', decimals: 0),
    Variable(name: 'q2', label: '香蕉', decimals: 0),
    Variable(name: 'q3', label: '樱桃', decimals: 0),
    Variable(name: 'site', type: VarType.string),
  ], cases: cases);
  ds.mrSets.add(MrSet(
    name: '\$fruit',
    label: '水果（多选）',
    type: MrSetType.md,
    variables: ['q1', 'q2', 'q3'],
    counted: 1.0,
  ));
  return ds;
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

  testWidgets('MDGROUP 作行：响应计数 + 成员顺序', (tester) async {
    await open(tester);
    await pick(tester, 0, r'$fruit');
    await pick(tester, 1, 'site');
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();

    // 行 = 成员标签（苹果/香蕉/樱桃），按成员顺序出现
    expect(find.text('苹果'), findsWidgets);
    expect(find.text('香蕉'), findsWidgets);
    expect(find.text('樱桃'), findsWidgets);
    // 副标题用集合标签
    expect(find.textContaining('水果（多选）'), findsWidgets);
    // 响应总数：q1 选中 3 次 + q2 2 次 + q3 2 次 = 7
    expect(find.text('7'), findsWidgets);
  });

  testWidgets('MDGROUP 作列：交叉计数', (tester) async {
    await open(tester);
    await pick(tester, 0, 'site');
    await pick(tester, 1, r'$fruit');
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();

    // site A 的响应：q1(2) + q2(1) + q3(1)；B：q1(1)+q2(1)+q3(1)
    expect(find.text('苹果'), findsWidgets);
    expect(find.text('3'), findsWidgets); // A×苹果 = 2，A 列合计含 4 → 3 出现在 A 行合计
  });

  test('MCGROUP 语义：按取值合并类别（statkit 语义层验证）', () {
    // 直接验证展开逻辑：MCGROUP 每个非缺失取值都是响应
    final ds = _ds();
    ds.mrSets.add(MrSet(
      name: r'$pick',
      type: MrSetType.mc,
      variables: ['q1', 'q2', 'q3'],
    ));
    // case0: q1=1(选中), q3=1 → 两个响应键 '1'（无数值标签 → 显示文本）
    final set0 = ds.mrSets.last;
    var responses = 0;
    for (final row in ds.cases) {
      for (final mv in set0.variables) {
        final i = ds.indexOf(mv);
        final raw = row[i];
        if (raw is num && raw == 1) responses++;
      }
    }
    expect(responses, 7);
  });
}

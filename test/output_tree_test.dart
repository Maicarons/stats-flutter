/// v1.5.0 M4.1 输出树：多次运行累积成卡片、折叠/删除/清空、会话内保留、
/// 导出全部（`combinedReport`）与静态存储 `OutputStore`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
import 'package:stats_flutter/features/output/output_store.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/output/report_card.dart';
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

Dataset _tiny() => Dataset(
      name: 'tiny',
      variables: [
        Variable(name: 'a'),
        Variable(name: 'b'),
      ],
      cases: const [
        [1.0, 2.0],
        [2.0, 3.0],
        [3.0, 4.5],
        [4.0, 5.0],
      ],
    );

AnalysisReport _report(String varName) => AnalysisReport(
      title: 'Report $varName',
      subtitle: '',
      createdAt: DateTime.utc(2026, 1, 2, 3, 4),
      sections: [
        ReportSection(
          heading: 'S',
          tables: [
            ReportTable(headers: const ['v', 'n'], rows: [
              [varName, '4'],
            ]),
          ],
        ),
      ],
    );

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('OutputStore', () {
    setUp(OutputStore.reset);

    test('追加时最新在最前，按分析隔离', () {
      final r1 = _report('a');
      final r2 = _report('b');
      OutputStore.add('descriptives', r1);
      OutputStore.add('descriptives', r2);
      OutputStore.add('anova', r1);

      expect(OutputStore.of('descriptives'), [r2, r1]);
      expect(OutputStore.of('anova').single, r1);
      expect(OutputStore.has('descriptives'), isTrue);
      expect(OutputStore.has('ttest_ind'), isFalse);
    });

    test('删除与清空', () {
      final r1 = _report('a');
      final r2 = _report('b');
      OutputStore.add('x', r1);
      OutputStore.add('x', r2);

      expect(OutputStore.remove('x', r1), isTrue);
      expect(OutputStore.of('x'), [r2]);
      expect(OutputStore.remove('x', r1), isFalse, reason: '已经删过');

      OutputStore.clear('x');
      expect(OutputStore.of('x'), isEmpty);
      expect(OutputStore.anyReport, isFalse);
    });
  });

  group('combinedReport', () {
    test('只有一份时原样返回', () {
      final r = _report('a');
      expect(combinedReport([r], title: 'All'), same(r));
    });

    test('多份时按运行分隔小节拼接，原分区保持不变', () {
      final all = combinedReport(
        [_report('b'), _report('a')],
        title: 'All',
        createdAt: DateTime.utc(2026, 1, 2, 3, 5),
      );
      expect(all.title, 'All');
      // 每份报告一个小节（slug run-N）+ 它原有的分区（原样保留）
      expect(all.sections.length, 4);
      expect(all.sections[0].slug, 'run-1');
      expect(all.sections[2].slug, 'run-2');
      expect(all.sections.first.heading, startsWith('Report b · '));
      expect(all.sections[2].heading, startsWith('Report a · '));
      expect(all.sections[1].heading, 'S');
      expect(all.sections[1].tables.single.rows.single.first, 'b');
      expect(all.sections[3].tables.single.rows.single.first, 'a');
    });

    test('空列表是可编程错误', () {
      expect(() => combinedReport(const [], title: 'All'), throwsArgumentError);
    });
  });

  group('输出树（widget）', () {
    setUp(() {
      OutputStore.reset();
      datasetStore.replace(_tiny());
    });

    Future<void> open(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(560, 4200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(const AnalysisRunner(analysisId: 'descriptives', title: 'Descriptives')),
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

    testWidgets('同一分析连跑 3 次 → 3 张卡片，最新在上、只展开最新一张', (tester) async {
      await open(tester);
      await chip(tester, 'a');
      await run(tester);
      await chip(tester, 'b');
      await run(tester);
      await chip(tester, 'a'); // 取消 a → 只剩 b
      await run(tester);

      expect(find.byType(ReportCard), findsNWidgets(3));
      final store = OutputStore.of('descriptives');
      expect(store.length, 3);
      expect(store.first.sections.first.tables.first.rows.single.first, 'b');
      expect(store.last.sections.first.tables.first.rows.single.first, 'a');
      // 折叠态：分区标题只在展开的那张（最新）里渲染
      expect(find.text(l10n.descriptivesStats), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('卡片可折叠、可删除、可清空', (tester) async {
      await open(tester);
      await chip(tester, 'a');
      await run(tester);
      await run(tester);
      expect(find.byType(ReportCard), findsNWidgets(2));
      expect(find.text(l10n.descriptivesStats), findsOneWidget);

      // 展开旧的那张（chevron_right 只在折叠卡片上）
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.descriptivesStats), findsNWidgets(2));

      // 折叠最新那张
      await tester.tap(find.byIcon(Icons.expand_more).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.descriptivesStats), findsOneWidget);

      // 删除第一张
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.byType(ReportCard), findsOneWidget);
      expect(OutputStore.of('descriptives').length, 1);

      // 清空：二次确认后连「输出」表头一起消失
      await tester.tap(find.widgetWithText(TextButton, l10n.clearOutput));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.clearOutput).last);
      await tester.pumpAndSettle();
      expect(find.byType(ReportCard), findsNothing);
      expect(find.text(l10n.outputTitle), findsNothing);
      expect(OutputStore.of('descriptives'), isEmpty);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('切页面再回来，输出还在（会话内保留）', (tester) async {
      await open(tester);
      await chip(tester, 'a');
      await run(tester);
      expect(find.byType(ReportCard), findsOneWidget);

      await tester.pumpWidget(_app(const Scaffold(body: Text('other page'))));
      await tester.pumpAndSettle();
      expect(find.byType(ReportCard), findsNothing);

      await open(tester);
      expect(find.byType(ReportCard), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AppBar 有「分享全部 / 导出全部」两个入口', (tester) async {
      await open(tester);
      expect(find.byIcon(Icons.share), findsNothing, reason: '没有输出时不显示');

      await chip(tester, 'a');
      await run(tester);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();
      expect(find.text(l10n.exportPdf), findsOneWidget);
      expect(find.text(l10n.exportMarkdown), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });
  });
}

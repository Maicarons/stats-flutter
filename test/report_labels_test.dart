/// 变量标签 / 值标签（v1.5.0 M4.3）：
/// 1. `report_labels.dart` 的显示名、值标签、注释映射；
/// 2. 报告构建处（描述 / 相关 / 卡方交叉表）真的用标签而不是变量名；
/// 3. 跑到屏幕上：频数分析的变量名与类别都显示标签。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_catalog.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
import 'package:stats_flutter/features/output/output_store.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/output/report_labels.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';

const _seed = Color(0xFF2F6FED);

Widget _host(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
    );

Dataset _ds() => Dataset(
      name: 'labels',
      variables: [
        Variable(
          name: 'gender',
          label: 'Gender',
          valueLabels: const {1: 'Male', 2: 'Female'},
        ),
        Variable(name: 'score'),
      ],
      cases: const [
        [1.0, 10.0],
        [2.0, 12.0],
        [1.0, 14.0],
      ],
    );

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    // OutputStore 是静态的：不重置会串到下一条用例
    OutputStore.reset();
    datasetStore.replace(_ds());
  });

  group('变量显示名', () {
    test('有标签用标签，没有标签回落变量名', () {
      final ds = _ds();
      expect(variableLabel(ds, 'gender'), 'Gender');
      expect(variableLabel(ds, 'score'), 'score');
      expect(variableLabel(ds, 'nope'), 'nope');
    });

    test('只有标签与名字不同的变量进映射表', () {
      final ds = _ds();
      expect(variableLabels(ds, ['gender', 'score']), {'gender': 'Gender'});
      expect(variableLabels(ds, ['score']), isEmpty);
    });

    test('值标签按变量取出；未知变量给空表', () {
      final ds = _ds();
      expect(valueLabelsOf(ds, 'gender'), {1: 'Male', 2: 'Female'});
      expect(valueLabelsOf(ds, 'score'), isEmpty);
      expect(valueLabelsOf(ds, 'nope'), isEmpty);
    });

    test('注释只在真的有标签时出现，并给出「标签 = 变量名」', () {
      final ds = _ds();
      final note = variableLabelNote(l10n, ds, ['gender', 'score']);
      expect(note, isNotNull);
      expect(note, contains('Gender = gender'));
      // score 没有标签，不该出现在注释里
      expect(note, isNot(contains('score')));
      expect(variableLabelNote(l10n, ds, ['score']), isNull);
    });

    test('注释合并：两个都有时空行分隔，只有一个时用它自己', () {
      expect(mergeNotes('A', 'B'), 'A\nB');
      expect(mergeNotes('A', null), 'A');
      expect(mergeNotes(null, 'B'), 'B');
      expect(mergeNotes('A', '  '), 'A');
      expect(mergeNotes(null, null), '');
    });
  });

  group('报告表用标签', () {
    test('描述统计：变量行显示标签，注释追加对应关系', () {
      final rep = reportDescriptives(
        l10n,
        {'gender': Descriptives.compute(const [1, 2, 1])},
        labels: {'gender': 'Gender'},
        labelNote: 'Gender = gender',
      );
      expect(rep.sections.first.tables.first.rows.first.first, 'Gender');
      expect(rep.sections.first.notes, contains('Gender = gender'));
      // 原有注释不被顶掉
      expect(rep.sections.first.notes, contains(l10n.ciNote));
    });

    test('描述统计：没有标签时原样显示变量名', () {
      final rep = reportDescriptives(
        l10n,
        {'score': Descriptives.compute(const [1.0, 2.0, 3.0])},
      );
      expect(rep.sections.first.tables.first.rows.first.first, 'score');
      expect(rep.sections.first.notes, l10n.ciNote);
    });

    test('相关：行标签与表头都用标签', () {
      final m = {'gender': <String, CorrelationResult>{}, 'score': <String, CorrelationResult>{}};
      for (final a in m.keys) {
        for (final b in m.keys) {
          m[a]![b] = Correlation.pearson(const [1, 2, 3], const [2, 4, 6]);
        }
      }
      final rep = reportCorrelation(
        l10n,
        m,
        labels: {'gender': 'Gender'},
        labelNote: 'Gender = gender',
      );
      final t = rep.sections.first.tables.first;
      expect(t.headers, ['', 'Gender', 'score']);
      expect(t.rows.first.first, 'Gender');
      expect(t.rows.first[1], '1');
      expect(rep.sections.first.notes, contains('Gender = gender'));
    });

    test('卡方：交叉表行列用值标签，单元格表带行列标签', () {
      final r = ChiSquareTest.independence(const [
        [10, 20],
        [30, 40],
      ]);
      final rep = reportChiSquare(
        l10n,
        r,
        rowVar: 'Gender',
        colVar: 'Method',
        rowLabels: const ['Male', 'Female'],
        colLabels: const ['Lecture', 'Inquiry'],
        labelNote: 'Gender = gender',
      );

      final cross = rep.sections.firstWhere((s) => s.heading == l10n.crossTable);
      final ct = cross.tables.single;
      expect(ct.caption, l10n.observed);
      expect(ct.headers, ['Gender', 'Lecture', 'Inquiry']);
      expect(ct.rows, [
        ['Male', '10', '20'],
        ['Female', '30', '40'],
      ]);

      final cells = rep.sections.last;
      expect(cells.tables.single.headers.first, 'Gender · Method');
      expect(cells.tables.single.rows.first.first, 'Male · Lecture');
      expect(cells.tables.single.rows.last.first, 'Female · Inquiry');
      expect(cells.notes, 'Gender = gender');
      // 行列标签按行主序展开：第 3 个格子是第二行第一列
      expect(cells.tables.single.rows[2].first, 'Female · Lecture');
    });

    test('卡方：没有值标签时用序号兜底', () {
      final r = ChiSquareTest.independence(const [
        [10, 20],
        [30, 40],
      ]);
      final rep = reportChiSquare(l10n, r);
      final ct =
          rep.sections.firstWhere((s) => s.heading == l10n.crossTable).tables.single;
      expect(ct.headers, ['', '1', '2']);
      expect(ct.rows.first, ['1', '10', '20']);
      expect(rep.sections.last.tables.single.rows.first.first, '1 · 1');
    });
  });

  group('频数分析整链路', () {
    testWidgets('变量名与类别都显示标签', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 1600);
      addTearDown(tester.view.reset);

      // 演示数据：gender 的标签是 Gender，值标签 Male / Female
      datasetStore.replace(Dataset.demoScores(zh: false));

      await tester.pumpWidget(_host(
        AnalysisRunner(
          analysisId: 'frequencies',
          title: analysisById('frequencies')!.title(l10n),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.runAnalysis));
      await tester.pumpAndSettle();

      // 报告副标题是变量标签，表里是值标签
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Male'), findsWidgets);
      expect(find.text('Female'), findsWidgets);
      // 注释给出「标签 = 变量名」
      expect(find.textContaining('Gender = gender'), findsOneWidget);
    });
  });
}

/// 图表组件 + 分析参数覆盖（v1.3.1）：
/// 1. 自绘图（箱线 / 误差条）与 fl_chart 封装（Q-Q / 碎石 / 直方 / 条形 / 散点）能渲染；
/// 2. 每个分析目录条目都必须在参数区暴露选择器 —— 防止再出现「点了运行却无处选变量」。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_catalog.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';
import 'package:stats_flutter/shared/ui/charts/charts.dart';
import 'package:stats_flutter/shared/ui/ui.dart';

const _seed = Color(0xFF2F6FED);

Widget _host(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      darkTheme: AppTheme.dark(_seed),
      home: home,
    );

/// 图表需要确定尺寸才能布局。
Widget _chartHost(Widget chart, {double w = 420, double h = 260}) => _host(
      Scaffold(
        body: Center(child: SizedBox(width: w, height: h, child: chart)),
      ),
    );

/// 40 个近似正态点 + 1 个离群点，保证箱体 / 须 / 离群点都有内容。
final _sample = <double>[
  for (var i = 0; i < 40; i++) 50 + i * 1.3,
  200,
];

void main() {
  group('箱线图', () {
    testWidgets('单组渲染箱体，离群点被识别', (tester) async {
      final box = boxPlot(_sample);
      expect(box.outliers, isNotEmpty);

      await tester.pumpWidget(
        _chartHost(BoxPlotChart(boxes: [box], labels: ['post'])),
      );

      expect(find.byType(BoxPlotChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('多组并列渲染', (tester) async {
      final boxes = boxPlotGroups([_sample, _sample.reversed.toList()]);
      await tester.pumpWidget(
        _chartHost(BoxPlotChart(boxes: boxes, labels: const ['A', 'B'])),
      );
      expect(find.byType(BoxPlotChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('空数据显示空态文案', (tester) async {
      await tester.pumpWidget(_chartHost(
        const BoxPlotChart(boxes: [], labels: [], emptyLabel: 'no data'),
      ));
      expect(find.text('no data'), findsOneWidget);
    });

    test('值域覆盖离群点与均值', () {
      final (lo, hi) = BoxPlotChart.valueRange([boxPlot(_sample)]);
      expect(lo, lessThanOrEqualTo(50));
      expect(hi, greaterThanOrEqualTo(200));
    });
  });

  group('误差条图', () {
    testWidgets('分组均值 + 置信区间须 + 参考线', (tester) async {
      final bars = errorBarsFromGroups({
        'A': _sample,
        'B': [for (final v in _sample) v - 6],
      });
      expect(bars, hasLength(2));
      expect(bars.first.low, lessThan(bars.first.mean));

      await tester.pumpWidget(_chartHost(
        ErrorBarChart(bars: bars, referenceLine: bars.first.mean),
      ));

      expect(find.byType(ErrorBarChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('空数据显示空态', (tester) async {
      await tester.pumpWidget(_chartHost(
        const ErrorBarChart(bars: [], emptyLabel: 'empty'),
      ));
      expect(find.text('empty'), findsOneWidget);
    });
  });

  group('Q-Q 图', () {
    testWidgets('散点 + 参考线渲染，偏离最大的点被标记', (tester) async {
      final pts = normalQQPointsStandardized(_sample);
      expect(pts, isNotEmpty);
      expect(QQPlot.topDeviationIndices(pts, 3), hasLength(3));

      await tester.pumpWidget(_chartHost(QQPlot(points: pts)));
      expect(find.byType(QQPlot), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('数据不足显示空态', (tester) async {
      await tester.pumpWidget(
        _chartHost(const QQPlot(points: [], emptyLabel: 'too few')),
      );
      expect(find.text('too few'), findsOneWidget);
    });
  });

  group('碎石图', () {
    testWidgets('曲线 + 肘部标记渲染', (tester) async {
      final eig = [3.4, 1.2, 0.8];
      await tester.pumpWidget(
        _chartHost(ScreePlot(eigenvalues: eig, labels: const ['PC1', 'PC2', 'PC3'])),
      );
      expect(find.byType(ScreePlot), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('肘部取下降曲率最大的分量', () {
      expect(ScreePlot.elbowComponent([3.4, 1.2, 0.8]), 2);
      expect(ScreePlot.elbowComponent([5.0, 0.4, 0.2]), 2);
      // 分量不足 3 个时不标肘部
      expect(ScreePlot.elbowComponent([2.0, 1.0]), isNull);
    });
  });

  group('迁移后的既有图表', () {
    testWidgets('直方图 / 条形图 / 散点图 / 聚类散点图均可渲染', (tester) async {
      final values = _sample;
      final bins = Frequencies.histogramBins(values);
      final rows = Frequencies.compute(values, variableName: 'v').rows;

      for (final chart in <Widget>[
        HistogramChart(bins: bins, xTitle: 'v'),
        FrequencyBarChart(rows: rows),
        ScatterChartView(
          points: [for (var i = 0; i < bins.length; i++) Offset(i.toDouble(), i * 2.0)],
          xTitle: 'x',
          yTitle: 'y',
        ),
        ClusterScatterChart(
          points: const [Offset(0, 0), Offset(1, 1), Offset(2, 2)],
          assignments: const [0, 1, 1],
          centers: const [Offset(0, 0), Offset(2, 2)],
        ),
      ]) {
        await tester.pumpWidget(_chartHost(chart));
        expect(tester.takeException(), isNull, reason: '$chart 渲染异常');
      }
    });

    testWidgets('直方图空态', (tester) async {
      await tester.pumpWidget(
        _chartHost(const HistogramChart(bins: [], emptyLabel: 'no bins')),
      );
      expect(find.text('no bins'), findsOneWidget);
    });
  });

  group('分析运行页参数覆盖', () {
    setUp(() {
      datasetStore.replace(Dataset.demoScores(zh: false));
    });

    /// 33 个条目全部要有参数选择器（单选/多选变量、分组、X/Y 或行列下拉）。
    testWidgets('每个分析条目都暴露参数选择器', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 1400);
      addTearDown(tester.view.reset);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final ids = analysisCatalog.expand((c) => c.items).map((i) => i.id).toList();
      expect(ids.length, greaterThanOrEqualTo(33));

      for (final id in ids) {
        await tester.pumpWidget(
          _host(AnalysisRunner(analysisId: id, title: analysisById(id)!.title(l10n))),
        );
        await tester.pumpAndSettle();

        final pickers = find.byType(ParamVarPicker).evaluate().length +
            find.byType(DropdownButtonFormField<String>).evaluate().length +
            find.byType(TextField).evaluate().length;
        expect(pickers, greaterThan(0), reason: '$id 缺少参数选择器');
      }
    });

    testWidgets('箱线图选变量后运行，输出报告与箱线图', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 1600);
      addTearDown(tester.view.reset);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(_host(
        AnalysisRunner(analysisId: 'boxplot', title: analysisById('boxplot')!.title(l10n)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.runAnalysis));
      await tester.pumpAndSettle();

      expect(find.byType(BoxPlotChart), findsOneWidget);
      expect(find.text(l10n.distSummary), findsOneWidget);
      // 图例说明箱体 / 中位数 / 均值
      expect(find.text(l10n.legendBox), findsOneWidget);
    });

    testWidgets('误差条图选变量后运行，输出误差条与图例', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 1600);
      addTearDown(tester.view.reset);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(_host(
        AnalysisRunner(analysisId: 'errorbar', title: analysisById('errorbar')!.title(l10n)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.runAnalysis));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBarChart), findsOneWidget);
      expect(find.text(l10n.legendCi), findsOneWidget);
      expect(find.text(l10n.errorBarNote), findsOneWidget);
    });
  });
}

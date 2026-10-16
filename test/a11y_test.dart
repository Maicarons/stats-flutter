import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/data_editor/data_editor_page.dart';
import 'package:stats_flutter/features/learn/learn_page.dart';
import 'package:stats_flutter/features/quiz/quiz_page.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';
import 'package:stats_flutter/shared/ui/charts/charts.dart';

const _seed = Color(0xFF2F6FED);

/// 40 个近似正态点 + 1 个离群点，保证箱体 / 须 / 离群点都有内容。
final _sample = <double>[
  for (var i = 0; i < 40; i++) 50 + i * 1.3,
  200,
];

Widget _app(Widget home, {Locale locale = const Locale('en'), bool dark = false}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: dark ? AppTheme.dark(_seed) : AppTheme.light(_seed),
      home: home,
    );

void _sizeTo(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// 树中所有 IconButton 都必须有 tooltip（仅图标按钮的无障碍名称来源）。
/// [requireAny] 为 true 时要求页面至少含一个图标按钮。
void _expectIconButtonsLabelled({bool requireAny = false}) {
  final buttons = find.byType(IconButton).evaluate().toList();
  if (requireAny) {
    expect(buttons, isNotEmpty, reason: '测试页面应当包含图标按钮');
  }
  for (final e in buttons) {
    final w = e.widget as IconButton;
    expect(
      w.tooltip,
      isNotNull,
      reason: '存在缺少 tooltip 的 IconButton',
    );
  }
}

void main() {
  setUp(() {
    datasetStore.replace(Dataset.demoScores(zh: false));
  });

  group('文本对比度（明/暗）', () {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('学习页对比度达 AA（$mode）', (tester) async {
        _sizeTo(tester, const Size(420, 900));
        await tester.pumpWidget(_app(const LearnPage(), dark: dark));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });

      testWidgets('数据编辑器对比度达 AA（$mode）', (tester) async {
        _sizeTo(tester, const Size(1000, 800));
        await tester.pumpWidget(_app(const DataEditorPage(), dark: dark));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('测试页对比度达 AA（$mode）', (tester) async {
        _sizeTo(tester, const Size(420, 900));
        await tester.pumpWidget(_app(const QuizPage(), dark: dark));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        // 进入答题界面后再检查一次（选项卡 + 进度条）
        await tester.tap(find.text('Start quiz'));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    }
  });

  group('触摸目标', () {
    testWidgets('测试页所有可点元素满足 Android 最小触摸尺寸', (tester) async {
      _sizeTo(tester, const Size(420, 900));
      await tester.pumpWidget(_app(const QuizPage()));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group('图表图例对比度（v1.3.1 新图表）', () {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('箱线 / 误差条 / Q-Q / 碎石图图例达 AA（$mode）', (tester) async {
        _sizeTo(tester, const Size(420, 1600));

        final boxes = boxPlotGroups([
          _sample,
          [for (final v in _sample) v - 6],
        ]);
        final bars = errorBarsFromGroups({
          'A': _sample,
          'B': [for (final v in _sample) v - 6],
        });
        final pts = normalQQPointsStandardized(_sample);

        final charts = <Widget>[
          BoxPlotChart(boxes: boxes, labels: const ['A', 'B']),
          ErrorBarChart(bars: bars, referenceLine: bars.first.mean),
          QQPlot(points: pts),
          ScreePlot(
            eigenvalues: const [3.4, 1.2, 0.8],
            labels: const ['PC1', 'PC2', 'PC3'],
          ),
        ];
        final legends = <List<ChartLegendItem>>[
          const [
            ChartLegendItem(color: _seed, label: 'Interquartile box Q1–Q3'),
            ChartLegendItem(color: Colors.transparent, label: 'Median'),
          ],
          const [
            ChartLegendItem(color: _seed, label: 'Mean'),
            ChartLegendItem(color: Colors.transparent, label: '95% confidence interval'),
          ],
          const [
            ChartLegendItem(color: _seed, label: 'Sample quantile z'),
            ChartLegendItem(color: Colors.transparent, label: 'Reference line y = x'),
          ],
          const [
            ChartLegendItem(color: _seed, label: 'Eigenvalue'),
            ChartLegendItem(color: Colors.transparent, label: 'Cumulative variance'),
          ],
        ];

        for (var i = 0; i < charts.length; i++) {
          await tester.pumpWidget(
            _app(
              Scaffold(
                body: SingleChildScrollView(
                  child: ChartCard(
                    title: 'Chart ${i + 1}',
                    legend: legends[i],
                    child: charts[i],
                  ),
                ),
              ),
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(
            tester,
            meetsGuideline(textContrastGuideline),
            reason: '${charts[i].runtimeType} 的图例 / 轴标签对比度不足',
          );
        }
      });
    }
  });

  group('无障碍标签', () {
    testWidgets('学习页图标按钮均有 tooltip', (tester) async {
      _sizeTo(tester, const Size(420, 900));
      await tester.pumpWidget(_app(const LearnPage()));
      _expectIconButtonsLabelled();
    });

    testWidgets('数据编辑器图标按钮均有 tooltip', (tester) async {
      _sizeTo(tester, const Size(1000, 800));
      await tester.pumpWidget(_app(const DataEditorPage()));
      await tester.pumpAndSettle();
      _expectIconButtonsLabelled(requireAny: true);

      final handle = tester.ensureSemantics();
      expect(find.byType(TextField), findsOneWidget);
      handle.dispose();

      await tester.pump(const Duration(seconds: 3));
    });
  });
}

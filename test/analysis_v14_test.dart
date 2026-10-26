/// v1.4.0 新增分析过程的端到端覆盖（M1.6 应用侧暴露）：
/// 有序趋势检验（Jonckheere-Terpstra）、置换检验、协方差分析（ANCOVA）、
/// 多项 logistic 回归，以及正态性报告里的 Lilliefors / Kolmogorov 两个 p。
///
/// 走的是真实路径：数据集 → 参数区选择（筛选块与下拉）→ 运行 → 报告表格；
/// 断言用「同一份数据直接调 statkit 得到的数值」在报告里出现，因此既覆盖
/// 参数装配（列序、缺失处理、标签映射），也覆盖报告表的拼装。
library;


import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_catalog.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
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

/// 确定性数据：60 个案例，含
/// - `gain`：连续因变量（随分组 D1/D2/D3 单调上升，且与 pre / effort 相关）
/// - `pre` / `effort`：连续自变量（协变量）
/// - `method`：3 个有序水平 D1…D3；`site`：2 个水平 A/B
/// - `rating`：3 类名义因变量（由协变量按多项式概率抽样，不会完全分离）
/// - `before` / `after`：配对测量
Dataset _v14Dataset() {
  final rng = math.Random(7);
  final cases = <List<Object?>>[];
  for (var i = 0; i < 60; i++) {
    final pre = 40 + rng.nextDouble() * 30;
    final effort = 1 + rng.nextDouble() * 3;
    final method = (i % 3) + 1;
    final site = (i % 2) + 1;
    final gain =
        4 + method * 3 + 0.25 * pre + 0.8 * effort + (rng.nextDouble() - 0.5) * 6;
    // rating：按 softmax 概率抽样（含噪声，避免线性可分导致的系数发散）
    final eta1 = 0.5 + 0.9 * (pre - 55) / 10;
    final eta2 = -0.4 + 0.8 * (effort - 2.5);
    final e1 = math.exp(eta1), e2 = math.exp(eta2);
    final den = 1 + e1 + e2;
    final u = rng.nextDouble();
    final rating = u < 1 / den ? 3 : (u < (1 + e1) / den ? 1 : 2);
    final before = 50 + rng.nextDouble() * 8;
    final after = before + 3 + (rng.nextDouble() - 0.5) * 4;
    cases.add([gain, pre, effort, method, site, rating, before, after]);
  }
  return Dataset(
    name: 'v14',
    variables: [
      Variable(name: 'gain'),
      Variable(name: 'pre'),
      Variable(name: 'effort'),
      Variable(name: 'method', valueLabels: {1: 'D1', 2: 'D2', 3: 'D3'}),
      Variable(name: 'site', valueLabels: {1: 'A', 2: 'B'}),
      Variable(name: 'rating', valueLabels: {1: 'low', 2: 'mid', 3: 'high'}),
      Variable(name: 'before'),
      Variable(name: 'after'),
    ],
    cases: cases,
  );
}

/// 直接读列（按数据行顺序），供「独立预期值」使用。
List<num?> _col(String name) {
  final ds = datasetStore.data;
  final i = ds.indexOf(name);
  return [for (final row in ds.cases) i < row.length ? row[i] as num? : null];
}

String _label(String name, num v) {
  final ds = datasetStore.data;
  return ds.variables[ds.indexOf(name)].displayValue(v);
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    datasetStore.replace(_v14Dataset());
  });

  Future<void> open(WidgetTester tester, String id) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(560, 4200);
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

  Future<void> pick(WidgetTester tester, int index, String value) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  Future<void> run(WidgetTester tester) async {
    await tester.tap(find.text(l10n.runAnalysis));
    await tester.pumpAndSettle();
  }

  testWidgets('有序趋势检验：J、Z、双侧/单侧 p 与分组汇总', (tester) async {
    await open(tester, 'jt_trend');
    await chip(tester, 'gain');
    await pick(tester, 0, 'method');
    await run(tester);

    // 独立预期值：按值标签顺序（D1 → D2 → D3）分组
    final gain = _col('gain');
    final method = _col('method');
    final groups = [
      for (final code in [1, 2, 3])
        [
          for (var i = 0; i < gain.length; i++)
            if (method[i] == code) gain[i]!.toDouble()
        ]
    ];
    final expected = NparExtended.jonckheereTerpstra(groups);
    final pOne = expected.extra['pOneTail'] as double;

    expect(expected.p, lessThan(0.05), reason: '数据应能被检验出趋势');
    expect(find.text(l10n.jtTitle), findsWidgets);
    expect(find.text(l10n.pTwoTail), findsOneWidget);
    expect(find.text(l10n.pOneTail), findsOneWidget);
    expect(find.text(formatNum(expected.statistic)), findsWidgets);
    expect(find.text(formatNum(expected.z!)), findsWidgets);
    expect(find.text(formatP(expected.p)), findsWidgets);
    expect(find.text(formatP(pOne)), findsWidgets);
    // 分组汇总里出现组标签与样本量
    for (final label in ['D1', 'D2', 'D3']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text(l10n.jtNote), findsOneWidget);
  });

  testWidgets('置换检验 · 独立样本：观察值、单双侧 p 与置换分布', (tester) async {
    await open(tester, 'permutation');
    await chip(tester, 'gain');
    await pick(tester, 0, 'site');
    await run(tester);

    // 独立预期值：按数据里首次出现的顺序取两组（A 先于 B）
    final gain = _col('gain');
    final site = _col('site');
    final first = <double>[], second = <double>[];
    final seen = <num>{};
    for (var i = 0; i < gain.length; i++) {
      final s = site[i]!;
      if (seen.isEmpty || seen.first == s) {
        first.add(gain[i]!.toDouble());
        seen.add(s);
      } else {
        second.add(gain[i]!.toDouble());
      }
    }
    final expected =
        Permutation.twoSampleMeanDifference(first, second, permutations: 9999);

    expect(find.text(l10n.permTitle), findsWidgets);
    expect(find.text(l10n.observedValue), findsOneWidget);
    expect(find.text(formatNum(expected.observed)), findsWidgets);
    expect(find.text(formatP(expected.pTwoTail)), findsWidgets);
    expect(find.text(formatP(expected.pGreater)), findsWidgets);
    expect(find.text(formatP(expected.pLess)), findsWidgets);
    expect(find.text(formatNum(expected.meanPermuted)), findsWidgets);
    expect(find.text(l10n.permDistribution), findsOneWidget);
    // 种子固定 → 结果可复现；备注里写清置换次数与随机模式
    expect(
      find.text(l10n.permRunInfo(9999, '${expected.seed}', l10n.permRandom)),
      findsOneWidget,
    );
  });

  testWidgets('置换检验 · 配对样本：切换到配对设计后按两个变量运行', (tester) async {
    await open(tester, 'permutation');
    await tester.tap(find.text(l10n.permPaired));
    await tester.pumpAndSettle();
    await chip(tester, 'before');
    await chip(tester, 'after');
    await run(tester);

    final expected = Permutation.pairedDifference(
      _col('before').map((v) => v!.toDouble()).toList(),
      _col('after').map((v) => v!.toDouble()).toList(),
      permutations: 9999,
    );
    expect(find.text(l10n.permTitle), findsWidgets);
    expect(find.text(formatNum(expected.observed)), findsWidgets);
    expect(find.text(formatP(expected.pTwoTail)), findsWidgets);
    expect(find.text(l10n.permPaired), findsWidgets);
  });

  testWidgets('协方差分析：类型 III 表 + 协变量斜率 + 调整均值', (tester) async {
    await open(tester, 'ancova');
    await pick(tester, 0, 'gain'); // 因变量
    await pick(tester, 1, 'method'); // 因子 A
    await chip(tester, 'pre'); // 协变量
    await run(tester);

    // 独立预期值：与运行页同样的整行装配（本数据无缺失）
    final gain = _col('gain');
    final method = _col('method');
    final expected = ancova(
      y: [for (final v in gain) v!.toDouble()],
      a: [for (final v in method) _label('method', v!)],
      covariates: {
        'pre': [for (final v in _col('pre')) v!.toDouble()]
      },
      yName: 'gain',
      aName: 'method',
    );

    expect(find.text(l10n.ancovaTitle), findsWidgets);
    expect(find.text(l10n.typeIiiSs), findsOneWidget);
    expect(find.text(l10n.covariateSlopes), findsOneWidget);
    expect(find.text(l10n.adjustedMeans), findsOneWidget);
    // 因子项：SS / F / p / 偏 η²（效应量）都要能引用
    expect(find.text(formatNum(expected.terms[0].ss)), findsWidgets);
    expect(find.text(formatP(expected.terms[0].p)), findsWidgets);
    expect(find.text(formatNum(expected.terms[0].partialEta2)), findsWidgets);
    // 协变量斜率（原始尺度）+ 置信区间
    expect(find.text(formatNum(expected.slopes[0].b)), findsWidgets);
    expect(find.text(formatNum(expected.slopes[0].se)), findsWidgets);
    // 调整均值与原始均值都给出
    expect(find.text(formatNum(expected.means[0].adjusted)), findsWidgets);
    expect(find.text(formatNum(expected.means[0].raw)), findsWidgets);
    expect(find.text(l10n.rawMean), findsOneWidget);
    expect(find.text(l10n.adjustedMean), findsOneWidget);
    // 斜率应恢复真值 0.25（±0.1）
    expect(expected.slopes[0].b, closeTo(0.25, 0.1));
    expect(expected.terms[0].p, lessThan(0.05), reason: '分组差异应显著');
  });

  testWidgets('多项 logistic：系数表、似然比检验、混淆矩阵', (tester) async {
    await open(tester, 'multinomial');
    await pick(tester, 0, 'rating');
    await chip(tester, 'pre');
    await chip(tester, 'effort');
    await run(tester);

    // 独立预期值：类别码按值标签顺序（low=1, mid=2, high=3），参考类别 = high
    final rating = _col('rating');
    final codes = [for (final v in rating) v!.toInt()];
    expect(codes.toSet().length, 3, reason: '三类都要出现，参考类别才有观测');
    final expected = multinomialLogistic(
      [
        [for (final v in _col('pre')) v!.toDouble()],
        [for (final v in _col('effort')) v!.toDouble()],
      ],
      codes,
      names: ['pre', 'effort'],
      levelLabels: ['low', 'mid', 'high'],
    );

    expect(expected.converged, isTrue);
    expect(find.text(l10n.multinomialTitle), findsWidgets);
    expect(find.text(l10n.waldCoefficients), findsOneWidget);
    expect(find.text(l10n.multinomialFit), findsOneWidget);
    expect(find.text(l10n.confusionMatrix), findsOneWidget);
    expect(find.text(formatNum(expected.pseudoR2)), findsWidgets);
    expect(find.text(formatNum(expected.lrChi)), findsWidgets);
    expect(find.text(formatP(expected.lrP)), findsWidgets);
    expect(find.text('${(expected.accuracy * 100).toStringAsFixed(1)}%'),
        findsWidgets);
    // 参考类别与两类方程都出现在系数表里
    expect(
      find.text(l10n.multinomialNote(
          expected.reference, formatNum(expected.pseudoR2), expected.n)),
      findsOneWidget,
    );
    // 至少有一项达到显著（数据里对协变量有真实信号）
    expect(expected.lrP, lessThan(0.05));
  });

  testWidgets('正态性报告同时给出 Lilliefors 与 Kolmogorov 两个 p', (tester) async {
    await open(tester, 'normality');
    await chip(tester, 'gain');
    await run(tester);

    final r = normalityTest([
      for (final v in _col('gain')) v!.toDouble()
    ]);
    expect(find.text(l10n.pKolmogorov), findsOneWidget);
    expect(find.text(formatP(r.p)), findsWidgets);
    expect(find.text(formatP(r.pKolmogorovAsymptotic)), findsWidgets);
    // 参数被估计时 Lilliefors p 不会大于 Kolmogorov 渐近 p
    expect(r.p, lessThanOrEqualTo(r.pKolmogorovAsymptotic + 1e-12));
  });
}

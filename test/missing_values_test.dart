/// 用户缺失值口径（v1.4.0 M5，规则 A–E）：
/// 变量自身的用户缺失值（离散值 / 缺失范围）在全部过程的口径与个案对齐。
///
/// 口径定义见 `lib/core/io/missing_aware.dart` 顶部注释。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/io/missing_aware.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';

/// 造一个带用户缺失值的表（4 个变量各有 1 个用户缺失值，位置互不相同）：
///
///   | 个案 | pre | post | grp |  w |
///   |-----|-----|------|-----|----|
///   | 1   | 10  | 11   | 1   | 1  |
///   | 2   | 12  | 13   | 1   | 1  |
///   | 3   | 99* | 15   | 1   | 1  |
///   | 4   | 14  | 98*  | 2   | 1  |
///   | 5   | 16  | 17   | 2   | 2  |
///   | 6   | 18  | 19   | 2   | 2  |
///   | 7   | 20  | 21   | 99* | 9* |
///   | 8   | 22  | 23   | 2   | 2  |
///
/// `*` = 该变量的用户缺失值（99 / 98 / 99 / 9）。
Dataset _fixture() {
  final d = Dataset(name: 'miss');
  d.addVariable(Variable(name: 'id', decimals: 0));
  d.addVariable(Variable(name: 'pre', missingValues: [99]));
  d.addVariable(Variable(name: 'post', missingValues: [98]));
  d.addVariable(Variable(name: 'grp', decimals: 0, missingValues: [99]));
  d.addVariable(Variable(name: 'w', missingValues: [9]));
  const pre = [10, 12, 99, 14, 16, 18, 20, 22];
  const post = [11, 13, 15, 98, 17, 19, 21, 23];
  const grp = [1, 1, 1, 2, 2, 2, 99, 2];
  const w = [1, 1, 1, 1, 2, 2, 9, 2];
  for (var i = 0; i < 8; i++) {
    d.addCase([i + 1, pre[i], post[i], grp[i], w[i]]);
  }
  return d;
}

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(const Color(0xFF2F6FED)),
      home: home,
    );

void main() {
  group('规则 A：单变量排除用户缺失值', () {
    test('numericColumn / MissingAware.numeric 都用变量自身的缺失规则', () {
      final d = _fixture();
      expect(MissingAware.numeric(d, 'pre'), [10, 12, 14, 16, 18, 20, 22]);
      expect(d.numericColumn('pre'), [10, 12, 14, 16, 18, 20, 22]);
      expect(MissingAware.numeric(d, 'grp'), [1, 1, 1, 2, 2, 2, 2]);
    });

    test('缺失范围（LOW..HIGH）也算缺失，边界值包含在内', () {
      final d = Dataset(name: 'r');
      d.addVariable(Variable(
        name: 'v',
        missingValues: [9],
        missingRangeLow: 90,
        missingRangeHigh: 99,
      ));
      for (final v in [1, 9, 90, 95, 99, 100]) {
        d.addCase([v]);
      }
      expect(MissingAware.numeric(d, 'v'), [1, 100]);
    });

    test('rawColumn 保留原值，MissingAware.raw 把用户缺失值记为 null', () {
      final d = _fixture();
      expect(d.rawColumn('pre'), [10, 12, 99, 14, 16, 18, 20, 22]);
      final raw = MissingAware.raw(d, 'pre');
      expect(raw.length, 8);
      expect(raw[2], isNull);
      expect(raw.where((e) => e == null).length, 1);
    });
  });

  group('规则 B：多变量按个案对齐（成对删除 / 完全案例）', () {
    test('pairs 成对删除，两列严格按个案对齐', () {
      final d = _fixture();
      final (pre, post) = MissingAware.pairs(d, 'pre', 'post');
      expect(pre, [10, 12, 16, 18, 20, 22]);
      expect(post, [11, 13, 17, 19, 21, 23]);
      expect(pre.length, post.length);
    });

    test('独立取列再按位置配对是错的（旧口径会错位）', () {
      final d = _fixture();
      final a = d.numericColumn('pre');
      final b = d.numericColumn('post');
      final (x, y) = MissingAware.pairs(d, 'pre', 'post');
      expect(x.length, lessThan(a.length));
      // 旧口径把第 3 个位置配成 (14, 15)，但那两个值来自不同个案
      expect([a[2], b[2]], [14, 15]);
      expect([x[2], y[2]], [16, 17]);
    });

    test('alignedNumeric 多列取同一批个案、长度一致', () {
      final d = _fixture();
      final cols = MissingAware.alignedNumeric(d, ['pre', 'post', 'w']);
      // w 在第 7 个个案缺失 → 该个案整行剔除，剩 5 个个案
      expect(cols.map((c) => c.length).toSet(), {5});
      expect(cols[0], [10, 12, 16, 18, 22]);
      expect(cols[1], [11, 13, 17, 19, 23]);
      expect(cols[2], [1, 1, 2, 2, 2]);
    });

    test('成对 t 检验与相关都只用成对完整个案', () {
      final d = _fixture();
      final (pre, post) = MissingAware.pairs(d, 'pre', 'post');
      final t = TTest.paired(pre, post);
      expect(t.n1, 6);
      expect(t.n2, 6);
      expect(t.df, 5);
      expect(Correlation.pearson(pre, post).n, 6);
    });
  });

  group('规则 C：加权时权重变量的缺失也剔除', () {
    test('weighted 取（值, 权重）都有效的个案', () {
      final d = _fixture();
      final (v, w) = MissingAware.weighted(d, 'pre', 'w');
      // pre 在第 3 个个案缺失、w 在第 7 个个案缺失 → 剩 6 个个案
      expect(v, [10, 12, 14, 16, 18, 22]);
      expect(w, [1, 1, 1, 2, 2, 2]);
      final wd = WeightedDescriptives.compute(v, w);
      expect(wd.nWeighted, closeTo(9, 1e-9));
      expect(
          wd.mean, closeTo((10 + 12 + 14 + 16 * 2 + 18 * 2 + 22 * 2) / 9, 1e-9));
    });
  });

  group('规则 D：分组变量缺失的个案不进任何一组', () {
    test('groups 既剔除分组变量缺失，也剔除分析变量缺失', () {
      final d = _fixture();
      final g = MissingAware.groups(d, 'pre', 'grp');
      expect(g.keys.toList(), ['1', '2']); // 99 不成为第三个组
      expect(g['1'], [10, 12]); // 第 3 个个案 pre 缺失
      expect(g['2'], [14, 16, 18, 22]); // 第 7 个个案 grp 缺失
      expect(g.values.expand((e) => e).length, 6);
    });

    test('组标签用值标签', () {
      final d = _fixture();
      d.variables[3].valueLabels.addAll({1: '对照', 2: '处理'});
      final g = MissingAware.groups(d, 'pre', 'grp');
      expect(g.keys.toList(), ['对照', '处理']);
      expect(g['处理'], [14, 16, 18, 22]);
    });
  });

  group('规则 E：分类过程把用户缺失值计为缺失', () {
    test('频数不计入类别，计入缺失', () {
      final d = _fixture();
      final valid = Frequencies.compute(d.rawColumn('grp'), variableName: 'grp');
      final aware =
          Frequencies.compute(MissingAware.raw(d, 'grp'), variableName: 'grp');
      // 不加口径时 99 是一个类别
      expect(valid.rows.map((e) => e.label).join(','), contains('99'));
      expect(valid.nMissing, 0);
      // 统一口径后 99 记为缺失，类别只剩 1 / 2
      expect(aware.rows.length, 2);
      expect(aware.nMissing, 1);
      expect(aware.nValid, 7);
    });
  });

  group('分析页集成（成对 t 检验按个案对齐）', () {
    testWidgets('成对 t 检验的 N 用成对完整个案数，而不是各自取列后截断',
        (tester) async {
      datasetStore.replace(_fixture());
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 1400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(
        const AnalysisRunner(analysisId: 'ttest_paired', title: 'Paired'),
      ));
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.widgetWithText(FilterChip, 'pre'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Run analysis'));
      await tester.pumpAndSettle();

      // 8 个个案里 pre 缺 1 个、post 缺 1 个（位置不同）→ 成对完整个案 6 个
      expect(find.text('6'), findsWidgets);
      expect(find.text('7'), findsNothing);
      expect(find.text('5.0'), findsWidgets); // df = 6 - 1
    });
  });
}

/// 与 PSPP 2.1.2 自带测试用例对拍（v1.4.0 M5.2）。
///
/// 本机没有 PSPP 可执行文件，期望数值直接取自 PSPP 源码树里的**期望输出**
/// （本地 `_ref/pspp-2.1.2`，不入库），逐条注明出处；对应的 `.sps` 样例放在
/// `_internal/pspp-parity/`（不入库，本机装 PSPP 后可手跑核对），本文件把期望
/// 数值固化进 CI，让「与 PSPP 对拍」在 CI 上也能跑。
///
/// 出处：
/// - `tests/language/commands/autorecode.at`（AUTORECODE multiple missing values）
/// - `tests/language/commands/rank.at`（RANK simple case with defaults；
///   RANK ... /TIES=HIGH 的 b)
/// - `tests/language/commands/oneway.at`（ONEWAY basic operation；
///   ONEWAY with missing values）
/// - `tests/language/commands/correlations.at`（CORRELATIONS -- unweighted，
///   `/MISSING=PAIRWISE` 那三张表的 N 与 r）
///
/// 已登记的口径差异（非缺陷）：
/// 1. RANK 的缺失个案：PSPP 2.1.2 在 `rank.at` 的 `a` 列把一个**行首**缺失值
///    也排到了最后（给了秩 10），而同一用例的 `b` 列（缺失在中间）不给秩 ——
///    PSPP 自己不一致；本应用按 SPSS 通行的做法（缺失不给秩，结果为空），
///    与 `b` 列一致。
/// 2. 相关系数按 PSPP / SPSS 默认的**成对删除**（`/MISSING=PAIRWISE`）取值，
///    与 `correlations.at` 第三张表（带 N 的那张）一致。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/io/missing_aware.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/transforms/transforms.dart';

/// 期望值按 PSPP 打印精度比较（PSPP 打印 2~3 位小数）。
void expectNum(double actual, double expected, {int digits = 2}) {
  final tol = 0.5 * (digits == 3 ? 0.001 : 0.01) + 1e-9;
  expect(actual, closeTo(expected, tol),
      reason: 'PSPP 期望 $expected（$digits 位小数）');
}

/// PSPP `autorecode.at`「AUTORECODE multiple missing values」的输入：
/// 六个变量各自取 11..16，缺失声明覆盖「单个值 / 两个值 / 三个值 / 缺失范围」
/// 四种写法。
Dataset _autorecodeFixture() {
  final d = Dataset(name: 'autorecode');
  d.addVariable(Variable(name: 'u', decimals: 0, missingValues: [11]));
  d.addVariable(Variable(name: 'v', decimals: 0, missingValues: [11, 12]));
  d.addVariable(Variable(name: 'w', decimals: 0, missingValues: [11, 12, 13]));
  d.addVariable(
      Variable(name: 'x', decimals: 0, missingRangeLow: 11, missingRangeHigh: 14));
  d.addVariable(
      Variable(name: 'y', decimals: 0, missingRangeLow: 11, missingRangeHigh: 15));
  d.addVariable(
      Variable(name: 'z', decimals: 0, missingRangeLow: 11, missingRangeHigh: 16));
  for (var i = 11; i <= 16; i++) {
    d.addCase([i, i, i, i, i, i]);
  }
  return d;
}

/// PSPP `oneway.at`「ONEWAY basic operation」的输入：
/// quality（Breaking Strain）按 brand（Manufacturer）1/2/3 分三组，各 5 例。
Dataset _onewayFixture() {
  final d = Dataset(name: 'oneway');
  d.addVariable(Variable(name: 'quality'));
  d.addVariable(Variable(name: 'brand', decimals: 0));
  const rows = [
    [7, 3],
    [4, 3],
    [3, 1],
    [2, 1],
    [1, 1],
    [4, 2],
    [2, 2],
    [3, 2],
    [5, 3],
    [1, 1],
    [4, 1],
    [5, 2],
    [2, 2],
    [3, 3],
    [6, 3],
  ];
  for (final r in rows) {
    d.addCase([r[0], r[1]]);
  }
  return d;
}

void main() {
  group('PSPP 对拍 · AUTORECODE（autorecode.at：multiple missing values）', () {
    test('编码表：非缺失值升序编号，用户缺失值恒排最后', () {
      final d = _autorecodeFixture();
      Transforms.autorecode(
        d,
        sourceVars: ['u', 'v', 'w', 'x', 'y', 'z'],
        targetVars: ['a', 'b', 'c', 'd', 'e', 'f'],
      );
      // PSPP「Table: Data List」六行
      expect(d.rawColumn('a'), [6, 1, 2, 3, 4, 5]);
      expect(d.rawColumn('b'), [5, 6, 1, 2, 3, 4]);
      expect(d.rawColumn('c'), [4, 5, 6, 1, 2, 3]);
      expect(d.rawColumn('d'), [3, 4, 5, 6, 1, 2]);
      expect(d.rawColumn('e'), [2, 3, 4, 5, 6, 1]);
      expect(d.rawColumn('f'), [1, 2, 3, 4, 5, 6]);
    });

    test('目标变量的缺失标记：≤3 个用离散值，>3 个用缺失范围', () {
      final d = _autorecodeFixture();
      Transforms.autorecode(
        d,
        sourceVars: ['u', 'v', 'w', 'x', 'y', 'z'],
        targetVars: ['a', 'b', 'c', 'd', 'e', 'f'],
      );
      // PSPP「Table: Variables / Missing Values」列
      expect(d.variables[d.indexOf('a')].missingValues, [6]);
      expect(d.variables[d.indexOf('b')].missingValues, [5, 6]);
      expect(d.variables[d.indexOf('c')].missingValues, [4, 5, 6]);
      for (final (name, low, high) in [
        ('d', 3, 6),
        ('e', 2, 6),
        ('f', 1, 6),
      ]) {
        final v = d.variables[d.indexOf(name)];
        expect(v.missingValues, isEmpty, reason: '$name 用缺失范围');
        expect(v.missingRangeLow, low, reason: '$name 缺失范围下界');
        expect(v.missingRangeHigh, high, reason: '$name 缺失范围上界');
      }
    });

    test('编码后的取值就是 PSPP 的 1..k，且原值标签回填', () {
      final d = _autorecodeFixture();
      Transforms.autorecode(
        d,
        sourceVars: ['u'],
        targetVars: ['a'],
      );
      final a = d.variables[d.indexOf('a')];
      expect(a.valueLabels[1], '12');
      expect(a.valueLabels[6], '11');
    });
  });

  group('PSPP 对拍 · RANK（rank.at）', () {
    test('RANK simple case with defaults：结取平均秩', () {
      final d = Dataset(name: 'rank');
      d.addVariable(Variable(name: 'x'));
      for (final v in [-1, 0, 1, 2, 2, 4, 5]) {
        d.addCase([v]);
      }
      Transforms.rank(d, sourceVar: 'x');
      expect(d.rawColumn('R_x'), [1.0, 2.0, 3.0, 4.5, 4.5, 6.0, 7.0]);
    });

    test('/TIES=HIGH + 降序：结取较大的秩号（对齐 PSPP 的 b 列）', () {
      final d = Dataset(name: 'rank2');
      d.addVariable(Variable(name: 'b'));
      for (final v in [24, 32, 31, 32, 30, 29, 1, 43, 45]) {
        d.addCase([v]);
      }
      Transforms.rank(d,
          sourceVar: 'b', descending: true, ties: RankTies.high);
      // PSPP rank.at 的 b 列：[8,4,5,4,6,7,9,2,1]（结 32/32 取较大的秩号 4）
      expect(d.rawColumn('R_b'),
          [8.0, 4.0, 5.0, 4.0, 6.0, 7.0, 9.0, 2.0, 1.0]);
    });

    test('缺失个案不给秩（PSPP 的 a 列是 PSPP 自身的不一致，不跟随）', () {
      final d = Dataset(name: 'rank3');
      d.addVariable(Variable(name: 'a'));
      for (final v in <num?>[null, 1, 2, 2, 4, 5, 6, 7, 8, 9]) {
        d.addCase([v]);
      }
      Transforms.rank(d,
          sourceVar: 'a', descending: true, ties: RankTies.high);
      // PSPP 的非缺失部分：[.,1,2,2,4,5,6,7,8,9] -> [-,9,8,8,6,5,4,3,2,1]
      expect(d.rawColumn('R_a'),
          [null, 9.0, 8.0, 8.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0]);
    });
  });

  group('PSPP 对拍 · ONEWAY（oneway.at）', () {
    test('basic operation：组描述、Levene、ANOVA 平方和与 F', () {
      final d = _onewayFixture();
      final groups = MissingAware.groups(d, 'quality', 'brand');
      final r = OnewayAnova.compute(
        [groups['1']!, groups['2']!, groups['3']!],
        labels: ['Aspeger', 'Bloggs', 'Charlies'],
      );
      // Table: Descriptives
      expect(r.groups[0].n, 5);
      expect(r.groups[1].n, 5);
      expect(r.groups[2].n, 5);
      expectNum(r.groups[0].mean, 2.20);
      expectNum(r.groups[1].mean, 3.20);
      expectNum(r.groups[2].mean, 5.00);
      expectNum(r.groups[0].sd, 1.30);
      expectNum(r.groups[1].sd, 1.30);
      expectNum(r.groups[2].sd, 1.58);
      expect(r.nTotal, 15);
      expectNum(r.grandMean, 3.47);
      // Table: Test of Homogeneity of Variances
      expectNum(r.levene.f, 0.09);
      expect(r.levene.df1, 2);
      expect(r.levene.df2, 12);
      expect(r.levene.p, closeTo(0.913, 0.001));
      // Table: ANOVA
      expectNum(r.ssBetween, 20.13);
      expect(r.dfBetween, 2);
      expectNum(r.msBetween, 10.07);
      expectNum(r.f, 5.12);
      expect(r.p, closeTo(0.025, 0.001));
      expectNum(r.ssWithin, 23.60);
      expect(r.dfWithin, 12);
      expectNum(r.msWithin, 1.97);
      expectNum(r.ssTotal, 43.73);
    });

    test('ONEWAY with missing values：缺失个案被剔除，结果与 basic 相同', () {
      // oneway.at「ONEWAY with missing values」的 oneway-missing1.sps：
      // v1 第 1 个个案缺失（这里用用户缺失值 99 表示，等效于 PSPP 的系统缺失）
      final d = Dataset(name: 'oneway-missing');
      d.addVariable(Variable(name: 'v1', missingValues: [99]));
      d.addVariable(Variable(name: 'dep', decimals: 0));
      const v1 = <num>[99, 3, 2, 1, 1, 4, 5, 2, 4, 2, 3, 7, 4, 5, 3, 6];
      const dep = [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3];
      for (var i = 0; i < v1.length; i++) {
        d.addCase([v1[i], dep[i]]);
      }
      final groups = MissingAware.groups(d, 'v1', 'dep');
      expect(groups.keys.toList(), ['1', '2', '3']);
      expect(groups['1'], [3, 2, 1, 1, 4]);
      expect(groups['2'], [5, 2, 4, 2, 3]);
      expect(groups['3'], [7, 4, 5, 3, 6]);
      final r = OnewayAnova.compute(
        [groups['1']!, groups['2']!, groups['3']!],
      );
      expect(r.nTotal, 15); // 16 个个案减掉 1 个缺失
      expectNum(r.f, 5.12);
      expectNum(r.ssBetween, 20.13);
      expectNum(r.ssWithin, 23.60);
      expect(r.dfWithin, 12);
    });

    test('独立变量（分组变量）缺失的个案整体剔除，不进入任何一组', () {
      // oneway.at「... missing values in the independent variable」（missing3）
      final d = Dataset(name: 'oneway-missing-iv');
      d.addVariable(Variable(name: 'v1'));
      d.addVariable(Variable(name: 'dep', decimals: 0, missingValues: [99]));
      const v1 = <num>[4, 3, 2, 1, 1, 4, 5, 2, 4, 2, 3, 7, 4, 5, 3, 6];
      const dep = <num>[99, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3];
      for (var i = 0; i < v1.length; i++) {
        d.addCase([v1[i], dep[i]]);
      }
      final groups = MissingAware.groups(d, 'v1', 'dep');
      expect(groups.keys.toList(), ['1', '2', '3']);
      expect(groups['1']!.length, 5);
      expect(groups['2']!.length, 5);
      expect(groups['3']!.length, 5);
      final r = OnewayAnova.compute(
        [groups['1']!, groups['2']!, groups['3']!],
      );
      expectNum(r.f, 5.12);
      expect(r.nTotal, 15);
    });
  });

  group('PSPP 对拍 · CORRELATIONS（correlations.at：/MISSING=PAIRWISE）', () {
    // correlations.at「CORRELATIONS -- unweighted」输入（foo 第 7 例、bang 第 8 例缺失）
    const foo = <num?>[1, 3, 3, 4, 98, 3, null, 5];
    const bar = <num?>[0, 9, 4, -9, 78, 50, 4, 3];
    const wiz = <num?>[3, -50, 3, 0, 104, -49, 4, 0];
    const bang = <num?>[1, 5, 203, -4, 2, 200, 4, null];

    late Dataset d;
    setUp(() {
      d = Dataset(name: 'corr');
      for (final name in ['foo', 'bar', 'wiz', 'bang']) {
        d.addVariable(Variable(name: name));
      }
      for (var i = 0; i < 8; i++) {
        d.addCase([foo[i], bar[i], wiz[i], bang[i]]);
      }
    });

    test('成对删除：每一对的 N 与 r 与 PSPP 第三张表一致', () {
      // 期望值 = PSPP 第三张表：r 与 N
      const expected = <(String, String, double, int)>[
        ('foo', 'bar', 0.805, 7),
        ('foo', 'wiz', 0.883, 7),
        ('foo', 'bang', -0.308, 6),
        ('bar', 'wiz', 0.497, 8),
        ('bar', 'bang', 0.164, 7),
        ('wiz', 'bang', -0.337, 7),
      ];
      for (final (a, b, r, n) in expected) {
        final (x, y) = MissingAware.pairs(d, a, b);
        final c = Correlation.pearson(x, y);
        expect(c.n, n, reason: '$a-$b 的 N');
        expectNum(c.r, r, digits: 3);
      }
    });

    test('对角线 N 就是该变量自身的有效个案数（PSPP 的 N 行）', () {
      final (x, _) = MissingAware.pairs(d, 'foo', 'bar');
      expect(Correlation.pearson(MissingAware.numeric(d, 'foo'), MissingAware.numeric(d, 'foo')).n, 7);
      expect(x.length, 7);
      expect(MissingAware.numeric(d, 'bar').length, 8);
      expect(MissingAware.numeric(d, 'bang').length, 7);
    });
  });
}

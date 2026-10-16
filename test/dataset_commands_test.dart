/// v1.4.0 M2 数据层命令的单元测试。
///
/// 语义参考 PSPP 2.1.2 源码（`_ref/pspp-2.1.2/src/language/commands/*.c`）：
/// - RANK：`rank.c`（秩、N、RFRACTION、PROPORTION、PERCENT、NORMAL、NTILES + 结处理）
/// - AUTORECODE：`autorecode.c`（取值 → 1..k 码 + 自动值标签）
/// - SAMPLE：`sample.c`（按比例 / n FROM N）
/// - MRSETS：`mrsets.c`（多选集定义与显示）
///
/// 每个命令同时给「直接调用 Transforms / MRSets」与「走语法动词」两条路径的断言。
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/models/mrset.dart';
import 'package:stats_flutter/core/models/project.dart';
import 'package:stats_flutter/core/syntax/syntax_engine.dart';
import 'package:stats_flutter/core/transforms/combine_files.dart';
import 'package:stats_flutter/core/transforms/transforms.dart';

Dataset _ds(List<String> names, List<List<Object?>> cases) {
  final d = Dataset(name: 'test');
  for (final n in names) {
    d.addVariable(Variable(name: n));
  }
  for (final row in cases) {
    d.addCase(List<Object?>.of(row));
  }
  return d;
}

/// 原始列（保留 null，便于逐个案比对）
List<Object?> _col(Dataset d, String name) => d.rawColumn(name);

List<double?> _numCol(Dataset d, String name) =>
    [for (final v in _col(d, name)) v == null ? null : (v as num).toDouble()];

/// 造一个 id 从 1 到 [n] 的数据集（SAMPLE 用）
Dataset _ids(int n) {
  final d = Dataset(name: 'test');
  d.addVariable(Variable(name: 'id', decimals: 0));
  for (var i = 1; i <= n; i++) {
    d.addCase([i]);
  }
  return d;
}

/// 多选集用的调查数据集：
/// - act1..act5：二分变量（1 = 选中），带变量标签「活动i」；
/// - subj1..subj3：分类法组的多个响应（同一分类问题的宽格式），
///   值标签 1 语文 / 2 数学 / 3 英语；
/// - gender：1 男 / 2 女。
///
/// 个案（act1..act5 | subj1..subj3 | gender）：
///   1: 1 0 1 0 0 | 1 2 .        | 1
///   2: 0 0 1 1 0 | 3 . .        | 2
///   3: 1 1 0 0 0 | 2 2 .        | 1
///   4: 0 0 0 0 0 | . . .        | 2
Dataset _survey() {
  final d = Dataset(name: 'survey');
  for (var i = 1; i <= 5; i++) {
    d.addVariable(Variable(
      name: 'act$i',
      label: '活动$i',
      decimals: 0,
      measure: MeasureLevel.nominal,
    ));
  }
  for (var i = 1; i <= 3; i++) {
    d.addVariable(Variable(
      name: 'subj$i',
      label: '科目$i',
      decimals: 0,
      measure: MeasureLevel.nominal,
      valueLabels: const {1: '语文', 2: '数学', 3: '英语'},
    ));
  }
  d.addVariable(Variable(
    name: 'gender',
    label: '性别',
    decimals: 0,
    measure: MeasureLevel.nominal,
    valueLabels: const {1: '男', 2: '女'},
  ));
  d.addCase([1, 0, 1, 0, 0, 1, 2, null, 1]);
  d.addCase([0, 0, 1, 1, 0, 3, null, null, 2]);
  d.addCase([1, 1, 0, 0, 0, 2, 2, null, 1]);
  d.addCase([0, 0, 0, 0, 0, null, null, null, 2]);
  return d;
}

/// 定义测试用的两个多选集：二分法组 $act（VALUE=1）与分类法组 $subj
void _defineSurveySets(Dataset d) {
  MRSets.define(
    d,
    name: r'$act',
    type: MrSetType.md,
    variables: ['act1', 'act2', 'act3', 'act4', 'act5'],
    label: '参加的活动',
    counted: 1,
  );
  MRSets.define(
    d,
    name: r'$subj',
    type: MrSetType.mc,
    variables: ['subj1', 'subj2', 'subj3'],
    label: '选考科目',
  );
}

void main() {
  group('RANK 秩', () {
    test('默认平均秩：结取平均，输出变量为序数尺度', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      final r = Transforms.rank(d, sourceVar: 'score');
      expect(r.changed, 5);
      expect(_numCol(d, 'R_score'), [1.0, 2.5, 2.5, 4.0, 5.0]);
      final v = d.variables[d.indexOf('R_score')];
      expect(v.measure, MeasureLevel.ordinal);
      expect(r.message, contains('R_score'));
    });

    test('降序秩', () {
      final d = _ds(['score'], [
        [40], [30], [20], [20], [10],
      ]);
      Transforms.rank(d, sourceVar: 'score', descending: true);
      expect(_numCol(d, 'R_score'), [1.0, 2.0, 3.5, 3.5, 5.0]);
    });

    test('N / RFRACTION / PERCENT（与 PSPP 定义一致）', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(d, sourceVar: 'score', function: RankFunction.n);
      Transforms.rank(d, sourceVar: 'score', function: RankFunction.rFraction);
      Transforms.rank(d, sourceVar: 'score', function: RankFunction.percent);
      // N：同一常数
      expect(_numCol(d, 'N_score'), [5.0, 5.0, 5.0, 5.0, 5.0]);
      // RFRACTION = r / N
      expect(_numCol(d, 'RF_score'), [0.2, 0.5, 0.5, 0.8, 1.0]);
      // PERCENT = r x 100 / N（不是 (r-0.5)/N x 100）
      expect(_numCol(d, 'P_score'), [20.0, 50.0, 50.0, 80.0, 100.0]);
    });

    test('PROPORTION：Blom 绘图位置 (r - 3/8) / (N + 1/4)', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(d, sourceVar: 'score', function: RankFunction.proportion);
      final col = _numCol(d, 'PR_score');
      // 手算：(1-0.375)/5.25、(2.5-0.375)/5.25、(4-0.375)/5.25、(5-0.375)/5.25
      expect(col[0], closeTo(0.625 / 5.25, 1e-12));
      expect(col[1], closeTo(2.125 / 5.25, 1e-12));
      expect(col[3], closeTo(3.625 / 5.25, 1e-12));
      expect(col[4], closeTo(4.625 / 5.25, 1e-12));
    });

    test('NORMAL：Blom 正态得分（与独立实现一致）', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(d, sourceVar: 'score', function: RankFunction.normal);
      final col = _numCol(d, 'Z_score');
      // 期望值由 Python statistics.NormalDist().inv_cdf 独立计算
      // z = Φ⁻¹((r - 0.375) / (5 + 0.25))
      expect(col[0], closeTo(-1.179761, 1e-5));
      expect(col[1], closeTo(-0.241040, 1e-5));
      expect(col[2], closeTo(-0.241040, 1e-5));
      expect(col[3], closeTo(0.497201, 1e-5));
      expect(col[4], closeTo(1.179761, 1e-5));
      // 与库内 normalQuantile 一致（同一公式、同一分位数实现）
      for (var i = 0; i < 5; i++) {
        final r = [1.0, 2.5, 2.5, 4.0, 5.0][i];
        expect(col[i], closeTo(_probitCheck((r - 0.375) / 5.25), 1e-6));
      }
    });

    test('NTILES：floor(秩 x k / (N + 1)) + 1', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(d, sourceVar: 'score',
          function: RankFunction.ntiles, ntiles: 4);
      // floor(r*4/6)+1 → [1, 2, 2, 3, 4]
      expect(_numCol(d, 'NT_score'), [1.0, 2.0, 2.0, 3.0, 4.0]);

      final d2 = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(d2, sourceVar: 'score',
          function: RankFunction.ntiles, ntiles: 2);
      // floor(r*2/6)+1 → [1, 1, 1, 2, 2]
      expect(_numCol(d2, 'NT_score'), [1.0, 1.0, 1.0, 2.0, 2.0]);
    });

    test('TIES=LOW / HIGH / CONDENSE（PSPP rank_rank）', () {
      // 结内个案 {20, 20} 占秩 2、3
      final low = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(low, sourceVar: 'score', ties: RankTies.low);
      expect(_numCol(low, 'R_score'), [1.0, 2.0, 2.0, 4.0, 5.0]);

      final high = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(high, sourceVar: 'score', ties: RankTies.high);
      expect(_numCol(high, 'R_score'), [1.0, 3.0, 3.0, 4.0, 5.0]);

      final condense = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      Transforms.rank(condense, sourceVar: 'score', ties: RankTies.condense);
      expect(_numCol(condense, 'R_score'), [1.0, 2.0, 2.0, 4.0, 5.0]);
    });

    test('缺失值（空值与用户缺失值）不参与，且结果为空', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(name: 'score', missingValues: [99]));
      d.addCase([1]);
      d.addCase([99]);
      d.addCase([3]);
      d.addCase([null]);
      Transforms.rank(d, sourceVar: 'score');
      expect(_numCol(d, 'R_score'), [1.0, null, 2.0, null]);
      // N = 有效个案数 2
      final d2 = Dataset(name: 'test');
      d2.addVariable(Variable(name: 'score', missingValues: [99]));
      d2.addCase([1]);
      d2.addCase([99]);
      d2.addCase([3]);
      Transforms.rank(d2, sourceVar: 'score', function: RankFunction.n);
      expect(_numCol(d2, 'N_score'), [2.0, null, 2.0]);
    });

    test('自定义目标变量名与 N 的三位小数设置', () {
      final d = _ds(['score'], [
        [10], [20],
      ]);
      final r = Transforms.rank(d,
          sourceVar: 'score', targetVar: 'myrank',
          function: RankFunction.percent);
      expect(d.indexOf('myrank'), greaterThan(0));
      expect(_numCol(d, 'myrank'), [50.0, 100.0]);
      expect(r.message, contains('myrank'));
      // 分位组为整数显示，秩与百分位保留 3 位小数
      expect(d.variables[d.indexOf('myrank')].decimals, 3);
    });

    test('重复调用同一目标变量：不新建变量', () {
      final d = _ds(['score'], [
        [10], [20], [30],
      ]);
      final n0 = d.nVars;
      Transforms.rank(d, sourceVar: 'score');
      Transforms.rank(d, sourceVar: 'score');
      expect(d.nVars, n0 + 1);
      expect(_numCol(d, 'R_score'), [1.0, 2.0, 3.0]);
    });

    test('NTILES 参数校验：k >= 1', () {
      final d = _ds(['score'], [
        [10], [20],
      ]);
      expect(
        () => Transforms.rank(d,
            sourceVar: 'score', function: RankFunction.ntiles, ntiles: 0),
        throwsArgumentError,
      );
    });

    test('变量不存在时报错', () {
      final d = _ds(['score'], [
        [10],
      ]);
      expect(() => Transforms.rank(d, sourceVar: 'nope'), throwsArgumentError);
    });
  });

  group('RANK 语法动词', () {
    test('RANK VARIABLES=v /NTILES(4)：生成 NT_ 变量', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      final rs = SyntaxExecutor.run(
          'RANK VARIABLES=score /NTILES(4).', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('NT_score'));
      expect(_numCol(d, 'NT_score'), [1.0, 2.0, 2.0, 3.0, 4.0]);
    });

    test('RANK VARIABLES=v (D) /PERCENT：降序百分位', () {
      final d = _ds(['score'], [
        [10], [20], [30],
      ]);
      final rs = SyntaxExecutor.run(
          'RANK VARIABLES=score (D) /PERCENT.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      // 降序后 10 得秩 3、20 得 2、30 得 1；百分位 = 秩 x 100 / 3
      expect(_numCol(d, 'P_score'), [100.0, 200.0 / 3, 100.0 / 3]);
    });

    test('RANK VARIABLES=a b：一次处理多个变量', () {
      final d = _ds(['a', 'b'], [
        [3, 30], [1, 10], [2, 20],
      ]);
      final rs = SyntaxExecutor.run('RANK VARIABLES=a b /RANK.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(_numCol(d, 'R_a'), [3.0, 1.0, 2.0]);
      expect(_numCol(d, 'R_b'), [3.0, 1.0, 2.0]);
    });

    test('/NORMAL 与 /TIES=HIGH：结取最大秩后换算正态得分', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      final rs = SyntaxExecutor.run(
          'RANK VARIABLES=score /NORMAL /TIES=HIGH.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      final col = _numCol(d, 'Z_score');
      // 结内取秩 3 → p = (3 - 0.375)/5.25 = 0.5 → z = 0
      expect(col[1], closeTo(0.0, 1e-12));
      expect(col[2], closeTo(0.0, 1e-12));
      // 其余与平均秩一致
      expect(col[0], closeTo(-1.179761, 1e-5));
      expect(col[3], closeTo(0.497201, 1e-5));
      expect(col[4], closeTo(1.179761, 1e-5));
    });

    test('未给出变量：报语法错误', () {
      final d = _ds(['score'], [
        [10],
      ]);
      final rs = SyntaxExecutor.run('RANK /NTILES(4).', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('RANK syntax'));
    });

    test('TIES=CONDENSE 与 /RFRACTION', () {
      final d = _ds(['score'], [
        [10], [20], [20], [30], [40],
      ]);
      final rs = SyntaxExecutor.run(
          'RANK VARIABLES=score /RFRACTION /TIES=CONDENSE.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(_numCol(d, 'RF_score'), [0.2, 0.4, 0.4, 0.8, 1.0]);
    });
  });

  group('AUTORECODE 自动编码', () {
    test('字符串取值 → 1..k 数值码 + 自动值标签', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(name: 'method', type: VarType.string));
      for (final v in ['B', 'A', 'C', 'A']) {
        d.addCase([v]);
      }
      final r = Transforms.autorecode(d, sourceVars: ['method']);
      expect(r.changed, 4);
      // 按字典序 A < B < C 编号
      expect(_numCol(d, 'method_n'), [2.0, 1.0, 3.0, 1.0]);
      final dst = d.variables[d.indexOf('method_n')];
      expect(dst.type, VarType.numeric);
      expect(dst.decimals, 0);
      expect(dst.measure, MeasureLevel.nominal);
      expect(dst.valueLabels, {1: 'A', 2: 'B', 3: 'C'});
      expect(r.message, contains('method_n'));
    });

    test('数值变量沿用已有的值标签作为新变量的值标签', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(
        name: 'method',
        measure: MeasureLevel.nominal,
        valueLabels: {1: 'Lecture', 2: 'Inquiry', 3: 'Blended'},
      ));
      for (final v in [3, 1, 2]) {
        d.addCase([v]);
      }
      Transforms.autorecode(d, sourceVars: ['method']);
      expect(_numCol(d, 'method_n'), [3.0, 1.0, 2.0]);
      final dst = d.variables[d.indexOf('method_n')];
      expect(dst.valueLabels, {1: 'Lecture', 2: 'Inquiry', 3: 'Blended'});
    });

    test('降序：大值得小码', () {
      final d = _ds(['score'], [
        [10], [30], [20],
      ]);
      Transforms.autorecode(d, sourceVars: ['score'], descending: true);
      expect(_numCol(d, 'score_n'), [3.0, 1.0, 2.0]);
    });

    test('用户缺失值排最后并被标为缺失', () {
      final d = Dataset(name: 'test');
      d.addVariable(
          Variable(name: 'score', decimals: 0, missingValues: [99]));
      for (final v in [1, 99, 3, null]) {
        d.addCase([v]);
      }
      Transforms.autorecode(d, sourceVars: ['score']);
      // 空值仍为空；99 得到最大码 3
      expect(_numCol(d, 'score_n'), [1.0, 3.0, 2.0, null]);
      final dst = d.variables[d.indexOf('score_n')];
      expect(dst.missingValues, [3.0]);
      expect(dst.valueLabels[3], '99');
    });

    test('用户缺失值超过 3 个时改用缺失范围', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(name: 'score', missingValues: [96, 97, 98, 99]));
      for (final v in [1, 96, 97, 98, 99]) {
        d.addCase([v]);
      }
      Transforms.autorecode(d, sourceVars: ['score']);
      final dst = d.variables[d.indexOf('score_n')];
      expect(_numCol(d, 'score_n'), [1.0, 2.0, 3.0, 4.0, 5.0]);
      expect(dst.missingValues, isEmpty);
      expect(dst.missingRangeLow, 2);
      expect(dst.missingRangeHigh, 5);
      // 编码后的缺失值确实被判为缺失
      expect(dst.isMissing(2.0), isTrue);
      expect(dst.isMissing(1.0), isFalse);
    });

    test('多个源变量与自定义目标名', () {
      final d = _ds(['a', 'b'], [
        [3, 30], [1, 10], [2, 20],
      ]);
      final r = Transforms.autorecode(d,
          sourceVars: ['a', 'b'], targetVars: ['an', 'bn']);
      expect(_numCol(d, 'an'), [3.0, 1.0, 2.0]);
      expect(_numCol(d, 'bn'), [3.0, 1.0, 2.0]);
      expect(r.changed, 6);
      expect(r.message, contains('an'));
    });

    test('GROUP：所有源变量共用一张编码表', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(name: 'a', type: VarType.string));
      d.addVariable(Variable(name: 'b', type: VarType.string));
      d.addCase(['A', 'B']);
      d.addCase(['B', 'C']);
      Transforms.autorecode(d, sourceVars: ['a', 'b'], group: true);
      expect(_numCol(d, 'a_n'), [1.0, 2.0]);
      expect(_numCol(d, 'b_n'), [2.0, 3.0]);
    });

    test('参数与命名校验', () {
      final d = _ds(['a', 'b'], [
        [1, 2],
      ]);
      expect(
          () => Transforms.autorecode(d, sourceVars: []), throwsArgumentError);
      expect(
        () => Transforms.autorecode(d,
            sourceVars: ['a', 'b'], targetVars: ['only']),
        throwsArgumentError,
      );
      expect(() => Transforms.autorecode(d, sourceVars: ['nope']),
          throwsArgumentError);
      // 目标名与源名相同时原地编码
      Transforms.autorecode(d, sourceVars: ['a'], targetVars: ['a']);
      expect(_numCol(d, 'a'), [1.0]);
      expect(d.variables[d.indexOf('a')].decimals, 0);
    });
  });

  group('AUTORECODE 语法动词', () {
    test('VARIABLES + INTO', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(name: 'method', type: VarType.string));
      for (final v in ['B', 'A', 'C']) {
        d.addCase([v]);
      }
      final rs = SyntaxExecutor.run(
          'AUTORECODE VARIABLES=method /INTO=code.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('code'));
      expect(_numCol(d, 'code'), [2.0, 1.0, 3.0]);
    });

    test('省略 INTO 时按 源名_n 命名', () {
      final d = _ds(['score'], [
        [20], [10],
      ]);
      final rs = SyntaxExecutor.run('AUTORECODE VARIABLES=score.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(_numCol(d, 'score_n'), [2.0, 1.0]);
    });

    test('/DESCENDING 与 /BLANK=VALID', () {
      final d = Dataset(name: 'test');
      d.addVariable(Variable(name: 'a', type: VarType.string));
      d.addCase(['A']);
      d.addCase([null]);
      d.addCase([' ']);
      final rs = SyntaxExecutor.run(
          'AUTORECODE VARIABLES=a /DESCENDING /BLANK=VALID.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      // BLANK=VALID 下空白串成为有效取值（空格 < 'A'，降序后 'A' 得 1）
      expect(_numCol(d, 'a_n'), [1.0, null, 2.0]);
    });

    test('源变量与目标变量数量不一致时报错', () {
      final d = _ds(['a', 'b'], [
        [1, 2],
      ]);
      final rs = SyntaxExecutor.run('AUTORECODE VARIABLES=a b /INTO=x.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('does not match'));
    });

    test('未给出变量时报语法提示', () {
      final d = _ds(['a'], [
        [1],
      ]);
      final rs = SyntaxExecutor.run('AUTORECODE /INTO=x.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('AUTORECODE syntax'));
    });
  });

  group('SAMPLE 抽样', () {
    test('n FROM N：恰好留 n 个，且只来自前 N 个', () {
      final d = _ids(20);
      final r = Transforms.sample(d, n: 5, from: 10, seed: 42);
      expect(d.nCases, 5);
      expect(r.changed, 15);
      final ids = d.numericColumn('id');
      expect(ids.every((v) => v <= 10), isTrue);
      // 同种子同结果
      final d2 = _ids(20);
      Transforms.sample(d2, n: 5, from: 10, seed: 42);
      expect(d2.numericColumn('id'), ids);
      // 不同种子会得到不同的组合（取 5 个种子，至少两种结果）
      final sets = <String>{};
      for (var seed = 42; seed < 47; seed++) {
        final dd = _ids(20);
        Transforms.sample(dd, n: 5, from: 10, seed: seed);
        sets.add(dd.numericColumn('id').join(','));
      }
      expect(sets.length, greaterThan(1));
    });

    test('n FROM N：前 N 个个案被等概率抽中（200 次重复）', () {
      final counts = List<int>.filled(20, 0);
      for (var seed = 0; seed < 200; seed++) {
        final d = _ids(20);
        Transforms.sample(d, n: 5, from: 10, seed: seed);
        for (final v in d.numericColumn('id')) {
          counts[v.toInt() - 1]++;
        }
      }
      // 前 10 个每个约 200 x 5/10 = 100 次（5σ 约 ±35）
      for (var i = 0; i < 10; i++) {
        expect(counts[i], inInclusiveRange(65, 135));
      }
      // 第 10 个之后一律不抽
      for (var i = 10; i < 20; i++) {
        expect(counts[i], 0);
      }
    });

    test('按比例：逐个案 Bernoulli，同种子可复现', () {
      final d = _ids(200);
      Transforms.sample(d, fraction: 0.5, seed: 7);
      expect(d.nCases, inInclusiveRange(80, 120));
      final d2 = _ids(200);
      Transforms.sample(d2, fraction: 0.5, seed: 7);
      expect(d2.numericColumn('id'), d.numericColumn('id'));
      // 200 个种子的平均保留比例接近 0.5
      var total = 0;
      for (var seed = 0; seed < 200; seed++) {
        final dd = _ids(200);
        Transforms.sample(dd, fraction: 0.5, seed: seed);
        total += dd.nCases;
      }
      expect(total / (200 * 200), closeTo(0.5, 0.02));
    });

    test('参数校验', () {
      final d = _ids(10);
      expect(() => Transforms.sample(d, fraction: 0), throwsArgumentError);
      expect(() => Transforms.sample(d, fraction: 1), throwsArgumentError);
      expect(() => Transforms.sample(d), throwsArgumentError);
      expect(() => Transforms.sample(d, n: 5), throwsArgumentError);
      expect(() => Transforms.sample(d, n: 0, from: 10), throwsArgumentError);
      expect(() => Transforms.sample(d, n: 10, from: 10), throwsArgumentError);
    });
  });

  group('SAMPLE 语法动词', () {
    test('SAMPLE n FROM N', () {
      final d = _ids(20);
      final rs = SyntaxExecutor.run('SAMPLE 5 FROM 10.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('keep 5'));
      expect(d.nCases, 5);
      expect(d.numericColumn('id').every((v) => v <= 10), isTrue);
    });

    test('SAMPLE p 与 /SEED：同种子可复现，默认种子等于显式写入', () {
      final d = _ids(50);
      final rs = SyntaxExecutor.run('SAMPLE 0.4 /SEED=99.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      final ids = d.numericColumn('id');
      final d2 = _ids(50);
      SyntaxExecutor.run('SAMPLE 0.4 /SEED=99.', d2,
          messages: SyntaxMessages.en);
      expect(d2.numericColumn('id'), ids);
      final d3 = _ids(50);
      SyntaxExecutor.run('SAMPLE 0.4.', d3, messages: SyntaxMessages.en);
      final d4 = _ids(50);
      SyntaxExecutor.run('SAMPLE 0.4 /SEED=20261016.', d4,
          messages: SyntaxMessages.en);
      expect(d3.numericColumn('id'), d4.numericColumn('id'));
    });

    test('语法错误时给出提示', () {
      final d = _ids(10);
      final rs = SyntaxExecutor.run('SAMPLE abc.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('SAMPLE syntax'));
    });

    test('命令分割不拆开小数（SAMPLE 0.4. 与 COMPUTE x = 1.5.）', () {
      expect(SyntaxParser.splitCommands('SAMPLE 0.4.'), ['SAMPLE 0.4']);
      expect(SyntaxParser.splitCommands('COMPUTE x = 1.5.'), ['COMPUTE x = 1.5']);
      // 多条命令仍在句点处分开
      expect(SyntaxParser.splitCommands('LIST. SAMPLE 2 FROM 4.'),
          ['LIST', 'SAMPLE 2 FROM 4']);
      final d = _ds(['score'], [
        [1], [2],
      ]);
      final rs = SyntaxExecutor.run('COMPUTE x = 1.5. LIST.', d,
          messages: SyntaxMessages.en);
      expect(rs.length, 2);
      expect(_numCol(d, 'x'), [1.5, 1.5]);
    });
  });

  group('MRSETS 定义与查询', () {
    test('二分法组：成员顺序即类别顺序，标签取变量标签', () {
      final d = _survey();
      final s = MRSets.define(
        d,
        name: r'$act',
        type: MrSetType.md,
        variables: ['act1', 'act2', 'act3'],
        label: '活动',
        counted: 1,
      );
      expect(d.mrSets.length, 1);
      expect(s.isDichotomy, isTrue);
      expect(s.variables, ['act1', 'act2', 'act3']);
      expect(s.counted, 1);
      expect(MRSets.lookup(d, r'$ACT'), isNotNull); // 名字大小写不敏感
      expect(MRSets.lookup(d, r'$act')!.label, '活动');
      expect(MRSets.lookup(d, r'$nope'), isNull);
    });

    test('分类法组：不接受 VALUE，标签可为空', () {
      final d = _survey();
      final s = MRSets.define(
        d,
        name: r'$subj',
        type: MrSetType.mc,
        variables: ['subj1', 'subj2'],
      );
      expect(s.counted, isNull);
      expect(s.type, MrSetType.mc);
      expect(
        () => MRSets.define(
          d,
          name: r'$bad',
          type: MrSetType.mc,
          variables: ['subj1', 'subj2'],
          counted: 1,
        ),
        throwsArgumentError,
      );
    });

    test('同名定义覆盖旧定义（PSPP dict_add_mrset）', () {
      final d = _survey();
      MRSets.define(d,
          name: r'$act',
          type: MrSetType.md,
          variables: ['act1', 'act2'],
          counted: 1);
      MRSets.define(d,
          name: r'$act',
          type: MrSetType.md,
          variables: ['act1', 'act2', 'act3'],
          counted: 1,
          label: '新');
      expect(d.mrSets.length, 1);
      expect(MRSets.lookup(d, r'$act')!.variables.length, 3);
      expect(MRSets.lookup(d, r'$act')!.label, '新');
    });

    test('定义校验：名字、成员数、类型、VALUE', () {
      final d = _survey();
      // 名字为空 / 非法
      expect(
        () => MRSets.define(d,
            name: '  ', type: MrSetType.md, variables: ['act1', 'act2'], counted: 1),
        throwsArgumentError,
      );
      expect(
        () => MRSets.define(d,
            name: '1bad name',
            type: MrSetType.md,
            variables: ['act1', 'act2'],
            counted: 1),
        throwsArgumentError,
      );
      // 成员不足 2 个（重复变量先去重）
      expect(
        () => MRSets.define(d,
            name: r'$x', type: MrSetType.md, variables: ['act1'], counted: 1),
        throwsArgumentError,
      );
      expect(
        () => MRSets.define(d,
            name: r'$x',
            type: MrSetType.md,
            variables: ['act1', 'act1'],
            counted: 1),
        throwsArgumentError,
      );
      // 变量不存在
      expect(
        () => MRSets.define(d,
            name: r'$x',
            type: MrSetType.md,
            variables: ['act1', 'nope'],
            counted: 1),
        throwsArgumentError,
      );
      // 类型不一致
      final d2 = _survey();
      d2.addVariable(Variable(name: 'text', type: VarType.string));
      expect(
        () => MRSets.define(d2,
            name: r'$x',
            type: MrSetType.md,
            variables: ['act1', 'text'],
            counted: 1),
        throwsArgumentError,
      );
      // 二分法组必须给 VALUE，且类型要与变量一致
      expect(
        () => MRSets.define(d,
            name: r'$x', type: MrSetType.md, variables: ['act1', 'act2']),
        throwsArgumentError,
      );
      expect(
        () => MRSets.define(d,
            name: r'$x',
            type: MrSetType.md,
            variables: ['act1', 'act2'],
            counted: '1'),
        throwsArgumentError,
      );
    });

    test('删除：按名删除与 ALL', () {
      final d = _survey();
      _defineSurveySets(d);
      expect(MRSets.delete(d, [r'$act']), 1);
      expect(d.mrSets.length, 1);
      expect(MRSets.delete(d, [r'$missing']), 0);
      expect(MRSets.delete(d, [for (final s in d.mrSets) s.name]), 1);
      expect(d.mrSets, isEmpty);
    });

    test('copy 与工程 JSON 往返都保留多选集', () {
      final d = _survey();
      _defineSurveySets(d);
      final c = d.copy().mrSets;
      expect(c.length, 2);
      expect(c.first.name, r'$act');
      expect(c.first.counted, 1);
      // copy 是深拷贝，改副本不影响原数据集
      c.first.variables.add('gender');
      expect(MRSets.lookup(d, r'$act')!.variables.length, 5);
      // 工程序列化
      final p = Project.create(name: 'survey', dataset: d);
      final back = Project.fromJson(p.toJson());
      expect(back.dataset.mrSets.length, 2);
      expect(back.dataset.mrSets[1].type, MrSetType.mc);
      expect(back.dataset.mrSets[0].counted, 1);
    });
  });

  group('MRSETS 频数与交叉表', () {
    test('二分法组频数：每列一个成员变量，空值不计数', () {
      final d = _survey();
      _defineSurveySets(d);
      final f = MRSets.frequencies(d, MRSets.lookup(d, r'$act')!);
      expect([for (final c in f.categories) c.label],
          ['活动1', '活动2', '活动3', '活动4', '活动5']);
      expect([for (final c in f.categories) c.count], [2, 1, 2, 1, 0]);
      expect(f.nResponses, 6);
      expect(f.nCasesWithResponse, 3);
      expect(f.nCases, 4);
    });

    test('分类法组频数：按取值合并，标签取值标签', () {
      final d = _survey();
      _defineSurveySets(d);
      final f = MRSets.frequencies(d, MRSets.lookup(d, r'$subj')!);
      expect([for (final c in f.categories) c.label], ['语文', '数学', '英语']);
      expect([for (final c in f.categories) c.count], [1, 3, 1]);
      expect(f.nResponses, 5);
      expect(f.nCasesWithResponse, 3);
    });

    test('二分法组频数：CATEGORYLABELS=COUNTEDVALUES 用值标签', () {
      final d = _survey();
      // 给成员变量补上选中值的值标签
      for (var i = 1; i <= 3; i++) {
        d.variables[d.indexOf('act$i')].valueLabels[1] = '选中';
      }
      final s = MRSets.define(
        d,
        name: r'$act',
        type: MrSetType.md,
        variables: ['act1', 'act2'],
        counted: 1,
        categoryLabels: MrCategorySource.countedValues,
      );
      final f = MRSets.frequencies(d, s);
      expect([for (final c in f.categories) c.label], ['选中', '选中']);
      expect(f.nResponses, 3); // act1: 2 + act2: 1
    });

    test('二分法组频数：用户缺失值不计数', () {
      final d = _survey();
      d.variables[d.indexOf('act1')].missingValues.add(1); // 把 1 声明为缺失
      final s = MRSets.define(d,
          name: r'$act',
          type: MrSetType.md,
          variables: ['act1', 'act2'],
          counted: 1);
      final f = MRSets.frequencies(d, s);
      expect([for (final c in f.categories) c.count], [0, 1]);
      expect(f.nResponses, 1);
      expect(f.nCasesWithResponse, 1);
    });

    test('二分法组 × 分类变量：列按取值排序，计数与分母都对', () {
      final d = _survey();
      _defineSurveySets(d);
      final c = MRSets.crosstab(d, MRSets.lookup(d, r'$act')!, 'gender');
      expect(c.colLabels, ['男', '女']);
      expect(c.counts, [
        [2, 0], // 活动1
        [1, 0], // 活动2
        [1, 1], // 活动3
        [0, 1], // 活动4
        [0, 0], // 活动5
      ]);
      expect(c.colResponses, [4, 2]);
      expect(c.colCasesWithResponse, [2, 1]);
      expect(c.colCases, [2, 2]);
      expect(c.totalResponses, 6);
      expect(c.totalCases, 4);
      expect(c.byLabel, '性别');
    });

    test('分类法组 × 分类变量：一个个案的多个响应分别计数', () {
      final d = _survey();
      _defineSurveySets(d);
      final c = MRSets.crosstab(d, MRSets.lookup(d, r'$subj')!, 'gender');
      expect(c.colLabels, ['男', '女']);
      expect(c.counts, [
        [1, 0], // 语文
        [3, 0], // 数学（第 3 个个案贡献两个响应）
        [0, 1], // 英语
      ]);
      expect(c.colResponses, [4, 1]);
      expect(c.colCasesWithResponse, [2, 1]);
      expect(c.colCases, [2, 2]);
    });

    test('文本输出含标题、合计与百分比', () {
      final d = _survey();
      _defineSurveySets(d);
      final text = MRSetsText.frequencies(
          MRSets.frequencies(d, MRSets.lookup(d, r'$act')!));
      expect(text, contains(r'$act'));
      expect(text, contains('Total responses'));
      expect(text, contains('6'));
      expect(text, contains('3 / 4'));
      final ct = MRSetsText.crosstab(
          MRSets.crosstab(d, MRSets.lookup(d, r'$act')!, 'gender'));
      expect(ct, contains('男'));
      expect(ct, contains('Cases with responses'));
      final df = MRSetsText.display(d.mrSets);
      expect(df, contains('Dichotomies'));
      expect(df, contains('Categories'));
      expect(df, contains('act5'));
    });
  });

  group('MRSETS 语法动词', () {
    test('MDGROUP / MCGROUP / DISPLAY', () {
      final d = _survey();
      final rs = SyntaxExecutor.run(
        "MRSETS /MDGROUP NAME=\$act LABEL='参加的活动' "
        'VARIABLES=act1 act2 act3 act4 act5 VALUE=1 '
        r'/MCGROUP NAME=$subj VARIABLES=subj1 subj2 subj3 '
        '/DISPLAY NAME=ALL.',
        d,
        messages: SyntaxMessages.en,
      );
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('MRSETS MDGROUP'));
      expect(rs.single.output, contains('VALUE=1.0'));
      expect(rs.single.output, contains('Multiple Response Sets'));
      expect(d.mrSets.length, 2);
      expect(MRSets.lookup(d, r'$act')!.label, '参加的活动');
      expect(MRSets.lookup(d, r'$act')!.variables.length, 5);
      expect(MRSets.lookup(d, r'$subj')!.type, MrSetType.mc);
    });

    test('/FREQUENCIES 与 /CROSSTABS', () {
      final d = _survey();
      _defineSurveySets(d);
      final rs = SyntaxExecutor.run(
          r'MRSETS /FREQUENCIES NAME=$act /CROSSTABS NAME=$subj BY=gender.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('/FREQUENCIES NAME='));
      expect(rs.single.output, contains('/CROSSTABS NAME='));
      expect(rs.single.output, contains('数学'));
      expect(rs.single.output, contains('Cases with responses'));
    });

    test('/DELETE NAME= 与 NAME=ALL', () {
      final d = _survey();
      _defineSurveySets(d);
      var rs = SyntaxExecutor.run(r'MRSETS /DELETE NAME=$act.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(rs.single.output, contains('1 set(s)'));
      expect(d.mrSets.length, 1);
      rs = SyntaxExecutor.run('MRSETS /DELETE NAME=ALL.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(d.mrSets, isEmpty);
      expect(rs.single.output, contains('0 remaining'));
    });

    test('错误：缺 VALUE、缺变量、未知子命令、未定义集合', () {
      final d = _survey();
      // 二分法组缺 VALUE
      var rs = SyntaxExecutor.run(
          'MRSETS /MDGROUP NAME=\$act VARIABLES=act1 act2.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('VALUE'));
      // 只有一个成员变量
      rs = SyntaxExecutor.run(
          r'MRSETS /MDGROUP NAME=$act VARIABLES=act1 VALUE=1.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('two variables'));
      // 未知子命令
      rs = SyntaxExecutor.run('MRSETS /NOPE NAME=x.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('MRSETS syntax'));
      // 未定义的集合
      rs = SyntaxExecutor.run(r'MRSETS /FREQUENCIES NAME=$none.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('no multiple response set'));
      // 没有子命令
      rs = SyntaxExecutor.run('MRSETS.', d, messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('MRSETS syntax'));
    });

    test('/CROSSTABS 缺 BY 时报语法提示', () {
      final d = _survey();
      _defineSurveySets(d);
      final rs = SyntaxExecutor.run(r'MRSETS /CROSSTABS NAME=$act.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('MRSETS syntax'));
    });
  });

  group('COMBINE FILES 追加（ADD FILES）', () {
    /// 两张同结构的成绩表：a 的 score 带标签与缺失值，b 多一个带值标签的 group
    (Dataset, Dataset) twoTables() {
      final a = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
      ]);
      a.variables[0].label = '学号';
      a.variables[1].label = '成绩';
      a.variables[1].missingValues.add(99);
      final b = _ds(['id', 'score', 'group'], [
        [3, 70, 1],
        [4, 85, 2],
      ]);
      b.variables[2].label = '班级';
      b.variables[2].valueLabels.addAll({1: 'A班', 2: 'B班'});
      b.variables[0].valueLabels.addAll({3: '三号'});
      return (a, b);
    }

    test('按变量名拼行，缺的变量补缺失值', () {
      final (a, b) = twoTables();
      final r = CombineFiles.addFiles([CombineInput(a), CombineInput(b)]);
      final d = r.dataset;
      expect([for (final v in d.variables) v.name], ['id', 'score', 'group']);
      expect(d.nCases, 4);
      expect(_numCol(d, 'id'), [1, 2, 3, 4]);
      expect(_numCol(d, 'score'), [80, 90, 70, 85]);
      expect(_col(d, 'group'), [null, null, 1, 2]);
      expect(r.message, contains('4 cases x 3 variables'));
    });

    test('变量标签 / 值标签 / 缺失值不丢（先定义的文件为准，后续补缺口）', () {
      final (a, b) = twoTables();
      final d =
          CombineFiles.addFiles([CombineInput(a), CombineInput(b)]).dataset;
      expect(d.variables[0].label, '学号'); // 来自 a
      expect(d.variables[1].label, '成绩'); // a 有、b 无
      expect(d.variables[1].missingValues, [99]); // a 的缺失值保留
      expect(d.variables[2].label, '班级'); // 只有 b 有
      expect(d.variables[2].valueLabels[1], 'A班'); // b 的值标签保留
      expect(d.variables[0].valueLabels[3], '三号'); // 后续文件补缺口
    });

    test('同名变量类型不一致报错', () {
      final a = _ds(['id', 'score'], [
        [1, 80],
      ]);
      final bad = Dataset(name: 'bad')
        ..addVariable(Variable(name: 'id'))
        ..addVariable(Variable(name: 'score', type: VarType.string));
      bad.addCase([2, 'x']);
      expect(
        () => CombineFiles.addFiles([CombineInput(a), CombineInput(bad)]),
        throwsArgumentError,
      );
    });

    test('/BY：各文件按 BY 升序，等值组按文件顺序输出', () {
      final x = _ds(['id', 'v'], [
        [1, 10],
        [1, 11],
        [3, 30],
      ]);
      final y = _ds(['id', 'w'], [
        [1, 100],
        [2, 200],
      ]);
      final d = CombineFiles
          .addFiles([CombineInput(x), CombineInput(y)], by: ['id']).dataset;
      expect([for (final v in d.variables) v.name], ['id', 'v', 'w']);
      expect(_numCol(d, 'id'), [1, 1, 1, 2, 3]);
      expect(_col(d, 'v'), [10, 11, null, null, 30]);
      expect(_col(d, 'w'), [null, null, 100, 200, null]);
    });

    test('/BY 要求文件已排序、变量必须存在', () {
      final x = _ds(['id', 'v'], [
        [1, 10],
        [1, 11],
        [3, 30],
      ]);
      final unsorted = _ds(['id', 'w'], [
        [2, 200],
        [1, 100],
      ]);
      expect(
        () => CombineFiles.addFiles(
            [CombineInput(x), CombineInput(unsorted)],
            by: ['id']),
        throwsArgumentError,
      );
      expect(
        () => CombineFiles.addFiles(
            [CombineInput(x), CombineInput(_ds(['id', 'w'], [
              [1, 1],
            ]))],
            by: ['nope']),
        throwsArgumentError,
      );
    });

    test('/IN= 指示变量与 /KEEP /DROP', () {
      final (a, b) = twoTables();
      final d = CombineFiles.addFiles([
        CombineInput(a, inVar: 'src'),
        CombineInput(b),
      ]).dataset;
      expect([for (final v in d.variables) v.name], ['id', 'score', 'group', 'src']);
      expect(_col(d, 'src'), [1, 1, 0, 0]);

      final dropped = CombineFiles.addFiles(
        [CombineInput(a), CombineInput(b)],
        drop: ['group'],
      ).dataset;
      expect([for (final v in dropped.variables) v.name], ['id', 'score']);

      final kept = CombineFiles.addFiles(
        [CombineInput(a), CombineInput(b)],
        keep: ['score'],
      ).dataset;
      expect([for (final v in kept.variables) v.name], ['score']);
      expect(() => CombineFiles.addFiles([CombineInput(a)], drop: ['nope']),
          throwsArgumentError);
    });
  });

  group('COMBINE FILES 匹配（MATCH FILES）', () {
    test('按 BY 查表：保持主文件顺序，只在表里的键追加到末尾', () {
      final main = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
        [3, 70],
        [3, 75],
      ]);
      final table = _ds(['id', 'group'], [
        [1, 10],
        [2, 20],
        [4, 40],
      ]);
      final r = CombineFiles.matchFiles(CombineInput(main), [
        CombineInput(table),
      ], by: ['id']);
      final d = r.dataset;
      expect([for (final v in d.variables) v.name], ['id', 'score', 'group']);
      expect(_numCol(d, 'id'), [1, 2, 3, 3, 4]);
      expect(_col(d, 'score'), [80, 90, 70, 75, null]);
      expect(_col(d, 'group'), [10, 20, null, null, 40]);
      expect(r.message, contains('only in table'));
    });

    test('查表文件同键重复时取第一个并在提示里报告', () {
      final main = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
      ]);
      final table = _ds(['id', 'group'], [
        [1, 10],
        [1, 99],
        [2, 20],
      ]);
      final r = CombineFiles.matchFiles(CombineInput(main), [
        CombineInput(table),
      ], by: ['id']);
      expect(_col(r.dataset, 'group'), [10, 20]);
      expect(r.message, contains('duplicated'));
    });

    test('不给 BY 时按个案序号对齐，较短的文件不再贡献', () {
      final main = _ds(['id', 'v'], [
        [1, 10],
        [2, 20],
        [3, 30],
      ]);
      final t = _ds(['id', 'w'], [
        [1, 100],
        [2, 200],
      ]);
      final d =
          CombineFiles.matchFiles(CombineInput(main), [CombineInput(t)]).dataset;
      expect(_numCol(d, 'id'), [1, 2, 3]);
      expect(_col(d, 'v'), [10, 20, 30]);
      expect(_col(d, 'w'), [100, 200, null]);
    });

    test('/RENAME 让两侧键名不同也能匹配，/IN 标记来源', () {
      final main = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
      ]);
      final table = _ds(['code', 'group'], [
        [1, 10],
        [2, 20],
      ]);
      final d = CombineFiles.matchFiles(
        CombineInput(main, inVar: 'from_main'),
        [
          CombineInput(table,
              rename: {'code': 'id'}, inVar: 'from_table'),
        ],
        by: ['id'],
      ).dataset;
      expect([for (final v in d.variables) v.name],
          ['id', 'score', 'group', 'from_main', 'from_table']);
      expect(_col(d, 'group'), [10, 20]);
      expect(_col(d, 'from_main'), [1, 1]);
      expect(_col(d, 'from_table'), [1, 1]);
    });

    test('BY 变量在查表文件里缺失时报错', () {
      final main = _ds(['id', 'score'], [
        [1, 80],
      ]);
      final table = _ds(['code', 'group'], [
        [1, 10],
      ]);
      expect(
        () => CombineFiles.matchFiles(CombineInput(main), [
          CombineInput(table),
        ], by: ['id']),
        throwsArgumentError,
      );
    });
  });

  group('COMBINE FILES 语法动词', () {
    test('ADD FILES /FILE=* /FILE=名字 /IN=来源 替换活动数据集', () {
      final ds = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
      ]);
      final b = _ds(['id', 'score', 'group'], [
        [3, 70, 1],
      ]);
      final rs = SyntaxExecutor.run(
        'ADD FILES /FILE=* /IN=src /FILE=b2.',
        ds,
        messages: SyntaxMessages.en,
        files: {'b2': b},
      );
      expect(rs.single.ok, isTrue);
      expect(ds.nCases, 3);
      expect([for (final v in ds.variables) v.name],
          ['id', 'score', 'group', 'src']);
      expect(_col(ds, 'src'), [1, 1, 0]);
      expect(_col(ds, 'group'), [null, null, 1]);
    });

    test('MATCH FILES /FILE=* /TABLE=名字 /RENAME /BY', () {
      final ds = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
      ]);
      final t = _ds(['code', 'group'], [
        [1, 10],
        [2, 20],
      ]);
      final rs = SyntaxExecutor.run(
        "MATCH FILES /FILE=* /TABLE='classes.sav' /RENAME=(code=id) /BY id.",
        ds,
        messages: SyntaxMessages.en,
        files: {'classes.sav': t},
      );
      expect(rs.single.ok, isTrue);
      expect(ds.nCases, 2);
      expect(_col(ds, 'group'), [10, 20]);
      expect(rs.single.output, contains('MATCH FILES'));
    });

    test('错误：未知文件、TABLE 配 ADD、缺 FILE、未知子命令、类型不一致', () {
      final ds = _ds(['id'], [
        [1],
      ]);
      var rs = SyntaxExecutor.run('ADD FILES /FILE=* /FILE=nope.', ds,
          messages: SyntaxMessages.en, files: {'b2': _ids(2)});
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('file not found'));

      rs = SyntaxExecutor.run('ADD FILES /FILE=* /TABLE=b2.', ds,
          messages: SyntaxMessages.en, files: {'b2': _ids(2)});
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('TABLE='));

      rs = SyntaxExecutor.run('MATCH FILES /TABLE=b2 /BY id.', ds,
          messages: SyntaxMessages.en, files: {'b2': _ids(2)});
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('FILE='));

      rs = SyntaxExecutor.run('ADD FILES /NOPE=x.', ds,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('COMBINE FILES'));

      final bad = Dataset(name: 'bad')
        ..addVariable(Variable(name: 'id', type: VarType.string));
      bad.addCase(['a']);
      rs = SyntaxExecutor.run('ADD FILES /FILE=* /FILE=bad.', ds,
          messages: SyntaxMessages.en, files: {'bad': bad});
      expect(rs.single.ok, isFalse);
      expect(rs.single.output, contains('different types'));
      // 失败时活动数据集不动
      expect(ds.nVars, 1);
      expect(ds.nCases, 1);
    });

    test('注释行不影响后续命令的参数（parse 修正）', () {
      final d = _ds(['score'], [
        [1],
        [2],
      ]);
      final rs = SyntaxExecutor.run('* 说明行\nCOMPUTE x = score + 1.', d,
          messages: SyntaxMessages.en);
      expect(rs.single.ok, isTrue);
      expect(_numCol(d, 'x'), [2, 3]);
    });

    test('.sps 例：附加数据集后追加 + 按键匹配（可复现）', () {
      const sps = '''
* v1.4.0 M2.5 可复现例：把 b 表按名追加进来，再按 id 匹配班级表。
ADD FILES /FILE=* /IN=src /FILE='b.sav'.
MATCH FILES /FILE=* /TABLE='classes.sav' /BY id.
LIST.
''';
      final ds = _ds(['id', 'score'], [
        [1, 80],
        [2, 90],
      ]);
      final rs = SyntaxExecutor.run(
        sps,
        ds,
        messages: SyntaxMessages.en,
        files: {
          'b.sav': _ds(['id', 'score'], [
            [3, 70],
          ]),
          'classes.sav': _ds(['id', 'group'], [
            [1, 10],
            [2, 20],
            [3, 30],
          ]),
        },
      );
      expect(rs.length, 3,
          reason: rs.map((r) => '${r.command} ok=${r.ok}: ${r.output}').join(' | '));
      expect(rs.every((r) => r.ok), isTrue,
          reason: rs.map((r) => '${r.command} ok=${r.ok}: ${r.output}').join(' | '));
      expect(ds.nCases, 3);
      expect([for (final v in ds.variables) v.name],
          ['id', 'score', 'src', 'group']);
      expect(_numCol(ds, 'id'), [1, 2, 3]);
      expect(_col(ds, 'src'), [1, 1, 0]);
      expect(_col(ds, 'group'), [10, 20, 30]);
    });
  });
}

/// 测试内独立的 Φ⁻¹（二分求 normCdf 的反函数），用于交叉验证 normalQuantile。
double _probitCheck(double p) {
  var lo = -10.0, hi = 10.0;
  for (var i = 0; i < 200; i++) {
    final mid = (lo + hi) / 2;
    if (_phi(mid) < p) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// 测试内独立的标准正态 CDF（误差函数形式）。
double _phi(double z) => 0.5 * (1 + _erf(z / math.sqrt2));

double _erf(double x) {
  // Abramowitz & Stegun 7.1.26
  final t = 1 / (1 + 0.3275911 * x.abs());
  final y = 1 -
      ((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t -
                  0.284496736) *
              t +
          0.254829592) *
          t *
          math.exp(-x * x);
  return x >= 0 ? y : -y;
}

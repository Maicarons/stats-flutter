/// 10 万行规模基准（v1.4.0 M5.3）。
///
/// 这个文件带 `benchmark` 标签：
///
/// - 默认测试不跑它（CI 主流程 `flutter test --exclude-tags "golden || benchmark"`）；
/// - 本地：`flutter test --tags benchmark`；
/// - CI 另有一个 `continue-on-error: true` 的影子任务专门跑它，
///   把每一步耗时打进日志，性能回退只当告警、不挡发布。
///
/// 覆盖的是「数据规模一大就可能退化」的路径，且都带上 v1.4.0 M5.1 的缺失值口径：
/// 建表、分组、单因素方差分析、描述统计、成对相关（成对删除）、频数（含缺失计数）、
/// 加权描述统计、RANK（排序）、SAMPLE（重排）。
@Tags(['benchmark'])
library;

// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/core/io/missing_aware.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/transforms/transforms.dart';

/// 基准行数（10 万）。
const int _rows = 100000;

/// 单步耗时上限的宽松护栏：正常在 10 秒内，这里留到 60 秒，
/// 只用来发现「数量级退化」，不追求稳定的性能断言。
const int _budgetMs = 60000;

/// 造 [n] 行数据：两个数值列（各约 2% 用户缺失值 999）、一个 5 分类变量、
/// 一列权重。取值由固定种子生成，所以每次跑的是同一份数据。
Dataset _bigDataset(int n) {
  final rng = math.Random(42);
  final d = Dataset(name: 'bench');
  d.addVariable(Variable(name: 'id', decimals: 0));
  d.addVariable(Variable(name: 'score', missingValues: [999]));
  d.addVariable(Variable(name: 'score2', missingValues: [999]));
  d.addVariable(Variable(name: 'grp', decimals: 0, valueLabels: {
    0: 'A',
    1: 'B',
    2: 'C',
    3: 'D',
    4: 'E',
  }));
  d.addVariable(Variable(name: 'w', decimals: 0));
  for (var i = 0; i < n; i++) {
    final missing = rng.nextDouble() < 0.02;
    final missing2 = rng.nextDouble() < 0.02;
    d.addCase([
      i,
      missing ? 999 : (50 + rng.nextDouble() * 20).roundToDouble(),
      missing2 ? 999 : (100 + rng.nextDouble() * 5).roundToDouble(),
      rng.nextInt(5),
      1 + rng.nextInt(3),
    ]);
  }
  d.weightVariable = 'w';
  return d;
}

void main() {
  test('10 万行：核心分析路径耗时（影子基准，失败仅告警）', () {
    final timings = <String, int>{};
    int time(String name, void Function() body) {
      final sw = Stopwatch()..start();
      body();
      sw.stop();
      timings[name] = sw.elapsedMilliseconds;
      return timings[name]!;
    }

    late Dataset d;
    time('build 100k x 5', () => d = _bigDataset(_rows));

    late Map<String, List<double>> groups;
    time('groups (by 5-level factor)', () => groups = MissingAware.groups(d, 'score', 'grp'));

    late AnovaResult anova;
    time('OnewayAnova.compute', () {
      final keys = groups.keys.toList()..sort();
      anova = OnewayAnova.compute([for (final k in keys) groups[k]!], labels: keys);
    });

    late Descriptives desc;
    time('Descriptives.compute', () =>
        desc = Descriptives.compute(MissingAware.numeric(d, 'score')));

    late CorrelationResult corr;
    time('pairs + Correlation.pearson', () {
      final (x, y) = MissingAware.pairs(d, 'score', 'score2');
      corr = Correlation.pearson(x, y);
    });

    late FrequencyTable freq;
    time('Frequencies.compute (categorical)', () =>
        freq = Frequencies.compute(MissingAware.raw(d, 'grp'), variableName: 'grp'));

    time('WeightedDescriptives.compute', () {
      final (v, w) = MissingAware.weighted(d, 'score', 'w');
      WeightedDescriptives.compute(v, w);
    });

    // 结果自检：口径对了，规模上也得对。
    // 注意：下面的 RANK / SAMPLE 会（按 PSPP 语义）改写数据集本身，
    // 所以自检放在它们之前。
    expect(desc.n, MissingAware.numeric(d, 'score').length);
    expect(desc.n, lessThan(_rows));
    // 分组剔除「分析变量缺失」的个案，所以组内总数 = score 的有效个案数
    expect(groups.values.fold<int>(0, (a, b) => a + b.length), desc.n);
    expect(anova.nTotal, groups.values.fold<int>(0, (a, b) => a + b.length));
    expect(corr.n, greaterThan(_rows * 0.9));
    expect(freq.nValid + freq.nMissing, _rows);
    expect(freq.rows.length, 5);

    time('Transforms.rank (sort 100k)', () =>
        Transforms.rank(d, sourceVar: 'score'));

    final beforeSample = d.nCases;
    time('Transforms.sample (fraction 0.5)', () =>
        Transforms.sample(d, fraction: 0.5));
    expect(d.nCases, lessThan(beforeSample));

    final total = timings.values.reduce((a, b) => a + b);

    final lines = <String>[
      'BENCH rows=$_rows vars=5',
      for (final e in timings.entries)
        'BENCH ${e.key.padRight(34)} ${e.value.toString().padLeft(6)} ms',
      'BENCH ${'total'.padRight(34)} ${total.toString().padLeft(6)} ms',
      'BENCH budget=$_budgetMs ms',
    ];
    print(lines.join('\n'));

    expect(total, lessThan(_budgetMs),
        reason: '10 万行核心路径总耗时超出宽松护栏，可能数量级退化');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

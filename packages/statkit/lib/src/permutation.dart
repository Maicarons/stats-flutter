/// 置换检验框架（v0.5）
///
/// 适用场景：小样本、分布未知、或统计量的零分布没有闭式解（均值差、t、相关、
/// KS 等）。p 值用 Phipson & Smyth (2010) 的「加一」校正
/// `(1 + #{|s| ≥ |obs|}) / (1 + B)`，避免小 B 时给出 p = 0 这种不可能的读数。
///
/// 固定 [seed] 时结果完全可复现（同一个 `Random(seed)` 按固定顺序取随机数）；
/// 组合数不大时可以用 [Permutation.exact] 做完全枚举，得到精确置换 p 值。
library;

import 'dart:math' as math;

/// 置换检验结果
class PermutationResult {
  /// 原始数据的统计量
  final double observed;

  /// 双侧 p（按 |统计量| 计尾概率）
  final double pTwoTail;

  /// 单侧：置换统计量 ≥ 观察值
  final double pGreater;

  /// 单侧：置换统计量 ≤ 观察值
  final double pLess;

  /// 实际使用的置换次数（完全枚举时为组合数）
  final int permutations;

  /// true 表示完全枚举（精确置换分布），false 表示随机抽样
  final bool exact;

  /// 随机抽样的种子；完全枚举时为 0
  final int seed;

  final double meanPermuted;
  final double sdPermuted;
  final double minPermuted;
  final double maxPermuted;

  const PermutationResult({
    required this.observed,
    required this.pTwoTail,
    required this.pGreater,
    required this.pLess,
    required this.permutations,
    required this.exact,
    required this.seed,
    required this.meanPermuted,
    required this.sdPermuted,
    required this.minPermuted,
    required this.maxPermuted,
  });

  /// 观察值在置换分布中的标准化位置，可与 z 并列展示
  double get z =>
      sdPermuted > 0 ? (observed - meanPermuted) / sdPermuted : 0.0;

  Map<String, dynamic> toJson() => {
        'observed': observed,
        'pTwoTail': pTwoTail,
        'pGreater': pGreater,
        'pLess': pLess,
        'permutations': permutations,
        'exact': exact,
        'seed': seed,
        'meanPermuted': meanPermuted,
        'sdPermuted': sdPermuted,
        'minPermuted': minPermuted,
        'maxPermuted': maxPermuted,
      };
}

class Permutation {
  /// 随机置换检验
  ///
  /// [permutedStatistic] 每次调用拿到同一个 [math.Random]，调用方负责用它
  /// 生成置换并返回该置换下的统计量。同一 seed + 同一调用顺序 → 同一结果。
  static PermutationResult random({
    required double observed,
    required double Function(math.Random rng) permutedStatistic,
    int permutations = 9999,
    int seed = 20261016,
  }) {
    final rng = math.Random(seed);
    final stats = <double>[];
    for (var i = 0; i < permutations; i++) {
      final s = permutedStatistic(rng);
      if (s.isFinite) stats.add(s);
    }
    return _build(observed, stats, exact: false, seed: seed);
  }

  /// 完全枚举：调用方给出全部置换下的统计量（组合数不大时使用）
  static PermutationResult exact({
    required double observed,
    required Iterable<double> permutedStatistics,
  }) {
    final stats = permutedStatistics.where((s) => s.isFinite).toList();
    return _build(observed, stats, exact: true, seed: 0);
  }

  /// 独立两组均值差的置换检验（合并两组后重排标签）
  static PermutationResult twoSampleMeanDifference(
    List<double> a,
    List<double> b, {
    int permutations = 9999,
    int seed = 20261016,
  }) {
    final x = a.where((v) => v.isFinite).toList();
    final y = b.where((v) => v.isFinite).toList();
    if (x.isEmpty || y.isEmpty) {
      return const PermutationResult(
        observed: double.nan,
        pTwoTail: double.nan,
        pGreater: double.nan,
        pLess: double.nan,
        permutations: 0,
        exact: false,
        seed: 0,
        meanPermuted: double.nan,
        sdPermuted: double.nan,
        minPermuted: double.nan,
        maxPermuted: double.nan,
      );
    }
    final pooled = <double>[...x, ...y];
    final n1 = x.length;
    final n2 = y.length;
    final observed = _mean(x) - _mean(y);
    return random(
      observed: observed,
      permutations: permutations,
      seed: seed,
      permutedStatistic: (rng) {
        pooled.shuffle(rng);
        var s1 = 0.0, s2 = 0.0;
        for (var i = 0; i < pooled.length; i++) {
          if (i < n1) {
            s1 += pooled[i];
          } else {
            s2 += pooled[i];
          }
        }
        return s1 / n1 - s2 / n2;
      },
    );
  }

  /// 配对置换检验（如前后测）：随机交换每对的先后顺序
  static PermutationResult pairedDifference(
    List<double> before,
    List<double> after, {
    int permutations = 9999,
    int seed = 20261016,
  }) {
    final n = math.min(before.length, after.length);
    final diffs = <double>[];
    for (var i = 0; i < n; i++) {
      if (before[i].isFinite && after[i].isFinite) {
        diffs.add(after[i] - before[i]);
      }
    }
    if (diffs.isEmpty) {
      return const PermutationResult(
        observed: double.nan,
        pTwoTail: double.nan,
        pGreater: double.nan,
        pLess: double.nan,
        permutations: 0,
        exact: false,
        seed: 0,
        meanPermuted: double.nan,
        sdPermuted: double.nan,
        minPermuted: double.nan,
        maxPermuted: double.nan,
      );
    }
    final observed = _mean(diffs);
    return random(
      observed: observed,
      permutations: permutations,
      seed: seed,
      permutedStatistic: (rng) {
        var sum = 0.0;
        for (final d in diffs) {
          sum += rng.nextBool() ? d : -d;
        }
        return sum / diffs.length;
      },
    );
  }

  static double _mean(List<double> v) =>
      v.isEmpty ? double.nan : v.reduce((a, b) => a + b) / v.length;

  static PermutationResult _build(
    double observed,
    List<double> stats, {
    required bool exact,
    required int seed,
  }) {
    final b = stats.length;
    if (b == 0) {
      return PermutationResult(
        observed: observed,
        pTwoTail: double.nan,
        pGreater: double.nan,
        pLess: double.nan,
        permutations: 0,
        exact: exact,
        seed: seed,
        meanPermuted: double.nan,
        sdPermuted: double.nan,
        minPermuted: double.nan,
        maxPermuted: double.nan,
      );
    }
    const eps = 1e-12;
    final absObs = observed.abs();
    var geTwo = 0, ge = 0, le = 0;
    var sum = 0.0, lo = stats.first, hi = stats.first;
    for (final s in stats) {
      if (s.abs() >= absObs - eps) geTwo++;
      if (s >= observed - eps) ge++;
      if (s <= observed + eps) le++;
      sum += s;
      if (s < lo) lo = s;
      if (s > hi) hi = s;
    }
    final mean = sum / b;
    var ss = 0.0;
    for (final s in stats) {
      ss += (s - mean) * (s - mean);
    }
    final sd = b > 1 ? math.sqrt(ss / (b - 1)) : 0.0;
    return PermutationResult(
      observed: observed,
      pTwoTail: (1 + geTwo) / (1 + b),
      pGreater: (1 + ge) / (1 + b),
      pLess: (1 + le) / (1 + b),
      permutations: b,
      exact: exact,
      seed: seed,
      meanPermuted: mean,
      sdPermuted: sd,
      minPermuted: lo,
      maxPermuted: hi,
    );
  }
}

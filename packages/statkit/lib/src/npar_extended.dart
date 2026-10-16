/// 非参数检验扩展：Binomial / Kendall / McNemar / Friedman / Cochran / Median（v0.2）
/// 以及 Jonckheere-Terpstra 有序备择趋势检验（v0.5）
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'correlation.dart';
import 'descriptives.dart';
import 'distributions.dart';
import 'exact_tests.dart';
import 'nonparametric.dart';

class NparExtended {
  /// 二项检验（可 exact）
  static NonparametricResult binomial(
    List<double> data, {
    required double splitValue,
    double p0 = 0.5,
    bool exact = true,
  }) {
    var k = 0;
    var n = 0;
    for (final x in data) {
      if (!x.isFinite) continue;
      n++;
      if (x > splitValue) k++;
    }
    final ex = exact ? exactBinomial(k, n, p0: p0) : null;
    // 渐近：正态近似带连续性校正
    final mu = n * p0;
    final sigma = math.sqrt(n * p0 * (1 - p0));
    final z = sigma > 0 ? (k - mu) / sigma : 0.0;
    final pAsy = normTwoTail(z);
    return NonparametricResult(
      testName: 'Binomial Test',
      statistic: k.toDouble(),
      statisticName: 'K',
      z: z,
      p: ex?.pTwoTail ?? pAsy,
      pExact: ex?.pTwoTail ?? double.nan,
      n1: n,
      extra: {
        'split': splitValue,
        'p0': p0,
        'pLess': ex?.pLess,
        'pGreater': ex?.pGreater,
        'pAsymptotic': pAsy,
      },
    );
  }

  /// Kendall tau-b
  static CorrelationResult kendallTau(List<double> x, List<double> y) {
    final n = math.min(x.length, y.length);
    if (n < 3) {
      return CorrelationResult(
          r: double.nan, p: double.nan, n: n, t: double.nan);
    }
    int concordant = 0, discordant = 0;
    int tiesX = 0, tiesY = 0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final dx = x[i].compareTo(x[j]);
        final dy = y[i].compareTo(y[j]);
        if (dx == 0 && dy == 0) continue;
        if (dx == 0) {
          tiesX++;
          continue;
        }
        if (dy == 0) {
          tiesY++;
          continue;
        }
        if (dx == dy) {
          concordant++;
        } else {
          discordant++;
        }
      }
    }
    final n0 = n * (n - 1) / 2;
    final denom = math.sqrt((n0 - tiesX) * (n0 - tiesY));
    final tau = denom == 0 ? 0.0 : (concordant - discordant) / denom;
    // 渐近 SE
    final varTau = 2 * (2 * n + 5) / (9 * n * (n - 1));
    final z = varTau > 0 ? tau / math.sqrt(varTau) : 0.0;
    return CorrelationResult(r: tau, p: normTwoTail(z), n: n, t: z);
  }

  /// McNemar（配对二分）连续性校正
  static NonparametricResult mcnemar(int b, int c, {bool exact = true}) {
    final n = b + c;
    if (n == 0) {
      return const NonparametricResult(
        testName: 'McNemar',
        statistic: 0,
        statisticName: 'χ²',
        p: 1,
        n1: 0,
      );
    }
    final chi = math.pow((b - c).abs() - 1, 2).toDouble() / n;
    final pAsy = chiSquareSf(chi, 1);
    // exact: two-sided binomial
    final ex = exact ? exactBinomial(math.min(b, c), n, p0: 0.5) : null;
    return NonparametricResult(
      testName: 'McNemar',
      statistic: chi,
      statisticName: 'χ²',
      z: math.sqrt(chi),
      p: ex?.pTwoTail ?? pAsy,
      pExact: ex?.pTwoTail ?? double.nan,
      n1: n,
      extra: {'b': b, 'c': c, 'pAsymptotic': pAsy},
    );
  }

  /// Cochran Q（k 相关二分处理）
  static NonparametricResult cochranQ(List<List<bool>> treatments) {
    final k = treatments.length;
    if (k < 2) {
      return const NonparametricResult(
        testName: 'Cochran Q',
        statistic: 0,
        statisticName: 'Q',
        p: 1,
        n1: 0,
      );
    }
    final n = treatments[0].length;
    final colSum = List<double>.filled(k, 0);
    final rowSum = List<double>.filled(n, 0);
    for (var t = 0; t < k; t++) {
      for (var s = 0; s < n; s++) {
        final v = treatments[t][s] ? 1.0 : 0.0;
        colSum[t] += v;
        rowSum[s] += v;
      }
    }
    final total = colSum.fold<double>(0, (a, b) => a + b);
    final num =
        (k - 1) * (k * colSum.fold<double>(0, (a, b) => a + b * b) - total * total);
    final den = k * total - rowSum.fold<double>(0, (a, b) => a + b * b);
    final q = den == 0 ? 0.0 : num / den;
    return NonparametricResult(
      testName: 'Cochran Q',
      statistic: q,
      statisticName: 'Q',
      p: chiSquareSf(q, k - 1),
      n1: n,
      n2: k,
    );
  }

  /// 中位数检验（k 组，2×k 列联卡方）
  static NonparametricResult medianTest(List<List<double>> groups) {
    final gs = groups.where((g) => g.isNotEmpty).toList();
    final k = gs.length;
    final all = gs.expand((e) => e).toList();
    final med = percentile(List.of(all)..sort(), 50);
    // 2 x k table: rows above/below, cols groups
    final above = List.filled(k, 0);
    final below = List.filled(k, 0);
    for (var i = 0; i < k; i++) {
      for (final v in gs[i]) {
        if (v > med) {
          above[i]++;
        } else if (v < med) {
          below[i]++;
        }
      }
    }
    double chi = 0;
    final n = above.fold<int>(0, (a, b) => a + b) +
        below.fold<int>(0, (a, b) => a + b);
    final rowA = above.fold<int>(0, (a, b) => a + b).toDouble();
    final rowB = below.fold<int>(0, (a, b) => a + b).toDouble();
    for (var i = 0; i < k; i++) {
      final col = (above[i] + below[i]).toDouble();
      if (col == 0) continue;
      final eA = rowA * col / n;
      final eB = rowB * col / n;
      if (eA > 0) chi += math.pow(above[i] - eA, 2) / eA;
      if (eB > 0) chi += math.pow(below[i] - eB, 2) / eB;
    }
    return NonparametricResult(
      testName: 'Median Test',
      statistic: chi,
      statisticName: 'χ²',
      p: chiSquareSf(chi, k - 1),
      n1: n,
      n2: k,
      median: med,
    );
  }

  /// Friedman（别名，便于 NPAR 语义）
  static NonparametricResult friedman(List<List<double>> treatments) =>
      Nonparametric.friedman(treatments);

  /// Jonckheere-Terpstra 有序备择趋势检验。
  ///
  /// [groups] 必须按备择假设的方向给出：组序号越大、取值越大 → J 偏大 →
  /// 支持「随组序号单调上升」的趋势（而非仅仅「某组不同」）。
  /// 跨组相等的取值（结）每对计 0.5；方差取 Hollander-Wolfe 结校正，
  /// 与 PSPP `NPAR TESTS /J-T` 用的是同一组公式。返回的 p 为双侧渐近值，
  /// `extra['pOneTail']` 为「上升」方向的单侧 p。
  ///
  /// [weights] 与 [groups] 逐组、逐例对应，按频数解释：组内权重均为整数时，
  /// 结果与「把该例重复相应次数」完全一致。
  @experimental
  static NonparametricResult jonckheereTerpstra(
    List<List<double>> groups, {
    List<List<double>>? weights,
  }) {
    final data = <List<(double, double)>>[];
    for (var g = 0; g < groups.length; g++) {
      final values = groups[g];
      final ws = weights != null && g < weights.length ? weights[g] : null;
      final rows = <(double, double)>[];
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        if (!v.isFinite) continue;
        final w = ws != null && i < ws.length ? ws[i] : 1.0;
        if (!w.isFinite || w <= 0) continue;
        rows.add((v, w));
      }
      if (rows.isNotEmpty) {
        rows.sort((a, b) => a.$1.compareTo(b.$1));
        data.add(rows);
      }
    }
    final levels = data.length;
    final counts =
        data.map((g) => g.fold<double>(0, (a, e) => a + e.$2)).toList();
    final n = counts.fold<double>(0, (a, b) => a + b);
    if (levels < 2 || n <= 0) {
      return const NonparametricResult(
        testName: 'Jonckheere-Terpstra Test',
        statistic: double.nan,
        statisticName: 'J',
        p: double.nan,
        n1: 0,
        extra: {'levels': 0},
      );
    }

    // J = Σ_{i<j} U_ij：组对之间「前者小于后者」的对数（结计 0.5）
    var j = 0.0;
    for (var i = 0; i < levels; i++) {
      for (var q = i + 1; q < levels; q++) {
        j += _jtPairU(data[i], data[q]);
      }
    }

    // 结组：全样本每个不同取值的权重合计
    final tieWeights = <double, double>{};
    for (final g in data) {
      for (final (v, w) in g) {
        tieWeights[v] = (tieWeights[v] ?? 0) + w;
      }
    }
    var groupF1 = 0.0, groupF2 = 0.0, groupF3 = 0.0, groupSq = 0.0;
    for (final c in counts) {
      groupF1 += _jtF1(c);
      groupF2 += _jtF2(c);
      groupF3 += _jtF3(c);
      groupSq += c * c;
    }
    var tieF1 = 0.0, tieF2 = 0.0, tieF3 = 0.0;
    for (final t in tieWeights.values) {
      tieF1 += _jtF1(t);
      tieF2 += _jtF2(t);
      tieF3 += _jtF3(t);
    }

    final mean = (n * n - groupSq) / 4.0;
    final f2n = _jtF2(n), f3n = _jtF3(n);
    var variance = (_jtF1(n) - groupF1 - tieF1) / 72.0;
    if (f2n > 0) variance += groupF2 * tieF2 / (36.0 * f2n);
    if (f3n > 0) variance += groupF3 * tieF3 / (8.0 * f3n);
    if (variance < 0) variance = 0;
    final sd = math.sqrt(variance);
    final z = sd > 0 ? (j - mean) / sd : 0.0;
    final pTwo = normTwoTail(z);

    return NonparametricResult(
      testName: 'Jonckheere-Terpstra Test',
      statistic: j,
      statisticName: 'J',
      z: z,
      p: pTwo,
      n1: n.round(),
      n2: levels,
      extra: {
        'levels': levels,
        'meanJ': mean,
        'sdJ': sd,
        'variance': variance,
        'pOneTail': z >= 0 ? pTwo / 2 : 1 - pTwo / 2,
      },
    );
  }

  /// 组对 U 值：A 中每例按权重计「小于 B 的部分 + 相等部分的 0.5」。
  /// B 已按取值升序，用前缀和 + 二分，复杂度 O(|A| log |B|)。
  static double _jtPairU(List<(double, double)> a, List<(double, double)> b) {
    final prefix = List<double>.filled(b.length + 1, 0);
    for (var i = 0; i < b.length; i++) {
      prefix[i + 1] = prefix[i] + b[i].$2;
    }
    final total = prefix[b.length];
    var u = 0.0;
    for (final (v, w) in a) {
      final firstGe = _jtLowerBound(b, v);
      final firstGt = _jtUpperBound(b, v);
      final le = prefix[firstGt];
      final eq = le - prefix[firstGe];
      u += w * ((total - le) + 0.5 * eq);
    }
    return u;
  }

  static int _jtLowerBound(List<(double, double)> rows, double v) {
    var lo = 0, hi = rows.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (rows[mid].$1 < v) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  static int _jtUpperBound(List<(double, double)> rows, double v) {
    var lo = 0, hi = rows.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (rows[mid].$1 <= v) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

// —— Jonckheere-Terpstra 方差用到的三个辅助函数（与 PSPP 的 mff[] 一一对应） ——

double _jtF1(double e) => e * (e - 1) * (2 * e + 5);

double _jtF2(double e) => e * (e - 1) * (e - 2);

double _jtF3(double e) => e * (e - 1);


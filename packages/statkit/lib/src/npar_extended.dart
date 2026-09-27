/// 非参数检验扩展：Binomial / Kendall / McNemar / Friedman / Cochran / Median（v0.2）
library;

import 'dart:math' as math;

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
}

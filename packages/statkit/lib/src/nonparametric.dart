/// 非参数检验
library;

import 'dart:math' as math;

import 'correlation.dart';
import 'descriptives.dart';
import 'distributions.dart';

class NonparametricResult {
  final String testName;
  final double statistic;
  final String statisticName;
  final double? z;
  final double p;
  final double pExact;
  final int n1;
  final int n2;
  final double? meanRank1;
  final double? meanRank2;
  final double? median;
  final Map<String, dynamic> extra;

  const NonparametricResult({
    required this.testName,
    required this.statistic,
    required this.statisticName,
    this.z,
    required this.p,
    this.pExact = double.nan,
    required this.n1,
    this.n2 = 0,
    this.meanRank1,
    this.meanRank2,
    this.median,
    this.extra = const {},
  });

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'statistic': statistic,
        'statisticName': statisticName,
        'z': z,
        'p': p,
        'pExact': pExact,
        'n1': n1,
        'n2': n2,
        'meanRank1': meanRank1,
        'meanRank2': meanRank2,
        'median': median,
        'extra': extra,
      };
}

class Nonparametric {
  /// Mann-Whitney U（独立两样本）
  static NonparametricResult mannWhitney(List<double> a, List<double> b) {
    final n1 = a.length, n2 = b.length;
    final all = [...a, ...b];
    final ranks = averageRanks(all);
    final r1 = ranks.sublist(0, n1).fold<double>(0, (x, y) => x + y);
    final r2 = ranks.sublist(n1).fold<double>(0, (x, y) => x + y);
    final u1 = r1 - n1 * (n1 + 1) / 2;
    final u2 = r2 - n2 * (n2 + 1) / 2;
    final u = math.min(u1, u2);
    final mu = n1 * n2 / 2;
    final sigma = math.sqrt(n1 * n2 * (n1 + n2 + 1) / 12);
    final z = sigma > 0 ? (u - mu) / sigma : 0.0;
    final zc = sigma > 0
        ? ((u - mu).abs() - 0.5) / sigma * (u > mu ? -1 : 1)
        : 0.0;
    return NonparametricResult(
      testName: 'Mann-Whitney U',
      statistic: u,
      statisticName: 'U',
      z: z,
      p: normTwoTail(zc.isFinite ? zc : z),
      n1: n1,
      n2: n2,
      meanRank1: n1 > 0 ? r1 / n1 : double.nan,
      meanRank2: n2 > 0 ? r2 / n2 : double.nan,
    );
  }

  /// Wilcoxon 符号秩（配对）
  static NonparametricResult wilcoxon(List<double> a, List<double> b) {
    final n = math.min(a.length, b.length);
    final diffs = <double>[];
    for (var i = 0; i < n; i++) {
      final d = a[i] - b[i];
      if (d.abs() > 1e-12) diffs.add(d);
    }
    if (diffs.isEmpty) {
      return const NonparametricResult(
        testName: 'Wilcoxon Signed-Rank',
        statistic: 0,
        statisticName: 'W',
        p: 1,
        n1: 0,
      );
    }
    final absDiffs = diffs.map((e) => e.abs()).toList();
    final ranks = averageRanks(absDiffs);
    double wPlus = 0, wMinus = 0;
    for (var i = 0; i < diffs.length; i++) {
      if (diffs[i] > 0) {
        wPlus += ranks[i];
      } else {
        wMinus += ranks[i];
      }
    }
    final w = math.min(wPlus, wMinus);
    final m = diffs.length;
    final mu = m * (m + 1) / 4;
    final sigma = math.sqrt(m * (m + 1) * (2 * m + 1) / 24);
    final z = sigma > 0 ? (w - mu) / sigma : 0.0;
    return NonparametricResult(
      testName: 'Wilcoxon Signed-Rank',
      statistic: w,
      statisticName: 'W',
      z: z,
      p: normTwoTail(z),
      n1: m,
      extra: {'W+': wPlus, 'W-': wMinus},
    );
  }

  /// Kruskal-Wallis H（k 独立样本）
  static NonparametricResult kruskalWallis(List<List<double>> groups) {
    final gs = groups.where((g) => g.isNotEmpty).toList();
    final k = gs.length;
    final all = gs.expand((e) => e).toList();
    final ranks = averageRanks(all);
    final n = all.length;
    double h = 0;
    final meanRanks = <double>[];
    var idx = 0;
    for (final g in gs) {
      double rSum = 0;
      for (var i = 0; i < g.length; i++) {
        rSum += ranks[idx++];
      }
      final meanR = rSum / g.length;
      meanRanks.add(meanR);
      h += g.length * math.pow(meanR - (n + 1) / 2, 2).toDouble();
    }
    h = 12 / (n * (n + 1)) * h;
    final tieCorrection = _tieCorrection(all);
    if (tieCorrection > 0) h /= tieCorrection;
    final p = chiSquareSf(h, k - 1);
    return NonparametricResult(
      testName: 'Kruskal-Wallis H',
      statistic: h,
      statisticName: 'H',
      p: p,
      n1: n,
      n2: k,
      extra: {
        'meanRanks': meanRanks,
        'groupNs': gs.map((g) => g.length).toList(),
      },
    );
  }

  /// Friedman（k 相关样本，区组设计）
  static NonparametricResult friedman(List<List<double>> treatments) {
    final k = treatments.length;
    if (k < 3) {
      return NonparametricResult(
        testName: 'Friedman',
        statistic: 0,
        statisticName: 'χ²',
        p: 1,
        n1: treatments.isNotEmpty ? treatments[0].length : 0,
        n2: k,
      );
    }
    final b = treatments[0].length;
    double chi = 0;
    final meanRanks = List<double>.filled(k, 0);
    for (var block = 0; block < b; block++) {
      final row = List.generate(k, (t) => treatments[t][block]);
      final ranks = averageRanks(row);
      for (var t = 0; t < k; t++) {
        meanRanks[t] += ranks[t];
      }
    }
    for (var t = 0; t < k; t++) {
      meanRanks[t] /= b;
      chi += math.pow(meanRanks[t] - (k + 1) / 2, 2).toDouble();
    }
    chi = 12 * b / (k * (k + 1)) * chi;
    return NonparametricResult(
      testName: 'Friedman',
      statistic: chi,
      statisticName: 'χ²',
      p: chiSquareSf(chi, k - 1),
      n1: b,
      n2: k,
      extra: {'meanRanks': meanRanks},
    );
  }

  /// 符号检验（配对二项）
  static NonparametricResult signTest(List<double> a, List<double> b) {
    final n = math.min(a.length, b.length);
    int pos = 0, neg = 0;
    for (var i = 0; i < n; i++) {
      final d = a[i] - b[i];
      if (d > 1e-12) {
        pos++;
      } else if (d < -1e-12) {
        neg++;
      }
    }
    final m = pos + neg;
    final p = m == 0
        ? 1.0
        : (2 * binomialSf(math.max(pos, neg), m, 0.5)).clamp(0.0, 1.0);
    return NonparametricResult(
      testName: 'Sign Test',
      statistic: math.min(pos, neg).toDouble(),
      statisticName: 'S',
      p: p,
      n1: m,
      extra: {'positive': pos, 'negative': neg},
    );
  }

  /// 游程检验（单样本）
  static NonparametricResult runsTest(List<double> data, {double? cutoff}) {
    final med = cutoff ?? percentile(List.of(data)..sort(), 50);
    final signs = data.map((e) => e >= med ? 1 : 0).toList();
    int runs = 1;
    for (var i = 1; i < signs.length; i++) {
      if (signs[i] != signs[i - 1]) runs++;
    }
    final n1 = signs.where((e) => e == 1).length;
    final n2 = signs.length - n1;
    final mu = n1 + n2 == 0 ? 0.0 : 2 * n1 * n2 / (n1 + n2) + 1;
    final varR = n1 + n2 > 1
        ? 2 * n1 * n2 * (2 * n1 * n2 - n1 - n2) /
            ((n1 + n2) * (n1 + n2) * (n1 + n2 - 1))
        : 0.0;
    final sigma = math.sqrt(varR);
    final z = sigma > 0 ? (runs - mu) / sigma : 0.0;
    return NonparametricResult(
      testName: 'Runs Test',
      statistic: runs.toDouble(),
      statisticName: 'Runs',
      z: z,
      p: normTwoTail(z),
      n1: n1,
      n2: n2,
      median: med,
    );
  }

  /// 单样本 KS（对比正态）
  static NonparametricResult kolmogorovSmirnovNormal(List<double> data) {
    final d = Descriptives.compute(data);
    final n = d.n;
    final v = d.sorted;
    double dp = 0, dn = 0;
    for (var i = 0; i < n; i++) {
      final cdf = normCdf((v[i] - d.mean) / (d.sd > 0 ? d.sd : 1));
      final empAbove = (i + 1) / n;
      final empBelow = i / n;
      dp = math.max(dp, (empAbove - cdf).abs());
      dn = math.max(dn, (cdf - empBelow).abs());
    }
    final ks = math.max(dp, dn);
    final p = _ksSf(ks, n);
    return NonparametricResult(
      testName: 'One-Sample KS (Normal)',
      statistic: ks,
      statisticName: 'D',
      p: p,
      n1: n,
      extra: {'mean': d.mean, 'sd': d.sd},
    );
  }

  static double _ksSf(double d, int n) {
    if (n <= 0 || d <= 0) return 1;
    final x = (math.sqrt(n) + 0.12 + 0.11 / math.sqrt(n)) * d;
    double sum = 0;
    for (var k = 1; k <= 100; k++) {
      final term =
          math.pow(-1, k - 1).toDouble() * math.exp(-2 * k * k * x * x);
      sum += term;
    }
    return (2 * sum).clamp(0.0, 1.0);
  }

  static double _tieCorrection(List<double> values) {
    final freq = <double, int>{};
    for (final v in values) {
      freq[v] = (freq[v] ?? 0) + 1;
    }
    final n = values.length;
    double tie = 0;
    for (final t in freq.values) {
      if (t > 1) tie += t * t * t - t;
    }
    return 1 - tie / (n * n * n - n);
  }
}

/// Cochran Q（k 相关二分样本）
double cochranQ(List<List<bool>> treatments) {
  final k = treatments.length;
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
  if (den == 0) return 0;
  return num / den;
}

/// McNemar（配对二分）
({double chiSquare, double p, int b, int c}) mcnemar(int b, int c) {
  final n = b + c;
  if (n == 0) return (chiSquare: 0, p: 1, b: b, c: c);
  final chi = math.pow((b - c).abs() - 1, 2).toDouble() / n;
  return (
    chiSquare: chi,
    p: chiSquareSf(chi, 1),
    b: b,
    c: c,
  );
}

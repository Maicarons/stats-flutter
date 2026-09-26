/// 描述统计
library;

import 'dart:math' as math;

import 'distributions.dart';

/// 线性插值百分位数
double percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) return double.nan;
  if (sorted.length == 1) return sorted.first;
  final rank = (p / 100) * (sorted.length - 1);
  final lo = rank.floor();
  final hi = rank.ceil();
  if (lo == hi) return sorted[lo];
  final w = rank - lo;
  return sorted[lo] * (1 - w) + sorted[hi] * w;
}

/// 众数（可多个；若全不重复返回空）
List<double> modes(List<double> values) {
  if (values.isEmpty) return [];
  final freq = <double, int>{};
  for (final v in values) {
    freq[v] = (freq[v] ?? 0) + 1;
  }
  final maxF = freq.values.fold<int>(0, math.max);
  if (maxF <= 1) return [];
  return (freq.entries.where((e) => e.value == maxF).map((e) => e.key).toList())
    ..sort();
}

/// 数值向量完整描述
class Descriptives {
  final int n;
  final double mean;
  final double sd;
  final double variance;
  final double min;
  final double max;
  final double range;
  final double median;
  final double q1;
  final double q3;
  final double iqr;
  final double skewness;
  final double kurtosis;
  final double se;
  final double sum;
  final double sumSquares;
  final double ciLower95;
  final double ciUpper95;
  final List<double> sorted;

  const Descriptives({
    required this.n,
    required this.mean,
    required this.sd,
    required this.variance,
    required this.min,
    required this.max,
    required this.range,
    required this.median,
    required this.q1,
    required this.q3,
    required this.iqr,
    required this.skewness,
    required this.kurtosis,
    required this.se,
    required this.sum,
    required this.sumSquares,
    required this.sorted,
    required this.ciLower95,
    required this.ciUpper95,
  });

  static Descriptives compute(List<double> values) {
    final v = values.where((x) => x.isFinite).toList()..sort();
    final n = v.length;
    if (n == 0) {
      return Descriptives(
        n: 0,
        mean: double.nan,
        sd: double.nan,
        variance: double.nan,
        min: double.nan,
        max: double.nan,
        range: double.nan,
        median: double.nan,
        q1: double.nan,
        q3: double.nan,
        iqr: double.nan,
        skewness: double.nan,
        kurtosis: double.nan,
        se: double.nan,
        sum: 0,
        sumSquares: 0,
        sorted: const [],
        ciLower95: double.nan,
        ciUpper95: double.nan,
      );
    }
    final sum = v.fold<double>(0, (a, b) => a + b);
    final mean = sum / n;
    final ss = v.fold<double>(0, (a, b) => a + (b - mean) * (b - mean));
    final variance = n > 1 ? ss / (n - 1) : 0.0;
    final sd = math.sqrt(variance);
    final se = sd / math.sqrt(n);

    double skew = 0, kurt = 0;
    if (n > 2 && sd > 0) {
      final m3 = v.fold<double>(0, (a, b) => a + math.pow(b - mean, 3)) / n;
      final m4 = v.fold<double>(0, (a, b) => a + math.pow(b - mean, 4)) / n;
      skew = m3 / math.pow(sd, 3);
      kurt = m4 / math.pow(sd, 4) - 3.0;
    }

    final q1 = percentile(v, 25);
    final median = percentile(v, 50);
    final q3 = percentile(v, 75);
    final half = tCritical(n > 1 ? n - 1 : 1, 0.05) * se;

    return Descriptives(
      n: n,
      mean: mean,
      sd: sd,
      variance: variance,
      min: v.first,
      max: v.last,
      range: v.last - v.first,
      median: median,
      q1: q1,
      q3: q3,
      iqr: q3 - q1,
      skewness: skew,
      kurtosis: kurt,
      se: se,
      sum: sum,
      sumSquares: v.fold<double>(0, (a, b) => a + b * b),
      sorted: v,
      ciLower95: mean - half,
      ciUpper95: mean + half,
    );
  }
}

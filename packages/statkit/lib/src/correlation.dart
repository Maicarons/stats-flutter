/// 相关分析
library;

import 'dart:math' as math;

import 'distributions.dart';

class CorrelationResult {
  final double r;
  final double p;
  final int n;
  final double t;
  final double? ciLower95;
  final double? ciUpper95;
  const CorrelationResult({
    required this.r,
    required this.p,
    required this.n,
    required this.t,
    this.ciLower95,
    this.ciUpper95,
  });
}

class Correlation {
  /// Pearson 积差相关
  static CorrelationResult pearson(List<double> x, List<double> y) {
    final n = math.min(x.length, y.length);
    if (n < 3) {
      return CorrelationResult(
          r: double.nan, p: double.nan, n: n, t: double.nan);
    }
    final xs = x.sublist(0, n);
    final ys = y.sublist(0, n);
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    double sxx = 0, syy = 0, sxy = 0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - mx;
      final dy = ys[i] - my;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }
    final r = (sxx <= 0 || syy <= 0) ? 0.0 : sxy / math.sqrt(sxx * syy);
    final t = r.abs() >= 1
        ? (r > 0 ? 1e10 : -1e10)
        : r * math.sqrt((n - 2) / (1 - r * r));
    final p = tTwoTail(t, n - 2);
    // Fisher z 变换 CI
    double? lo, hi;
    if (n > 3 && r.abs() < 1) {
      final z = 0.5 * math.log((1 + r) / (1 - r));
      final se = 1 / math.sqrt(n - 3);
      final zc = 1.959964;
      lo = _tanh(z - zc * se);
      hi = _tanh(z + zc * se);
    }
    return CorrelationResult(r: r, p: p, n: n, t: t, ciLower95: lo, ciUpper95: hi);
  }

  /// Spearman 秩相关
  static CorrelationResult spearman(List<double> x, List<double> y) {
    final n = math.min(x.length, y.length);
    final rx = averageRanks(x.sublist(0, n));
    final ry = averageRanks(y.sublist(0, n));
    return pearson(rx, ry);
  }

  /// Pearson 相关矩阵
  static List<List<double>> matrix(List<List<double>> columns) {
    final p = columns.length;
    return List.generate(p, (i) {
      return List.generate(p, (j) {
        if (i == j) return 1.0;
        return pearson(columns[i], columns[j]).r;
      });
    });
  }

  /// 成对删除的样本量矩阵
  static List<List<int>> nMatrix(List<List<double>> columns) {
    final p = columns.length;
    return List.generate(p, (i) {
      return List.generate(p, (j) {
        if (i == j) return columns[i].length;
        final n = math.min(columns[i].length, columns[j].length);
        var c = 0;
        for (var k = 0; k < n; k++) {
          if (columns[i][k].isFinite && columns[j][k].isFinite) c++;
        }
        return c;
      });
    });
  }
}

double _tanh(double x) {
  if (x > 20) return 1;
  if (x < -20) return -1;
  final e2 = math.exp(2 * x);
  return (e2 - 1) / (e2 + 1);
}

/// 平均秩（并列取平均）
List<double> averageRanks(List<double> values) {
  final indexed = List.generate(values.length, (i) => (i, values[i]))
    ..sort((a, b) => a.$2.compareTo(b.$2));
  final ranks = List<double>.filled(values.length, 0);
  var i = 0;
  while (i < indexed.length) {
    var j = i;
    while (j + 1 < indexed.length && indexed[j + 1].$2 == indexed[i].$2) {
      j++;
    }
    final avg = (i + j) / 2.0 + 1.0;
    for (var k = i; k <= j; k++) {
      ranks[indexed[k].$1] = avg;
    }
    i = j + 1;
  }
  return ranks;
}

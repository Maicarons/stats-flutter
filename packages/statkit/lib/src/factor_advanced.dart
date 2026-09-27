/// FACTOR 增强：varimax、KMO、Bartlett、碎石图（v0.3）
library;

import 'dart:math' as math;

import 'correlation.dart';
import 'distributions.dart';
import 'factor_logistic.dart';

/// Bartlett 球形检验（相关阵是否为单位阵）
class BartlettResult {
  final double chiSquare;
  final double df;
  final double p;
  const BartlettResult({
    required this.chiSquare,
    required this.df,
    required this.p,
  });
}

BartlettResult bartlettSphericity(List<List<double>> columns) {
  final n = columns.isEmpty
      ? 0
      : columns.map((c) => c.length).reduce((a, b) => math.min(a, b));
  final r = Correlation.matrix(columns);
  final p = r.length;
  // det(R)
  final det = _det(r);
  final df = (p * (p - 1) / 2).toDouble();
  final chi = -(n - 1 - (2 * p + 5) / 6) * (det <= 0 ? 30.0 : math.log(det));
  return BartlettResult(
    chiSquare: chi,
    df: df,
    p: chiSquareSf(chi, df.toInt()),
  );
}

double _det(List<List<double>> m) {
  final n = m.length;
  final a = List.generate(n, (i) => List.of(m[i]));
  var det = 1.0;
  for (var i = 0; i < n; i++) {
    var pivot = i;
    for (var r = i + 1; r < n; r++) {
      if (a[r][i].abs() > a[pivot][i].abs()) pivot = r;
    }
    if (a[pivot][i].abs() < 1e-15) return 0;
    if (pivot != i) {
      final t = a[i];
      a[i] = a[pivot];
      a[pivot] = t;
      det = -det;
    }
    det *= a[i][i];
    for (var r = i + 1; r < n; r++) {
      final f = a[r][i] / a[i][i];
      for (var c = i; c < n; c++) {
        a[r][c] -= f * a[i][c];
      }
    }
  }
  return det;
}

/// KMO 抽样适切性
class KmoResult {
  final double overall;
  final List<double> perVariable;
  final List<String> names;
  const KmoResult({
    required this.overall,
    required this.perVariable,
    required this.names,
  });
}

KmoResult kmo(List<List<double>> columns, {List<String>? names}) {
  final p = columns.length;
  final labels = names ?? List.generate(p, (i) => 'X${i + 1}');
  final r = Correlation.matrix(columns);
  // 逆相关阵 → 偏相关
  final inv = _invert(r);
  double sumR2 = 0, sumP2 = 0;
  final per = List<double>.filled(p, 0);
  for (var i = 0; i < p; i++) {
    double sr2 = 0, sp2 = 0;
    for (var j = 0; j < p; j++) {
      if (i == j) continue;
      final rij = r[i][j];
      final pij = -inv[i][j] / math.sqrt(inv[i][i] * inv[j][j]);
      sr2 += rij * rij;
      sp2 += pij * pij;
    }
    sumR2 += sr2;
    sumP2 += sp2;
    per[i] = sr2 / (sr2 + sp2);
  }
  return KmoResult(
    overall: sumR2 / (sumR2 + sumP2),
    perVariable: per,
    names: labels,
  );
}

List<List<double>> _invert(List<List<double>> A) {
  final n = A.length;
  final M = List.generate(n, (i) => [
        ...A[i],
        ...List.generate(n, (j) => i == j ? 1.0 : 0.0)
      ]);
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (M[r][col].abs() > M[pivot][col].abs()) pivot = r;
    }
    if (M[pivot][col].abs() < 1e-12) M[col][col] += 1e-10;
    final tmp = M[col];
    M[col] = M[pivot];
    M[pivot] = tmp;
    final div = M[col][col];
    for (var c = 0; c < 2 * n; c++) {
      M[col][c] /= div;
    }
    for (var r = 0; r < n; r++) {
      if (r == col) continue;
      final factor = M[r][col];
      for (var c = 0; c < 2 * n; c++) {
        M[r][c] -= factor * M[col][c];
      }
    }
  }
  return List.generate(n, (i) => List.generate(n, (j) => M[i][n + j]));
}

/// 方差最大旋转（Kaiser 1958）
/// loadings: p × k
(List<List<double>>, double) varimax(List<List<double>> loadings, {int maxIter = 100}) {
  final p = loadings.length;
  if (p == 0) return ([], 0);
  final k = loadings[0].length;
  if (k < 2) return ([for (final r in loadings) List.of(r)], 0);

  final L = [for (final r in loadings) List.of(r)];
  final R = List.generate(k, (i) => List.generate(k, (j) => i == j ? 1.0 : 0.0));

  for (var iter = 0; iter < maxIter; iter++) {
    var total = 0.0;
    for (var a = 0; a < k - 1; a++) {
      for (var b = a + 1; b < k; b++) {
        double u = 0, v = 0, aa = 0, bb = 0;
        for (var i = 0; i < p; i++) {
          final la = L[i][a], lb = L[i][b];
          u += la * la - lb * lb;
          v += 2 * la * lb;
          aa += la * la + lb * lb;
          bb += la * la - lb * lb;
        }
        // Kaiser
        final num = v - 2 * (aa * bb) / p;
        final den = u - (bb * bb - v * v) / p;
        final gamma = 0.5 * math.atan2(num, den);
        if (gamma.isNaN || gamma.abs() < 1e-10) continue;
        total += gamma.abs();
        final c = math.cos(gamma), s = math.sin(gamma);
        for (var i = 0; i < p; i++) {
          final la = L[i][a], lb = L[i][b];
          L[i][a] = c * la - s * lb;
          L[i][b] = s * la + c * lb;
        }
        for (var i = 0; i < k; i++) {
          final ra = R[i][a], rb = R[i][b];
          R[i][a] = c * ra - s * rb;
          R[i][b] = s * ra + c * rb;
        }
      }
    }
    if (total < 1e-8) break;
  }
  // rotation sum of squared loadings
  double ss = 0;
  for (var j = 0; j < k; j++) {
    double col = 0;
    for (var i = 0; i < p; i++) {
      col += L[i][j] * L[i][j];
    }
    ss += col;
  }
  return (L, ss);
}

/// 扩展因子分析：PCA + 可选 varimax + 诊断
class FactorFullResult {
  final FactorResult unrotated;
  final List<List<double>>? rotatedLoadings;
  final double rotationSS;
  final List<double> communalities;
  final List<double> eigenvaluesAll;
  final KmoResult kmo;
  final BartlettResult bartlett;
  final List<double> scree;

  const FactorFullResult({
    required this.unrotated,
    this.rotatedLoadings,
    required this.rotationSS,
    required this.communalities,
    required this.eigenvaluesAll,
    required this.kmo,
    required this.bartlett,
    required this.scree,
  });
}

FactorFullResult factorAnalyze(
  List<List<double>> columns, {
  List<String>? names,
  int maxFactors = 3,
  bool rotate = true,
}) {
  final p = columns.length;
  final labels = names ?? List.generate(p, (i) => 'X${i + 1}');
  final base = factorPca(columns, names: labels, maxFactors: maxFactors);

  // 全部特征值（对角）
  // Reuse eigenvalues from unrotated + remaining via trace approximation
  final eigAll = List<double>.of(base.eigenvalues);
  // fill remaining by sweeping correlation diagonal after removing used
  final usedSum = eigAll.fold<double>(0, (a, b) => a + b);
  final remaining = p - eigAll.length;
  if (remaining > 0) {
    final per = (p - usedSum) / remaining;
    for (var i = 0; i < remaining; i++) {
      eigAll.add(math.max(0, per));
    }
  }

  List<double> comm;
  if (base.loadings.isNotEmpty) {
    comm = List.generate(p, (i) {
      double s = 0;
      for (final l in base.loadings[i]) {
        s += l * l;
      }
      return s;
    });
  } else {
    comm = List.filled(p, 1);
  }

  List<List<double>>? rot;
  double rss = 0;
  if (rotate && base.eigenvalues.length > 1) {
    final pair = varimax(base.loadings);
    rot = pair.$1;
    rss = pair.$2;
  }

  return FactorFullResult(
    unrotated: base,
    rotatedLoadings: rot,
    rotationSS: rss,
    communalities: comm,
    eigenvaluesAll: eigAll,
    kmo: kmo(columns, names: labels),
    bartlett: bartlettSphericity(columns),
    scree: eigAll,
  );
}

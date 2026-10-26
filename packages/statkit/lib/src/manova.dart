/// 单因素多元方差分析 MANOVA（v0.7 / v1.8.0 M2）
///
/// 一个分组因素、多个数值因变量：H（组间 SSP）与 E（组内 SSP）之上给出
/// 四个经典多元检验——Wilks Λ（Rao F 近似）、Pillai 迹、Hotelling-Lawley 迹、
/// Roy 最大根。特征值经广义特征问题 E⁻¹H 求解（E 做 Cholesky 分解后化为
/// 对称矩阵，Jacobi 旋转求特征值）。F 近似公式与 SAS / statsmodels 一致；
/// Roy 的 F 是上界口径（SAS 报法）。
library;

import 'dart:math' as math;

import 'distributions.dart';

class ManovaGroupSummary {
  final String level;
  final int n;

  /// 组内各因变量均值（与 [dvNames] 对齐）
  final List<double> means;
  const ManovaGroupSummary(this.level, this.n, this.means);
}

class ManovaTest {
  final double value;
  final double f;
  final double df1;
  final double df2;
  final double p;
  const ManovaTest(this.value, this.f, this.df1, this.df2, this.p);
}

class ManovaResult {
  final String factorName;
  final List<String> dvNames;
  final int n;
  final int nGroups;

  /// 因变量个数（p）
  final int dvs;

  /// 假设自由度 h = g − 1；误差自由度 v = n − g
  final int dfHypothesis;
  final int dfError;

  final ManovaTest wilks;
  final ManovaTest pillai;
  final ManovaTest hotelling;
  final ManovaTest roy;

  /// 总体各因变量均值
  final List<double> grandMeans;
  final List<ManovaGroupSummary> groupStats;

  /// 各因变量的单因素 ANOVA F（便于逐变量对照）
  final List<double> univariateF;
  const ManovaResult({
    required this.factorName,
    required this.dvNames,
    required this.n,
    required this.nGroups,
    required this.dvs,
    required this.dfHypothesis,
    required this.dfError,
    required this.wilks,
    required this.pillai,
    required this.hotelling,
    required this.roy,
    required this.grandMeans,
    required this.groupStats,
    required this.univariateF,
  });
}

/// [groups]：因素水平 → 该水平的个案行（每行为按 [dvNames] 顺序的因变量值）。
/// 任一因变量缺失的行不参与（调用方负责完整个案）。
ManovaResult oneWayManova({
  required Map<String, List<List<double>>> groups,
  required List<String> dvNames,
  String factorName = 'factor',
}) {
  final levels =
      groups.keys.where((k) => groups[k]!.isNotEmpty).toList()..sort();
  final g = levels.length;
  final p = dvNames.length;
  if (g < 2) {
    throw ArgumentError('MANOVA needs at least 2 groups');
  }
  if (p < 1) {
    throw ArgumentError('MANOVA needs at least 1 dependent variable');
  }

  var n = 0;
  final grand = List<double>.filled(p, 0);
  final groupMeans = <String, List<double>>{};
  final groupN = <String, int>{};
  for (final lv in levels) {
    final rows = groups[lv]!;
    groupN[lv] = rows.length;
    n += rows.length;
    final m = List<double>.filled(p, 0);
    for (final row in rows) {
      for (var j = 0; j < p; j++) {
        m[j] += row[j];
        grand[j] += row[j];
      }
    }
    for (var j = 0; j < p; j++) {
      m[j] /= rows.length;
    }
    groupMeans[lv] = m;
  }
  for (var j = 0; j < p; j++) {
    grand[j] /= n;
  }

  final h = g - 1;
  final v = n - g;

  // E（组内）与 H（组间）SSP，p×p 对称
  final E = _mat(p, p);
  final H = _mat(p, p);
  for (final lv in levels) {
    final m = groupMeans[lv]!;
    for (final row in groups[lv]!) {
      final d = [for (var j = 0; j < p; j++) row[j] - m[j]];
      for (var a = 0; a < p; a++) {
        for (var b = 0; b < p; b++) {
          E[a][b] += d[a] * d[b];
        }
      }
    }
    final dm = [for (var j = 0; j < p; j++) m[j] - grand[j]];
    final ng = groupN[lv]!.toDouble();
    for (var a = 0; a < p; a++) {
      for (var b = 0; b < p; b++) {
        H[a][b] += ng * dm[a] * dm[b];
      }
    }
  }

  // 特征值：E⁻¹H 的特征值 = 广义对称特征问题 (H, E)
  final eig = _generalizedEigenvalues(H, E); // 降序

  var pillaiV = 0.0;
  var hotellingT = 0.0;
  for (final lam in eig) {
    pillaiV += lam / (1 + lam);
    hotellingT += lam;
  }
  // 最大典型根 θ = E⁻¹H 的最大特征值（statsmodels 的 Roy Value 口径）
  final royTheta = eig.isEmpty ? 0.0 : eig[0];

  final s = math.min(p, h).toDouble();
  final mPar = (math.max(p, h) - math.min(p, h) - 1) / 2;
  final nPar = (v - p - 1) / 2;

  // Wilks Λ = det(E)/det(E+H) + Rao F 近似
  final lambda = _det(E) / _det(_matAdd(E, H));
  final tPar = (p * p + h * h - 5 > 0)
      ? math.sqrt((p * p * h * h - 4.0) / (p * p + h * h - 5.0))
      : 1.0;
  final rW = v - (p - h + 1) / 2.0;
  final uW = (p * h - 2) / 4.0;
  final wDf1 = (p * h).toDouble();
  final wDf2 = rW * tPar - 2 * uW;
  final wilks = ManovaTest(
    lambda,
    wDf1 > 0 && wDf2 > 0
        ? (1 - _root(lambda, tPar)) / _root(lambda, tPar) * (wDf2 / wDf1)
        : double.nan,
    wDf1,
    wDf2,
    wDf1 > 0 && wDf2 > 0
        ? fSf((1 - _root(lambda, tPar)) / _root(lambda, tPar) * (wDf2 / wDf1),
            wDf1.round(), wDf2.round())
        : double.nan,
  );

  // Pillai
  final pDf1 = s * (2 * mPar + s + 1);
  final pDf2 = s * (2 * nPar + s + 1);
  final pillaiF = (s - pillaiV) > 0
      ? (pDf2 / pDf1) * (pillaiV / (s - pillaiV))
      : double.nan;
  final pillai = ManovaTest(
    pillaiV,
    pillaiF,
    pDf1,
    pDf2,
    (pillaiF.isFinite)
        ? fSf(pillaiF, pDf1.round(), pDf2.round())
        : double.nan,
  );

  // Hotelling-Lawley：n > 0 用 McKeon 近似（SAS / statsmodels 口径），
  // 否则退回简单式 F = (T/s)·df2/df1。
  double hotF;
  double hDf1, hDf2;
  if (nPar > 0) {
    final b = (p + 2 * nPar) * (h + 2 * nPar) /
        (2 * (2 * nPar + 1) * (nPar - 1));
    hDf1 = (p * h).toDouble();
    hDf2 = 4 + (p * h + 2) / (b - 1);
    final c = (hDf2 - 2) / (2 * nPar);
    hotF = (hDf2 / hDf1) * (hotellingT / c);
  } else {
    hDf1 = s * (2 * mPar + s + 1);
    hDf2 = 2 * (s * nPar + 1);
    hotF = (hotellingT / s) * (hDf2 / hDf1);
  }
  final hotelling = ManovaTest(
    hotellingT,
    hotF,
    hDf1,
    hDf2,
    fSf(hotF, hDf1.round(), hDf2.round()),
  );

  // Roy 最大根（F 为上界口径）
  final rDf1 = math.max(p, h).toDouble();
  final rDf2 = (v - p + h).toDouble();
  final royF =
      royTheta < 1 ? (rDf2 / rDf1) * royTheta : double.infinity;
  final roy = ManovaTest(
    royTheta,
    royF,
    rDf1,
    rDf2,
    royF.isFinite ? fSf(royF, rDf1.round(), rDf2.round()) : double.nan,
  );

  // 逐因变量单因素 F（供报告对照）
  final uniF = <double>[];
  for (var j = 0; j < p; j++) {
    final all = <double>[];
    double ssW = 0;
    for (final lv in levels) {
      final col = [for (final row in groups[lv]!) row[j]];
      all.addAll(col);
      final m = col.reduce((a, b) => a + b) / col.length;
      ssW += col.fold<double>(0, (acc, x) => acc + (x - m) * (x - m));
    }
    final grandAll = all.reduce((a, b) => a + b) / all.length;
    var ssB = 0.0;
    for (final lv in levels) {
      final col = [for (final row in groups[lv]!) row[j]];
      final m = col.reduce((a, b) => a + b) / col.length;
      ssB += col.length * (m - grandAll) * (m - grandAll);
    }
    final dfB = g - 1;
    final dfW = n - g;
    final f = ssW > 0 ? (ssB / dfB) / (ssW / dfW) : double.nan;
    uniF.add(f);
  }

  return ManovaResult(
    factorName: factorName,
    dvNames: dvNames,
    n: n,
    nGroups: g,
    dvs: p,
    dfHypothesis: h,
    dfError: v,
    wilks: wilks,
    pillai: pillai,
    hotelling: hotelling,
    roy: roy,
    grandMeans: grand,
    groupStats: [
      for (final lv in levels)
        ManovaGroupSummary(lv, groupN[lv]!, groupMeans[lv]!),
    ],
    univariateF: uniF,
  );
}

double _root(double x, double t) => x <= 0 ? 0 : math.pow(x, 1.0 / t).toDouble();

List<List<double>> _mat(int r, int c) => [
      for (var i = 0; i < r; i++) List<double>.filled(c, 0),
    ];

List<List<double>> _matAdd(List<List<double>> a, List<List<double>> b) => [
      for (var i = 0; i < a.length; i++)
        [for (var j = 0; j < a.length; j++) a[i][j] + b[i][j]],
    ];

/// 对称矩阵行列式（高斯消元，带部分主元）
double _det(List<List<double>> m) {
  final n = m.length;
  final a = [for (final row in m) List<double>.of(row)];
  var det = 1.0;
  for (var i = 0; i < n; i++) {
    var piv = i;
    for (var k = i + 1; k < n; k++) {
      if (a[k][i].abs() > a[piv][i].abs()) piv = k;
    }
    if (a[piv][i].abs() < 1e-300) return 0;
    if (piv != i) {
      final tmp = a[piv];
      a[piv] = a[i];
      a[i] = tmp;
      det = -det;
    }
    det *= a[i][i];
    for (var k = i + 1; k < n; k++) {
      final f = a[k][i] / a[i][i];
      for (var j = i; j < n; j++) {
        a[k][j] -= f * a[i][j];
      }
    }
  }
  return det;
}

/// 广义对称特征问题 H x = λ E x 的特征值（降序）。
/// E 做 Cholesky E = L·Lᵀ，化为对称矩阵 M = L⁻¹ H L⁻ᵀ，再 Jacobi 求特征值。
/// E 奇异时加微小岭修正保证可解。
List<double> _generalizedEigenvalues(
    List<List<double>> H, List<List<double>> E) {
  final n = E.length;
  var L = _cholesky(E);
  if (L == null) {
    // 数值兜底：加 trace/p * 1e-10 的岭
    var tr = 0.0;
    for (var i = 0; i < n; i++) {
      tr += E[i][i];
    }
    final ridge = tr.abs() / n * 1e-10 + 1e-300;
    final er = _mat(n, n);
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        er[i][j] = E[i][j];
      }
      er[i][i] += ridge;
    }
    L = _cholesky(er);
    if (L == null) return [];
  }
  // M = L⁻¹ H L⁻ᵀ：先解 L X = H 得 X = L⁻¹H，再 M = X L⁻ᵀ（(L⁻¹ Xᵀ)ᵀ）
  final X = _solveLower(L, H); // X = L⁻¹ H
  final Y = _solveLower(L, _transpose(X)); // Y = L⁻¹ Xᵀ
  final M = _transpose(Y); // M = (L⁻¹ H L⁻ᵀ)ᵀ = 对称
  final eig = _jacobiEigenvalues(M);
  eig.sort((a, b) => b.compareTo(a));
  return eig;
}

List<List<double>> _transpose(List<List<double>> m) => [
      for (var j = 0; j < m[0].length; j++)
        [for (var i = 0; i < m.length; i++) m[i][j]],
    ];

/// Cholesky 分解（下三角）；非正定返回 null
List<List<double>>? _cholesky(List<List<double>> A) {
  final n = A.length;
  final L = _mat(n, n);
  for (var i = 0; i < n; i++) {
    for (var j = 0; j <= i; j++) {
      var sum = A[i][j];
      for (var k = 0; k < j; k++) {
        sum -= L[i][k] * L[j][k];
      }
      if (i == j) {
        if (sum <= 0) return null;
        L[i][j] = math.sqrt(sum);
      } else {
        L[i][j] = sum / L[j][j];
      }
    }
  }
  return L;
}

/// 解 L X = B（L 下三角；B 为 n×m），返回 X
List<List<double>> _solveLower(List<List<double>> L, List<List<double>> B) {
  final n = L.length;
  final mCols = B.isEmpty ? 0 : B[0].length;
  final X = _mat(n, mCols);
  for (var c = 0; c < mCols; c++) {
    for (var i = 0; i < n; i++) {
      var sum = B[i][c];
      for (var k = 0; k < i; k++) {
        sum -= L[i][k] * X[k][c];
      }
      X[i][c] = sum / L[i][i];
    }
  }
  return X;
}

/// 对称矩阵的 Jacobi 特征值（绝对值大小排序无关，返回原值列表）
List<double> _jacobiEigenvalues(List<List<double>> M) {
  final n = M.length;
  final a = [for (final row in M) List<double>.of(row)];
  for (var sweep = 0; sweep < 100; sweep++) {
    var off = 0.0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        off += a[i][j] * a[i][j];
      }
    }
    if (off < 1e-24) break;
    for (var p = 0; p < n - 1; p++) {
      for (var q = p + 1; q < n; q++) {
        if (a[p][q].abs() < 1e-300) continue;
        final theta = (a[q][q] - a[p][p]) / (2 * a[p][q]);
        final t = (theta >= 0 ? 1.0 : -1.0) /
            (theta.abs() + math.sqrt(theta * theta + 1));
        final c = 1 / math.sqrt(t * t + 1);
        final s = t * c;
        for (var k = 0; k < n; k++) {
          final akp = a[k][p];
          final akq = a[k][q];
          a[k][p] = c * akp - s * akq;
          a[k][q] = s * akp + c * akq;
        }
        for (var k = 0; k < n; k++) {
          final apk = a[p][k];
          final aqk = a[q][k];
          a[p][k] = c * apk - s * aqk;
          a[q][k] = s * apk + c * aqk;
        }
      }
    }
  }
  return [for (var i = 0; i < n; i++) a[i][i]];
}

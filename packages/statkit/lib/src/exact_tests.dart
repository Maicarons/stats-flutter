/// 精确检验：Fisher 精确、精确二项、精确符号检验（v0.2）
library;

import 'dart:math' as math;

import 'distributions.dart';

/// 2×2 Fisher 精确检验
class FisherExactResult {
  final double pTwoTail;
  final double pLess;
  final double pGreater;
  final double oddsRatio;
  final double n;
  const FisherExactResult({
    required this.pTwoTail,
    required this.pLess,
    required this.pGreater,
    required this.oddsRatio,
    required this.n,
  });
}

/// 表： | a  b |
///      | c  d |
FisherExactResult fisherExact(int a, int b, int c, int d) {
  final n = a + b + c + d;
  final row1 = a + b;
  final col1 = a + c;

  double logHyper(int x) {
    if (x < 0 || x > math.min(row1, col1)) return double.negativeInfinity;
    final y = row1 - x;
    if (y < 0 || y > n - col1) return double.negativeInfinity;
    return _logComb(col1, x) + _logComb(n - col1, y) - _logComb(n, row1);
  }

  double pLess = 0, pGreater = 0;
  final pObs = math.exp(logHyper(a));
  for (var x = 0; x <= math.min(row1, col1); x++) {
    final p = math.exp(logHyper(x));
    if (x <= a) pLess += p;
    if (x >= a) pGreater += p;
  }
  double two = 0;
  for (var x = 0; x <= math.min(row1, col1); x++) {
    final p = math.exp(logHyper(x));
    if (p <= pObs * (1 + 1e-9)) two += p;
  }

  final double or;
  if (b * c == 0) {
    or = (a * d == 0) ? double.nan : double.infinity;
  } else {
    or = (a * d) / (b * c);
  }

  return FisherExactResult(
    pTwoTail: two.clamp(0.0, 1.0),
    pLess: pLess.clamp(0.0, 1.0),
    pGreater: pGreater.clamp(0.0, 1.0),
    oddsRatio: or,
    n: n.toDouble(),
  );
}

double _logComb(int n, int k) {
  if (k < 0 || k > n) return double.negativeInfinity;
  return lnGamma(n + 1) - lnGamma(k + 1) - lnGamma(n - k + 1);
}

/// 精确二项检验 H0: p = p0
class ExactBinomialResult {
  final int k;
  final int n;
  final double p0;
  final double pLess;
  final double pGreater;
  final double pTwoTail;
  final double estimate;
  const ExactBinomialResult({
    required this.k,
    required this.n,
    required this.p0,
    required this.pLess,
    required this.pGreater,
    required this.pTwoTail,
    required this.estimate,
  });
}

ExactBinomialResult exactBinomial(int k, int n, {double p0 = 0.5}) {
  if (n <= 0 || p0 <= 0 || p0 >= 1) {
    return ExactBinomialResult(
      k: k,
      n: n,
      p0: p0,
      pLess: double.nan,
      pGreater: double.nan,
      pTwoTail: double.nan,
      estimate: double.nan,
    );
  }
  double logPmf(int i) {
    if (i < 0 || i > n) return double.negativeInfinity;
    return _logComb(n, i) + i * math.log(p0) + (n - i) * math.log(1 - p0);
  }

  double pLess = 0, pGreater = 0;
  final pObs = math.exp(logPmf(k));
  for (var i = 0; i <= n; i++) {
    final p = math.exp(logPmf(i));
    if (i <= k) pLess += p;
    if (i >= k) pGreater += p;
  }
  double two = 0;
  for (var i = 0; i <= n; i++) {
    final p = math.exp(logPmf(i));
    if (p <= pObs * (1 + 1e-9)) two += p;
  }
  return ExactBinomialResult(
    k: k,
    n: n,
    p0: p0,
    pLess: pLess.clamp(0.0, 1.0),
    pGreater: pGreater.clamp(0.0, 1.0),
    pTwoTail: two.clamp(0.0, 1.0),
    estimate: n == 0 ? double.nan : k / n,
  );
}

/// 精确符号检验（正/负个数）
ExactBinomialResult exactSignTest(int positive, int negative, {double p0 = 0.5}) {
  return exactBinomial(positive, positive + negative, p0: p0);
}

/// 单样本 Kolmogorov 分布的**精确** CDF：P(D_n < d)。
///
/// Marsaglia–Tsang–Wang (2003)「Evaluating Kolmogorov's Distribution」的
/// Durbin 矩阵法：把 H 矩阵（h = k − n·d 的阶梯转移矩阵）自乘 n 次，取
/// (k−1, k−1) 元并乘 n!/nⁿ。中间量用 1e140 缩放防溢出；右尾（作者注：
/// 损失约 7 位精度换取速度）退化为半经验渐近式。要求 F 完全指定（参数
/// 不由样本估计），估计参数时应改用 Lilliefors 口径。
///
/// [d] 为 KS 统计量 D_n（0 < d < 1）。返回值范围 [0, 1]。
double exactKolmogorovCdf(int n, double d) {
  if (n <= 0 || d <= 0) return 0;
  if (d >= 1) return 1;
  final s = d * d * n;
  if (s > 7.24 || (s > 3.76 && n > 99) || n > 15000) {
    return 1 -
        2 * math.exp(-(2.000071 + 0.331 / math.sqrt(n) + 1.409 / n) * s);
  }
  final k = (n * d).floor() + 1;
  final m = 2 * k - 1;
  final h = k - n * d;
  final H = List<double>.filled(m * m, 0);
  for (var i = 0; i < m; i++) {
    for (var j = 0; j < m; j++) {
      H[i * m + j] = (i - j + 1 < 0) ? 0 : 1;
    }
  }
  for (var i = 0; i < m; i++) {
    H[i * m] -= math.pow(h, i + 1).toDouble();
    H[(m - 1) * m + i] -= math.pow(h, m - i).toDouble();
  }
  final twoH1 = 2 * h - 1;
  H[(m - 1) * m] += twoH1 > 0 ? math.pow(twoH1, m).toDouble() : 0;
  for (var i = 0; i < m; i++) {
    for (var j = 0; j < m; j++) {
      if (i - j + 1 > 0) {
        for (var g = 1; g <= i - j + 1; g++) {
          H[i * m + j] /= g;
        }
      }
    }
  }
  final (Q, eQ) = _mPower(H, m, n);
  var v = Q[(k - 1) * m + (k - 1)];
  var e = eQ;
  for (var i = 1; i <= n; i++) {
    v *= i / n;
    if (v < 1e-140) {
      v *= 1e140;
      e -= 140;
    }
  }
  final out = v * math.pow(10.0, e).toDouble();
  return out.clamp(0.0, 1.0);
}

/// 矩阵乘法（返回新矩阵；指数部分由调用方维护）
(List<double>, int) _mMultiply(List<double> a, List<double> b, int m) {
  final c = List<double>.filled(m * m, 0);
  for (var i = 0; i < m; i++) {
    for (var j = 0; j < m; j++) {
      var s = 0.0;
      for (var t = 0; t < m; t++) {
        s += a[i * m + t] * b[t * m + j];
      }
      c[i * m + j] = s;
    }
  }
  return (c, 0);
}

/// A 的 n 次幂（二进制快速幂，>1e140 时整体缩放并回填指数）
(List<double>, int) _mPower(List<double> a, int m, int n) {
  if (n == 1) return (List<double>.of(a), 0);
  var (v, eV) = _mPower(a, m, n ~/ 2);
  var (b, eB) = _mMultiply(v, v, m);
  eB = 2 * eV;
  List<double> r;
  int eR;
  if (n.isEven) {
    r = b;
    eR = eB;
  } else {
    (r, eR) = _mMultiply(a, b, m);
    eR = eB; // 基矩阵 A 的指数恒为 0
  }
  final mid = (m ~/ 2) * m + (m ~/ 2);
  if (r[mid] > 1e140) {
    for (var i = 0; i < r.length; i++) {
      r[i] *= 1e-140;
    }
    eR += 140;
  }
  return (r, eR);
}

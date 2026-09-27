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

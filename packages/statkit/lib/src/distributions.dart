/// 概率分布与特殊函数
library;

import 'dart:math' as math;

/// 标准正态 CDF Φ(z)
double normCdf(double z) {
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;
  final sign = z < 0 ? -1 : 1;
  final x = z.abs() / math.sqrt2;
  final t = 1.0 / (1.0 + p * x);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
  return 0.5 * (1.0 + sign * y);
}

/// 标准正态 PDF
double normPdf(double z) => math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi);

/// 正态双侧 p 值
double normTwoTail(double z) => 2 * (1 - normCdf(z.abs()));

/// 正态单侧上尾 p
double normUpper(double z) => 1 - normCdf(z);

/// z 临界值（双侧）
double zCritical(double alpha) {
  double lo = 0, hi = 10;
  for (var i = 0; i < 80; i++) {
    final mid = (lo + hi) / 2;
    if (normTwoTail(mid) > alpha) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// t 分布 CDF
double tCdf(double t, int df) {
  if (df <= 0) return double.nan;
  final x = df / (df + t * t);
  final p = 0.5 * betaInc(df / 2.0, 0.5, x);
  return t >= 0 ? 1 - p : p;
}

/// t 双侧 p
double tTwoTail(double t, int df) {
  if (df <= 0) return double.nan;
  return 2 * (1 - tCdf(t.abs(), df));
}

/// t 单侧上尾 p
double tUpper(double t, int df) => 1 - tCdf(t, df);

/// t 临界值（双侧 alpha）
double tCritical(int df, double alpha) {
  if (df <= 0) return double.nan;
  double lo = 0, hi = 80;
  for (var i = 0; i < 100; i++) {
    final mid = (lo + hi) / 2;
    if (tTwoTail(mid, df) > alpha) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// t PDF
double tPdf(double t, int df) {
  final lg = lnGamma((df + 1) / 2.0) - lnGamma(df / 2.0);
  return math.exp(lg) /
      math.sqrt(df * math.pi) *
      math.pow(1 + t * t / df, -(df + 1) / 2.0).toDouble();
}

/// 卡方 CDF（下尾）
double chiSquareCdf(double x, int df) {
  if (x <= 0) return 0;
  return lowerIncGamma(df / 2.0, x / 2.0);
}

/// 卡方上尾 p（常用）
double chiSquareSf(double x, int df) {
  if (x <= 0) return 1;
  return upperIncGamma(df / 2.0, x / 2.0);
}

double chiSquarePdf(double x, int df) {
  if (x <= 0) return 0;
  final k = df / 2.0;
  return math.exp((k - 1) * math.log(x) - x / 2 - k * math.log(2) - lnGamma(k));
}

/// 卡方临界值（上尾 alpha）
double chiSquareCritical(int df, double alpha) {
  double lo = 0, hi = 1e4;
  for (var i = 0; i < 100; i++) {
    final mid = (lo + hi) / 2;
    if (chiSquareSf(mid, df) > alpha) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// F 分布 CDF
double fCdf(double f, int df1, int df2) {
  if (f <= 0) return 0;
  final x = df2 / (df2 + df1 * f);
  return 1 - betaInc(df2 / 2.0, df1 / 2.0, x);
}

/// F 上尾 p
double fSf(double f, int df1, int df2) => 1 - fCdf(f, df1, df2);

/// F 临界值
double fCritical(int df1, int df2, double alpha) {
  double lo = 0, hi = 1e5;
  for (var i = 0; i < 100; i++) {
    final mid = (lo + hi) / 2;
    if (fSf(mid, df1, df2) > alpha) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// 正则化不完全 Beta I_x(a,b)
double betaInc(double a, double b, double x) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  final lnBeta = lnGamma(a) + lnGamma(b) - lnGamma(a + b);
  final front = math.exp(math.log(x) * a + math.log(1 - x) * b - lnBeta) / a;
  double f = 1, c = 1, d = 0;
  for (var i = 0; i <= 250; i++) {
    final m = i ~/ 2;
    double num;
    if (i == 0) {
      num = 1;
    } else if (i.isOdd) {
      num = -(a + m) * (a + b + m) * x / ((a + 2 * m) * (a + 2 * m + 1));
    } else {
      num = m * (b - m) * x / ((a + 2 * m - 1) * (a + 2 * m));
    }
    d = 1 + num * d;
    if (d.abs() < 1e-30) d = 1e-30;
    d = 1 / d;
    c = 1 + num / c;
    if (c.abs() < 1e-30) c = 1e-30;
    f *= c * d;
    if ((1 - c * d).abs() < 1e-13) break;
  }
  return front * (f - 1);
}

/// ln Γ(x)（Lanczos 近似）
double lnGamma(double x) {
  const g = 7;
  const c = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  if (x < 0.5) {
    return math.log(math.pi / math.sin(math.pi * x)) - lnGamma(1 - x);
  }
  final xx = x - 1;
  double a = c[0];
  final t = xx + g + 0.5;
  for (var i = 1; i < g + 2; i++) {
    a += c[i] / (xx + i);
  }
  return 0.5 * math.log(2 * math.pi) +
      (xx + 0.5) * math.log(t) -
      t +
      math.log(a);
}

double gammaFn(double x) => math.exp(lnGamma(x));

/// 下不完全 gamma P(s,x)（正则化，返回 0..1）
double lowerIncGamma(double s, double x) {
  if (x <= 0) return 0;
  if (x < s + 1) {
    double sum = 1 / s;
    double term = 1 / s;
    for (var n = 1; n < 400; n++) {
      term *= x / (s + n);
      sum += term;
      if (term.abs() < 1e-15 * (sum.abs() + 1e-30)) break;
    }
    return (sum * math.exp(-x + s * math.log(x) - lnGamma(s))).clamp(0.0, 1.0);
  }
  return (1 - upperIncGamma(s, x)).clamp(0.0, 1.0);
}

/// 上不完全 gamma Q(s,x)（正则化，返回 0..1）
double upperIncGamma(double s, double x) {
  if (x <= 0) return 1;
  double b = x + 1 - s;
  double c = 1e300;
  double d = 1 / b;
  double h = d;
  for (var i = 1; i < 400; i++) {
    final an = -i * (i - s);
    b += 2;
    d = an * d + b;
    if (d.abs() < 1e-300) d = 1e-300;
    c = b + an / c;
    if (c.abs() < 1e-300) c = 1e-300;
    d = 1 / d;
    final del = d * c;
    h *= del;
    if ((del - 1).abs() < 1e-13) break;
  }
  return (math.exp(-x + s * math.log(x) - lnGamma(s)) * h).clamp(0.0, 1.0);
}

/// 组合数 C(n,k)
double combinations(int n, int k) {
  if (k < 0 || k > n) return 0;
  return math.exp(lnGamma(n + 1) - lnGamma(k + 1) - lnGamma(n - k + 1));
}

/// 二项分布 P(X = k)
double binomialPmf(int k, int n, double p) {
  if (k < 0 || k > n) return 0;
  return combinations(n, k) *
      math.pow(p, k).toDouble() *
      math.pow(1 - p, n - k).toDouble();
}

/// 二项分布上尾 P(X >= k)
double binomialSf(int k, int n, double p) {
  double s = 0;
  for (var i = k; i <= n; i++) {
    s += binomialPmf(i, n, p);
  }
  return s.clamp(0.0, 1.0);
}

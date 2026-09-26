/// 假设检验：t 检验、ANOVA、卡方、Levene
library;

import 'dart:math' as math;

import 'descriptives.dart';
import 'distributions.dart';

// ── t 检验 ───────────────────────────────────────────────

class TTestResult {
  final String mode;
  final double t;
  final double df;
  final double pTwoTail;
  final double pOneTail;
  final double meanDiff;
  final double seDiff;
  final double ciLower95;
  final double ciUpper95;
  final double cohensD;
  final double mean1;
  final double mean2;
  final int n1;
  final int n2;
  final double sd1;
  final double sd2;
  final double? leveneF;
  final double? leveneP;
  final bool equalVarAssumed;

  const TTestResult({
    required this.mode,
    required this.t,
    required this.df,
    required this.pTwoTail,
    required this.pOneTail,
    required this.meanDiff,
    required this.seDiff,
    required this.ciLower95,
    required this.ciUpper95,
    required this.cohensD,
    required this.mean1,
    required this.mean2,
    required this.n1,
    required this.n2,
    required this.sd1,
    required this.sd2,
    this.leveneF,
    this.leveneP,
    this.equalVarAssumed = true,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode,
        't': t,
        'df': df,
        'pTwoTail': pTwoTail,
        'pOneTail': pOneTail,
        'meanDiff': meanDiff,
        'seDiff': seDiff,
        'ciLower95': ciLower95,
        'ciUpper95': ciUpper95,
        'cohensD': cohensD,
        'mean1': mean1,
        'mean2': mean2,
        'n1': n1,
        'n2': n2,
        'sd1': sd1,
        'sd2': sd2,
        'leveneF': leveneF,
        'leveneP': leveneP,
        'equalVarAssumed': equalVarAssumed,
      };
}

class TTest {
  /// 单样本 t 检验
  static TTestResult oneSample(List<double> data, {required double mu0}) {
    final d = Descriptives.compute(data);
    final se = d.se;
    final t = se > 0 ? (d.mean - mu0) / se : double.nan;
    final df = (d.n - 1).toDouble();
    final half = tCritical(d.n > 1 ? d.n - 1 : 1, 0.05) * se;
    return TTestResult(
      mode: 'one-sample',
      t: t,
      df: df,
      pTwoTail: tTwoTail(t, d.n - 1),
      pOneTail: tUpper(t.abs(), d.n - 1),
      meanDiff: d.mean - mu0,
      seDiff: se,
      ciLower95: d.mean - half,
      ciUpper95: d.mean + half,
      cohensD: d.sd > 0 ? (d.mean - mu0) / d.sd : double.nan,
      mean1: d.mean,
      mean2: mu0,
      n1: d.n,
      n2: 1,
      sd1: d.sd,
      sd2: 0,
    );
  }

  /// 独立样本 t 检验（自动 Levene → 方差齐/不齐）
  static TTestResult independentSamples(
    List<double> g1,
    List<double> g2, {
    bool autoWelch = true,
  }) {
    final d1 = Descriptives.compute(g1);
    final d2 = Descriptives.compute(g2);
    final lev = leveneTest([g1, g2]);
    final homo = lev.p > 0.05;
    final usePooled = homo || !autoWelch;

    double t, df, se, meanDiff = d1.mean - d2.mean;
    double sp = 0;
    if (usePooled) {
      final df1 = d1.n - 1, df2 = d2.n - 1;
      df = (df1 + df2).toDouble();
      sp = math.sqrt(
          (df1 * d1.variance + df2 * d2.variance) / math.max(df, 1));
      se = sp * math.sqrt(1 / d1.n + 1 / d2.n);
      t = se > 0 ? meanDiff / se : double.nan;
    } else {
      final v1 = d1.variance / d1.n;
      final v2 = d2.variance / d2.n;
      se = math.sqrt(v1 + v2);
      t = se > 0 ? meanDiff / se : double.nan;
      df = (v1 + v2) * (v1 + v2) /
          ((v1 * v1) / (d1.n - 1) + (v2 * v2) / (d2.n - 1));
    }
    final dfi = df.round().clamp(1, 100000);
    final half = tCritical(dfi, 0.05) * se;
    final pooledSd = usePooled
        ? sp
        : math.sqrt((d1.variance + d2.variance) / 2);

    return TTestResult(
      mode: 'independent',
      t: t,
      df: df,
      pTwoTail: tTwoTail(t, dfi),
      pOneTail: tUpper(t.abs(), dfi),
      meanDiff: meanDiff,
      seDiff: se,
      ciLower95: meanDiff - half,
      ciUpper95: meanDiff + half,
      cohensD: pooledSd > 0 ? meanDiff / pooledSd : double.nan,
      mean1: d1.mean,
      mean2: d2.mean,
      n1: d1.n,
      n2: d2.n,
      sd1: d1.sd,
      sd2: d2.sd,
      leveneF: lev.f,
      leveneP: lev.p,
      equalVarAssumed: usePooled,
    );
  }

  /// 配对样本 t 检验
  static TTestResult paired(List<double> a, List<double> b) {
    final n = math.min(a.length, b.length);
    final diffs = List.generate(n, (i) => a[i] - b[i]);
    final r = oneSample(diffs, mu0: 0);
    final d1 = Descriptives.compute(a);
    final d2 = Descriptives.compute(b);
    return TTestResult(
      mode: 'paired',
      t: r.t,
      df: r.df,
      pTwoTail: r.pTwoTail,
      pOneTail: r.pOneTail,
      meanDiff: r.meanDiff,
      seDiff: r.seDiff,
      ciLower95: r.ciLower95,
      ciUpper95: r.ciUpper95,
      cohensD: r.cohensD,
      mean1: d1.mean,
      mean2: d2.mean,
      n1: n,
      n2: n,
      sd1: d1.sd,
      sd2: d2.sd,
    );
  }
}

// ── Levene ───────────────────────────────────────────────

class LeveneResult {
  final double f;
  final double p;
  final int df1;
  final int df2;
  final List<double> groupVariances;
  final List<double> groupMeans;
  final List<int> groupN;
  const LeveneResult({
    required this.f,
    required this.p,
    required this.df1,
    required this.df2,
    required this.groupVariances,
    required this.groupMeans,
    required this.groupN,
  });
}

/// Levene 方差齐性（默认 Brown-Forsythe：绝对离差对中位数）
LeveneResult leveneTest(List<List<double>> groups, {bool useMean = false}) {
  final gs = groups.where((g) => g.length >= 2).toList();
  final k = gs.length;
  if (k < 2) {
    return LeveneResult(
      f: double.nan,
      p: double.nan,
      df1: 0,
      df2: 0,
      groupVariances: const [],
      groupMeans: const [],
      groupN: const [],
    );
  }
  final zBars = <double>[];
  final zs = <List<double>>[];
  for (final g in gs) {
    final s = List.of(g)..sort();
    final center = useMean
        ? g.reduce((a, b) => a + b) / g.length
        : percentile(s, 50);
    final z = g.map((x) => (x - center).abs()).toList();
    zs.add(z);
    zBars.add(z.reduce((a, b) => a + b) / z.length);
  }
  final allZ = zs.expand((e) => e).toList();
  final grand = allZ.reduce((a, b) => a + b) / allZ.length;
  double ssb = 0, ssw = 0;
  for (var i = 0; i < k; i++) {
    ssb += zs[i].length * math.pow(zBars[i] - grand, 2);
    for (final z in zs[i]) {
      ssw += math.pow(z - zBars[i], 2);
    }
  }
  final df1 = k - 1;
  final df2 = allZ.length - k;
  final f = (df2 > 0 && ssw > 0) ? (ssb / df1) / (ssw / df2) : double.nan;
  return LeveneResult(
    f: f,
    p: fSf(f, df1, df2),
    df1: df1,
    df2: df2,
    groupVariances: gs.map((g) => Descriptives.compute(g).variance).toList(),
    groupMeans: gs.map((g) => Descriptives.compute(g).mean).toList(),
    groupN: gs.map((g) => g.length).toList(),
  );
}

// ── 单因素 ANOVA ─────────────────────────────────────────

class AnovaGroup {
  final String label;
  final int n;
  final double mean;
  final double sd;
  final double variance;
  const AnovaGroup({
    required this.label,
    required this.n,
    required this.mean,
    required this.sd,
    required this.variance,
  });
}

class AnovaResult {
  final double f;
  final double p;
  final int dfBetween;
  final int dfWithin;
  final double ssBetween;
  final double ssWithin;
  final double ssTotal;
  final double msBetween;
  final double msWithin;
  final double etaSquared;
  final double omegaSquared;
  final List<AnovaGroup> groups;
  final LeveneResult levene;
  final double grandMean;
  final int nTotal;

  const AnovaResult({
    required this.f,
    required this.p,
    required this.dfBetween,
    required this.dfWithin,
    required this.ssBetween,
    required this.ssWithin,
    required this.ssTotal,
    required this.msBetween,
    required this.msWithin,
    required this.etaSquared,
    required this.omegaSquared,
    required this.groups,
    required this.levene,
    required this.grandMean,
    required this.nTotal,
  });
}

class OnewayAnova {
  static AnovaResult compute(List<List<double>> rawGroups,
      {List<String>? labels}) {
    final entries = <(String, List<double>)>[];
    for (var i = 0; i < rawGroups.length; i++) {
      final g = rawGroups[i].where((x) => x.isFinite).toList();
      if (g.isEmpty) continue;
      entries.add((labels != null && i < labels.length ? labels[i] : 'G${i + 1}', g));
    }
    final k = entries.length;
    final all = entries.expand((e) => e.$2).toList();
    final nTotal = all.length;
    final grand = all.reduce((a, b) => a + b) / nTotal;

    double ssb = 0, ssw = 0;
    final groups = <AnovaGroup>[];
    for (final (label, g) in entries) {
      final d = Descriptives.compute(g);
      ssb += g.length * math.pow(d.mean - grand, 2);
      ssw += (g.length - 1) * d.variance;
      groups.add(AnovaGroup(
        label: label,
        n: d.n,
        mean: d.mean,
        sd: d.sd,
        variance: d.variance,
      ));
    }
    final sst = ssb + ssw;
    final dfb = k - 1;
    final dfw = nTotal - k;
    final msb = dfb > 0 ? ssb / dfb : double.nan;
    final msw = dfw > 0 ? ssw / dfw : double.nan;
    final f = msw > 0 ? msb / msw : double.nan;
    final eta2 = sst > 0 ? ssb / sst : 0.0;
    final omega2 = (ssb - dfb * msw) / (sst + msw);

    return AnovaResult(
      f: f,
      p: fSf(f, dfb, dfw),
      dfBetween: dfb,
      dfWithin: dfw,
      ssBetween: ssb,
      ssWithin: ssw,
      ssTotal: sst,
      msBetween: msb,
      msWithin: msw,
      etaSquared: eta2,
      omegaSquared: omega2 < 0 ? 0 : omega2,
      groups: groups,
      levene: leveneTest(entries.map((e) => e.$2).toList()),
      grandMean: grand,
      nTotal: nTotal,
    );
  }
}

// ── 卡方 ─────────────────────────────────────────────────

class ChiSquareCell {
  final double observed;
  final double expected;
  final double residual; // O-E
  final double stdResidual;
  const ChiSquareCell({
    required this.observed,
    required this.expected,
    required this.residual,
    required this.stdResidual,
  });
}

class ChiSquareResult {
  final double chiSquare;
  final int df;
  final double p;
  final double n;
  final List<ChiSquareCell> cells;
  final List<List<double>> observed;
  final List<List<double>> expected;
  final double? cramersV;
  final double? phi;
  final double likelihoodRatio;
  final double pLikelihood;

  const ChiSquareResult({
    required this.chiSquare,
    required this.df,
    required this.p,
    required this.n,
    required this.cells,
    required this.observed,
    required this.expected,
    this.cramersV,
    this.phi,
    required this.likelihoodRatio,
    required this.pLikelihood,
  });
}

class ChiSquareTest {
  /// 拟合优度：观察频数 vs 期望频数（期望可省略 → 均匀）
  static ChiSquareResult goodnessOfFit(
    List<double> observed, {
    List<double>? expected,
  }) {
    final n = observed.fold<double>(0, (a, b) => a + b);
    final k = observed.length;
    final exp = expected ??
        List.generate(k, (_) => n / k);
    double chi = 0, g2 = 0;
    final cells = <ChiSquareCell>[];
    for (var i = 0; i < k; i++) {
      final e = exp[i];
      final o = observed[i];
      final res = o - e;
      final std = e > 0 ? res / math.sqrt(e) : double.nan;
      if (e > 0) {
        chi += res * res / e;
        if (o > 0) g2 += 2 * o * math.log(o / e);
      }
      cells.add(ChiSquareCell(
          observed: o, expected: e, residual: res, stdResidual: std));
    }
    final df = k - 1;
    return ChiSquareResult(
      chiSquare: chi,
      df: df,
      p: chiSquareSf(chi, df),
      n: n,
      cells: cells,
      observed: [observed],
      expected: [exp],
      likelihoodRatio: g2,
      pLikelihood: chiSquareSf(g2, df),
    );
  }

  /// 独立性（列联表 r×c）
  static ChiSquareResult independence(List<List<double>> observed) {
    final r = observed.length;
    final c = observed.first.length;
    final rowSum = List.filled(r, 0.0);
    final colSum = List.filled(c, 0.0);
    double n = 0;
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        rowSum[i] += observed[i][j];
        colSum[j] += observed[i][j];
        n += observed[i][j];
      }
    }
    final expected =
        List.generate(r, (i) => List.generate(c, (j) {
              return (rowSum[i] * colSum[j]) / (n > 0 ? n : 1);
            }));
    double chi = 0, g2 = 0;
    final cells = <ChiSquareCell>[];
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        final o = observed[i][j];
        final e = expected[i][j];
        final res = o - e;
        final std = e > 0 ? res / math.sqrt(e) : double.nan;
        if (e > 0) {
          chi += res * res / e;
          if (o > 0) g2 += 2 * o * math.log(o / e);
        }
        cells.add(ChiSquareCell(
            observed: o, expected: e, residual: res, stdResidual: std));
      }
    }
    final df = (r - 1) * (c - 1);
    final minDim = math.min(r, c) - 1;
    final phiVal = n > 0 ? math.sqrt(chi / n) : double.nan;
    final cramers =
        (n > 0 && minDim > 0) ? math.sqrt(chi / (n * minDim)) : double.nan;
    return ChiSquareResult(
      chiSquare: chi,
      df: df,
      p: chiSquareSf(chi, df),
      n: n,
      cells: cells,
      observed: observed,
      expected: expected,
      phi: phiVal,
      cramersV: cramers,
      likelihoodRatio: g2,
      pLikelihood: chiSquareSf(g2, df),
    );
  }
}

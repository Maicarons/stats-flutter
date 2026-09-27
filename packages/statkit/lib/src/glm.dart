/// GLM：单元 / 双元固定效应 ANOVA（v0.4）
library;

import 'dart:math' as math;

import 'distributions.dart';
import 'hypothesis.dart';

class GlmTerm {
  final String name;
  final double ss;
  final int df;
  final double ms;
  final double f;
  final double p;
  final double partialEta2;
  const GlmTerm({
    required this.name,
    required this.ss,
    required this.df,
    required this.ms,
    required this.f,
    required this.p,
    required this.partialEta2,
  });
}

class GlmResult {
  final List<GlmTerm> terms;
  final double ssError;
  final int dfError;
  final double msError;
  final double ssTotal;
  final double ssModel;
  final double r2;
  final double adjR2;
  final double rmse;
  final int n;
  final int kA;
  final int kB;
  final LeveneResult levene;
  final String yName;

  const GlmResult({
    required this.terms,
    required this.ssError,
    required this.dfError,
    required this.msError,
    required this.ssTotal,
    required this.ssModel,
    required this.r2,
    required this.adjR2,
    required this.rmse,
    required this.n,
    required this.kA,
    required this.kB,
    required this.levene,
    required this.yName,
  });
}

/// 双元方差分析：y ~ A * B
/// cells: Map of (labelA, labelB) → values
GlmResult glmTwoWay(
  Map<(String, String), List<double>> cells, {
  String yName = 'Y',
}) {
  final aLevels = <String>{};
  final bLevels = <String>{};
  cells.forEach((k, v) {
    aLevels.add(k.$1);
    bLevels.add(k.$2);
  });
  final aList = aLevels.toList()..sort();
  final bList = bLevels.toList()..sort();
  final kA = aList.length;
  final kB = bList.length;

  final all = <double>[];
  double sumAll = 0;
  var n = 0;
  for (final v in cells.values) {
    for (final x in v) {
      all.add(x);
      sumAll += x;
      n++;
    }
  }
  final grand = n == 0 ? 0.0 : sumAll / n;

  // cell means and counts
  double ssA = 0, ssB = 0, ssAB = 0, ssE = 0, ssT = 0;
  final aMarg = <String, List<double>>{};
  final bMarg = <String, List<double>>{};
  for (final a in aList) {
    aMarg[a] = [];
  }
  for (final b in bList) {
    bMarg[b] = [];
  }

  for (final e in cells.entries) {
    final vals = e.value;
    if (vals.isEmpty) continue;
    final m = vals.reduce((x, y) => x + y) / vals.length;
    aMarg[e.key.$1]!.addAll(vals);
    bMarg[e.key.$2]!.addAll(vals);
    ssE += vals.fold<double>(0, (s, x) => s + math.pow(x - m, 2).toDouble());
    ssAB += vals.length * math.pow(m - grand, 2).toDouble();
  }

  for (final a in aList) {
    final v = aMarg[a]!;
    if (v.isEmpty) continue;
    final m = v.reduce((x, y) => x + y) / v.length;
    ssA += v.length * math.pow(m - grand, 2).toDouble();
  }
  for (final b in bList) {
    final v = bMarg[b]!;
    if (v.isEmpty) continue;
    final m = v.reduce((x, y) => x + y) / v.length;
    ssB += v.length * math.pow(m - grand, 2).toDouble();
  }
  ssT = all.fold<double>(0, (s, x) => s + math.pow(x - grand, 2).toDouble());
  // interaction = residual after A,B main from cell means — use SS_AB from cells minus mains
  ssAB = math.max(0, ssAB - ssA - ssB);
  ssE = math.max(0, ssT - ssA - ssB - ssAB);

  final dfA = kA - 1;
  final dfB = kB - 1;
  final dfAB = math.max(0, (kA - 1) * (kB - 1));
  final dfE = math.max(1, n - kA * kB);
  final msE = ssE / dfE;

  double eta(double ss) => ssT > 0 ? ss / (ss + ssE) : 0;

  GlmTerm mk(String name, double ss, int df) {
    final ms = df > 0 ? ss / df : double.nan;
    final f = (msE > 0 && df > 0) ? ms / msE : double.nan;
    return GlmTerm(
      name: name,
      ss: ss,
      df: df,
      ms: ms,
      f: f,
      p: df > 0 ? fSf(f, df, dfE) : double.nan,
      partialEta2: eta(ss),
    );
  }

  final groupsForLevene = <List<double>>[
    for (final v in cells.values)
      if (v.isNotEmpty) v
  ];

  final ssModel = ssA + ssB + ssAB;
  return GlmResult(
    terms: [
      mk('A', ssA, dfA),
      mk('B', ssB, dfB),
      mk('A×B', ssAB, dfAB),
    ],
    ssError: ssE,
    dfError: dfE,
    msError: msE,
    ssTotal: ssT,
    ssModel: ssModel,
    r2: ssT > 0 ? ssModel / ssT : 0,
    adjR2: ssT > 0
        ? 1 - (ssE / dfE) / (ssT / math.max(1, n - 1))
        : 0,
    rmse: math.sqrt(msE),
    n: n,
    kA: kA,
    kB: kB,
    levene: leveneTest(groupsForLevene),
    yName: yName,
  );
}

/// 单元 ANOVA（退化为 OnewayAnova，便于统一接口）
GlmResult glmOneWay(
  Map<String, List<double>> groups, {
  String yName = 'Y',
  String factorName = 'A',
}) {
  // Use two-way with B singleton
  final g = groups;
  final k = g.length;
  final all = g.values.expand((e) => e).toList();
  final n = all.length;
  final grand = n == 0 ? 0.0 : all.reduce((x, y) => x + y) / n;
  double ssA = 0, ssE = 0;
  final forLevene = <List<double>>[];
  for (final e in g.entries) {
    final v = e.value;
    if (v.isEmpty) continue;
    forLevene.add(v);
    final m = v.reduce((x, y) => x + y) / v.length;
    ssA += v.length * math.pow(m - grand, 2).toDouble();
    ssE += v.fold<double>(0, (s, x) => s + math.pow(x - m, 2).toDouble());
  }
  final ssT = all.fold<double>(0, (s, x) => s + math.pow(x - grand, 2).toDouble());
  final dfA = k - 1;
  final dfE = math.max(1, n - k);
  final msA = ssA / dfA;
  final msE = ssE / dfE;
  final f = msE > 0 ? msA / msE : double.nan;
  return GlmResult(
    terms: [
      GlmTerm(
        name: factorName,
        ss: ssA,
        df: dfA,
        ms: msA,
        f: f,
        p: fSf(f, dfA, dfE),
        partialEta2: ssT > 0 ? ssA / ssT : 0,
      ),
    ],
    ssError: ssE,
    dfError: dfE,
    msError: msE,
    ssTotal: ssT,
    ssModel: ssA,
    r2: ssT > 0 ? ssA / ssT : 0,
    adjR2: ssT > 0 ? 1 - (ssE / dfE) / (ssT / math.max(1, n - 1)) : 0,
    rmse: math.sqrt(msE),
    n: n,
    kA: k,
    kB: 1,
    levene: leveneTest(forLevene),
    yName: yName,
  );
}

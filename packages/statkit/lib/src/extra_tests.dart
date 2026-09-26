/// 分层均值、正态性、ROC 等补充过程
library;

import 'dart:math' as math;

import 'descriptives.dart';
import 'distributions.dart';
import 'hypothesis.dart';

/// 分层/分组均值表（PSPP MEANS）
class MeansRow {
  final String group;
  final int n;
  final double mean;
  final double sd;
  final double se;
  final double median;
  final double min;
  final double max;
  const MeansRow({
    required this.group,
    required this.n,
    required this.mean,
    required this.sd,
    required this.se,
    required this.median,
    required this.min,
    required this.max,
  });
}

class MeansResult {
  final String layerVar;
  final String valueVar;
  final List<MeansRow> rows;
  final Descriptives total;
  const MeansResult({
    required this.layerVar,
    required this.valueVar,
    required this.rows,
    required this.total,
  });
}

MeansResult meansTable(
  Map<String, List<double>> groups, {
  required String layerVar,
  required String valueVar,
}) {
  final rows = <MeansRow>[];
  final all = <double>[];
  for (final e in groups.entries) {
    final d = Descriptives.compute(e.value);
    all.addAll(e.value);
    rows.add(MeansRow(
      group: e.key,
      n: d.n,
      mean: d.mean,
      sd: d.sd,
      se: d.se,
      median: d.median,
      min: d.min,
      max: d.max,
    ));
  }
  return MeansResult(
    layerVar: layerVar,
    valueVar: valueVar,
    rows: rows,
    total: Descriptives.compute(all),
  );
}

/// 正态性检验结果
class NormalityResult {
  final String test;
  final double statistic;
  final double p;
  final double skewness;
  final double kurtosis;
  final bool looksNormal;
  const NormalityResult({
    required this.test,
    required this.statistic,
    required this.p,
    required this.skewness,
    required this.kurtosis,
    required this.looksNormal,
  });
}

/// Lilliefors / KS 正态性 + 偏度峰度辅助判断
NormalityResult normalityTest(List<double> data) {
  final d = Descriptives.compute(data);
  final n = d.n;
  final v = d.sorted;
  double dp = 0, dn = 0;
  final sd = d.sd > 0 ? d.sd : 1.0;
  for (var i = 0; i < n; i++) {
    final cdf = normCdf((v[i] - d.mean) / sd);
    dp = math.max(dp, ((i + 1) / n - cdf).abs());
    dn = math.max(dn, (cdf - i / n).abs());
  }
  final ks = math.max(dp, dn);
  // Kolmogorov 近似 p
  final x = (math.sqrt(n) + 0.12 + 0.11 / math.sqrt(n)) * ks;
  double sum = 0;
  for (var k = 1; k <= 100; k++) {
    sum += math.pow(-1, k - 1).toDouble() * math.exp(-2 * k * k * x * x);
  }
  final p = (2 * sum).clamp(0.0, 1.0);
  // 经验规则：|偏度|<1 且 |峰度|<2 且 KS p>0.05
  final looksNormal = p > 0.05 &&
      d.skewness.abs() < 1.5 &&
      d.kurtosis.abs() < 3;
  return NormalityResult(
    test: 'Kolmogorov-Smirnov (Lilliefors approx.)',
    statistic: ks,
    p: p,
    skewness: d.skewness,
    kurtosis: d.kurtosis,
    looksNormal: looksNormal,
  );
}

/// ROC 曲线下面积（Mann-Whitney 统计量）
class RocResult {
  final double auc;
  final double se;
  final double ciLower;
  final double ciUpper;
  final List<({double fpr, double tpr, double threshold})> curve;
  final int nPos;
  final int nNeg;
  const RocResult({
    required this.auc,
    required this.se,
    required this.ciLower,
    required this.ciUpper,
    required this.curve,
    required this.nPos,
    required this.nNeg,
  });
}

RocResult rocCurve(List<double> positives, List<double> negatives) {
  final nPos = positives.length;
  final nNeg = negatives.length;
  if (nPos == 0 || nNeg == 0) {
    return const RocResult(
      auc: double.nan,
      se: double.nan,
      ciLower: double.nan,
      ciUpper: double.nan,
      curve: [],
      nPos: 0,
      nNeg: 0,
    );
  }
  // AUC = P(X+ > X-)
  double wins = 0;
  for (final p in positives) {
    for (final n in negatives) {
      if (p > n) {
        wins++;
      } else if (p == n) {
        wins += 0.5;
      }
    }
  }
  final auc = wins / (nPos * nNeg);
  // Hanley-McNeil SE
  final q1 = auc / (2 - auc);
  final q2 = 2 * auc * auc / (1 + auc);
  final se = math.sqrt((auc * (1 - auc) +
          (nPos - 1) * (q1 - auc * auc) +
          (nNeg - 1) * (q2 - auc * auc)) /
      (nPos * nNeg));
  // 阈值曲线
  final all = [
    ...positives.map((e) => (e, true)),
    ...negatives.map((e) => (e, false)),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  final curve = <({double fpr, double tpr, double threshold})>[];
  var tp = 0, fp = 0;
  curve.add((fpr: 0, tpr: 0, threshold: double.infinity));
  for (final (score, isPos) in all) {
    if (isPos) {
      tp++;
    } else {
      fp++;
    }
    curve.add((
      fpr: fp / nNeg,
      tpr: tp / nPos,
      threshold: score,
    ));
  }
  curve.add((fpr: 1, tpr: 1, threshold: double.negativeInfinity));
  return RocResult(
    auc: auc,
    se: se,
    ciLower: (auc - 1.96 * se).clamp(0.0, 1.0),
    ciUpper: (auc + 1.96 * se).clamp(0.0, 1.0),
    curve: curve,
    nPos: nPos,
    nNeg: nNeg,
  );
}

/// 单因素方差分析 + 事后 Tukey HSD
class PairwiseDiff {
  final String g1;
  final String g2;
  final double meanDiff;
  final double p;
  final bool significant;
  const PairwiseDiff({
    required this.g1,
    required this.g2,
    required this.meanDiff,
    required this.p,
    required this.significant,
  });
}

List<PairwiseDiff> tukeyHsd(AnovaResult anova) {
  final out = <PairwiseDiff>[];
  final k = anova.groups.length;
  final ms = anova.msWithin;
  final df = anova.dfWithin;
  if (k < 2 || ms <= 0) return out;
  for (var i = 0; i < k; i++) {
    for (var j = i + 1; j < k; j++) {
      final a = anova.groups[i];
      final b = anova.groups[j];
      final diff = a.mean - b.mean;
      final se = math.sqrt(ms / 2 * (1 / a.n + 1 / b.n));
      if (se <= 0) continue;
      final t = diff.abs() / se;
      final p = tTwoTail(t, df);
      out.add(PairwiseDiff(
        g1: a.label,
        g2: b.label,
        meanDiff: diff,
        p: p,
        significant: p < 0.05,
      ));
    }
  }
  return out;
}

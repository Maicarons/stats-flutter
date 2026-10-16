/// 分层均值、正态性、ROC 等补充过程
library;

import 'dart:math' as math;

import 'descriptives.dart';
import 'distributions.dart';
import 'hypothesis.dart';
import 'nonparametric.dart';

/// 分层/分组均值表（MEANS）
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

  /// 参数完全指定时的 Kolmogorov 渐近 p（作对照，主 p 是 Lilliefors 修正值）
  final double pKolmogorovAsymptotic;
  final double skewness;
  final double kurtosis;
  final bool looksNormal;
  const NormalityResult({
    required this.test,
    required this.statistic,
    required this.p,
    this.pKolmogorovAsymptotic = double.nan,
    required this.skewness,
    required this.kurtosis,
    required this.looksNormal,
  });
}

/// Lilliefors（K-S，均值方差由样本估计）正态性 + 偏度峰度辅助判断。
///
/// p 值来自 `Nonparametric.kolmogorovSmirnovNormal`（Dallal & Wilkinson 1986
/// 近似），不再用参数完全指定时的 Kolmogorov 渐近式——后者在参数被估计时
/// 会系统性偏大，表现为「几乎不会拒绝正态性」。
NormalityResult normalityTest(List<double> data) {
  final d = Descriptives.compute(data);
  final ks = Nonparametric.kolmogorovSmirnovNormal(data);
  final p = ks.p;
  // 经验规则：|偏度|<1.5 且 |峰度|<3 且 Lilliefors p>0.05
  final looksNormal = p > 0.05 &&
      d.skewness.abs() < 1.5 &&
      d.kurtosis.abs() < 3;
  return NormalityResult(
    test: 'Kolmogorov-Smirnov (Lilliefors)',
    statistic: ks.statistic,
    p: p,
    pKolmogorovAsymptotic:
        ks.extra['pKolmogorovAsymptotic'] as double? ?? double.nan,
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

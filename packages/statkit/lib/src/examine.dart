/// EXAMINE 全套：百分位、极值、茎叶、箱线图数据（v0.3）
library;

import 'dart:math' as math;

import 'descriptives.dart';
import 'distributions.dart';

/// 百分位表（EXAMINE PERCENTILES）
class PercentileRow {
  final double p;
  final double value;
  final bool? statMethods; // 5/10/25/50/75/90/95
  const PercentileRow({required this.p, required this.value, this.statMethods});
}

class PercentileTable {
  final List<PercentileRow> rows;
  final double trimmedMean5;
  final double winsorizedMean5;
  const PercentileTable({
    required this.rows,
    required this.trimmedMean5,
    required this.winsorizedMean5,
  });
}

PercentileTable percentiles(List<double> values, {List<double>? probs}) {
  final v = values.where((x) => x.isFinite).toList()..sort();
  final ps = probs ??
      const [1, 5, 10, 25, 50, 75, 90, 95, 99];
  final rows = ps
      .map((p) => PercentileRow(p: p, value: percentile(v, p)))
      .toList();
  // 5% trimmed / winsorized means
  final n = v.length;
  var trimmed = 0.0, wins = 0.0;
  if (n > 0) {
    final k = (n * 0.05).floor();
    final kept = k < n ~/ 2 ? v.sublist(k, n - k) : v;
    trimmed = kept.isEmpty ? double.nan : kept.reduce((a, b) => a + b) / kept.length;
    final w = List<double>.of(v);
    if (k > 0 && n > 2 * k) {
      for (var i = 0; i < k; i++) {
        w[i] = w[k];
        w[n - 1 - i] = w[n - 1 - k];
      }
    }
    wins = w.reduce((a, b) => a + b) / w.length;
  }
  return PercentileTable(
    rows: rows,
    trimmedMean5: trimmed,
    winsorizedMean5: wins,
  );
}

/// 极值表（Extrim）
class ExtremeRow {
  final int caseIndex;
  final double value;
  const ExtremeRow({required this.caseIndex, required this.value});
}

class ExtremesResult {
  final List<ExtremeRow> lowest;
  final List<ExtremeRow> highest;
  const ExtremesResult({required this.lowest, required this.highest});
}

ExtremesResult extremes(List<double> values, {int nShow = 5}) {
  final indexed = [
    for (var i = 0; i < values.length; i++)
      if (values[i].isFinite) (i, values[i])
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  final k = math.min(nShow, indexed.length);
  return ExtremesResult(
    lowest: [
      for (var i = 0; i < k; i++)
        ExtremeRow(caseIndex: indexed[i].$1 + 1, value: indexed[i].$2)
    ],
    highest: [
      for (var i = 0; i < k; i++)
        ExtremeRow(
            caseIndex: indexed[indexed.length - 1 - i].$1 + 1,
            value: indexed[indexed.length - 1 - i].$2)
    ],
  );
}

/// 箱线图数据
class BoxPlotData {
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final double lowerWhisker;
  final double upperWhisker;
  final List<double> outliers;
  final double iqr;
  final double mean;

  const BoxPlotData({
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.lowerWhisker,
    required this.upperWhisker,
    required this.outliers,
    required this.iqr,
    required this.mean,
  });
}

BoxPlotData boxPlot(List<double> values) {
  final v = values.where((x) => x.isFinite).toList()..sort();
  if (v.isEmpty) {
    return const BoxPlotData(
      min: double.nan,
      q1: double.nan,
      median: double.nan,
      q3: double.nan,
      max: double.nan,
      lowerWhisker: double.nan,
      upperWhisker: double.nan,
      outliers: [],
      iqr: double.nan,
      mean: double.nan,
    );
  }
  final q1 = percentile(v, 25);
  final med = percentile(v, 50);
  final q3 = percentile(v, 75);
  final iqr = q3 - q1;
  final loFence = q1 - 1.5 * iqr;
  final hiFence = q3 + 1.5 * iqr;
  final outliers = v.where((x) => x < loFence || x > hiFence).toList();
  final inliers = v.where((x) => x >= loFence && x <= hiFence);
  final lower = inliers.isEmpty ? v.first : inliers.reduce(math.min);
  final upper = inliers.isEmpty ? v.last : inliers.reduce(math.max);
  return BoxPlotData(
    min: v.first,
    q1: q1,
    median: med,
    q3: q3,
    max: v.last,
    lowerWhisker: lower,
    upperWhisker: upper,
    outliers: outliers,
    iqr: iqr,
    mean: v.reduce((a, b) => a + b) / v.length,
  );
}

/// 多组箱线图数据
List<BoxPlotData> boxPlotGroups(List<List<double>> groups) =>
    groups.map(boxPlot).toList();

/// 茎叶图（stem-and-leaf）
class StemLeafRow {
  final String stem;
  final String leaf;
  final int frequency;
  const StemLeafRow({
    required this.stem,
    required this.leaf,
    required this.frequency,
  });
}

class StemLeafResult {
  final List<StemLeafRow> rows;
  final double unit; // each leaf = unit
  final String header;
  const StemLeafResult({
    required this.rows,
    required this.unit,
    required this.header,
  });
}

StemLeafResult stemAndLeaf(List<double> values, {double? unit}) {
  final v = values.where((x) => x.isFinite).toList()..sort();
  if (v.isEmpty) {
    return const StemLeafResult(
        rows: [], unit: 1, header: 'empty');
  }
  final range = v.last - v.first;
  double u = unit ??
      (range > 50
          ? 10
          : range > 5
              ? 1
              : range > 0.5
                  ? 0.1
                  : 0.01);
  final stems = <int, List<int>>{};
  for (final x in v) {
    final stem = (x / u).floor();
    final leaf = ((x - stem * u) / u).round().clamp(0, 9).toInt();
    stems.putIfAbsent(stem, () => []).add(leaf);
  }
  final keys = stems.keys.toList()..sort();
  final rows = keys.map((s) {
    final leaves = (stems[s]!..sort()).join();
    return StemLeafRow(
      stem: '${s * u}',
      leaf: leaves,
      frequency: stems[s]!.length,
    );
  }).toList();
  return StemLeafResult(
    rows: rows,
    unit: u,
    header: 'Stem unit = $u, each leaf = 1',
  );
}

/// Q-Q 图点（正态）
class QQPoint {
  final double theoretical;
  final double sample;
  const QQPoint({required this.theoretical, required this.sample});
}

List<QQPoint> normalQQPoints(List<double> values) {
  final v = values.where((x) => x.isFinite).toList()..sort();
  final n = v.length;
  if (n < 2) return [];
  final out = <QQPoint>[];
  for (var i = 0; i < n; i++) {
    // Blom plotting position
    final p = (i + 1 - 0.375) / (n + 0.25);
    final z = normalQuantile(p);
    out.add(QQPoint(theoretical: z, sample: v[i]));
  }
  // also normalize sample optionally
  return out;
}

/// 将样本标准化后的 Q-Q 点
List<QQPoint> normalQQPointsStandardized(List<double> values) {
  final d = Descriptives.compute(values);
  final scale = d.sd > 0 ? d.sd : 1.0;
  return normalQQPoints(values)
      .map((p) => QQPoint(theoretical: p.theoretical, sample: (p.sample - d.mean) / scale))
      .toList();
}


/// 误差条数据（均值 ± k·SE 或 CI）
class ErrorBarData {
  final String label;
  final double mean;
  final double low;
  final double high;
  final double se;
  final int n;
  const ErrorBarData({
    required this.label,
    required this.mean,
    required this.low,
    required this.high,
    required this.se,
    required this.n,
  });
}

List<ErrorBarData> errorBarsFromGroups(
  Map<String, List<double>> groups, {
  double z = 1.96,
}) {
  return groups.entries.map((e) {
    final d = Descriptives.compute(e.value);
    final half = z * d.se;
    return ErrorBarData(
      label: e.key,
      mean: d.mean,
      low: d.mean - half,
      high: d.mean + half,
      se: d.se,
      n: d.n,
    );
  }).toList();
}

/// D'Agostino-Pearson 正态性（偏度/峰度联合）——近似 Shapiro-Wilk 意图
class NormalityDP {
  final double zSkew;
  final double pSkew;
  final double zKurt;
  final double pKurt;
  final double chiSquare;
  final double p;
  final bool looksNormal;
  const NormalityDP({
    required this.zSkew,
    required this.pSkew,
    required this.zKurt,
    required this.pKurt,
    required this.chiSquare,
    required this.p,
    required this.looksNormal,
  });
}

NormalityDP dagostinoPearson(List<double> values) {
  final d = Descriptives.compute(values);
  final n = d.n;
  if (n < 8) {
    return const NormalityDP(
      zSkew: double.nan,
      pSkew: double.nan,
      zKurt: double.nan,
      pKurt: double.nan,
      chiSquare: double.nan,
      p: double.nan,
      looksNormal: false,
    );
  }
  // Skewness Z
  final b1 = d.skewness;
  final y = b1 * math.sqrt((n + 1) * (n + 3) / (6.0 * (n - 2)));
  final beta2 = 3 * (n * n + 27 * n - 70) * (n + 1) * (n + 3) /
      ((n - 2) * (n + 5) * (n + 7) * (n + 9));
  final w2 = -1 + math.sqrt(2 * (beta2 - 1));
  final delta = 1 / math.sqrt(math.log(math.sqrt(w2)));
  final alpha = math.sqrt(2 / (w2 - 1));
  final zSkew = delta * math.log(y / alpha + math.sqrt(y * y / (alpha * alpha) + 1));

  // Kurtosis Z (excess)
  final b2 = d.kurtosis;
  final meanB2 = -6.0 / (n + 1);
  final varB2 = 24.0 * n * (n - 2) * (n - 3) /
      ((n + 1) * (n + 1) * (n + 3) * (n + 5));
  final x = (b2 - meanB2) / math.sqrt(varB2);
  final sqrtB1 = 6 * (n * n - 5 * n + 2) /
      ((n + 7) * (n + 9)) *
      math.sqrt(6 * (n + 3) * (n + 5) / (n * (n - 2) * (n - 3)));
  final A = 6 + 8 / sqrtB1 * (2 / sqrtB1 + math.sqrt(1 + 4 / (sqrtB1 * sqrtB1)));
  final term = 1 - 2 / (9 * A);
  final denom = 1 + x * math.sqrt(2 / (A - 4));
  final zKurt = (1 - 2 / (9 * A) - math.pow(term / denom, 1 / 3)) /
      math.sqrt(2 / (9 * A));

  final chi = zSkew * zSkew + zKurt * zKurt;
  final p = chiSquareSf(chi, 2);
  return NormalityDP(
    zSkew: zSkew,
    pSkew: normTwoTail(zSkew),
    zKurt: zKurt,
    pKurt: normTwoTail(zKurt),
    chiSquare: chi,
    p: p,
    looksNormal: p > 0.05,
  );
}

/// 完整 EXAMINE 结果包
class ExamineResult {
  final Descriptives desc;
  final PercentileTable percentiles;
  final ExtremesResult extremes;
  final BoxPlotData box;
  final StemLeafResult stemLeaf;
  final List<QQPoint> qq;
  final NormalityDP normality;
  const ExamineResult({
    required this.desc,
    required this.percentiles,
    required this.extremes,
    required this.box,
    required this.stemLeaf,
    required this.qq,
    required this.normality,
  });
}

ExamineResult examine(List<double> values, {int extremesCount = 5}) {
  final v = values.where((x) => x.isFinite).toList();
  return ExamineResult(
    desc: Descriptives.compute(v),
    percentiles: percentiles(v),
    extremes: extremes(v, nShow: extremesCount),
    box: boxPlot(v),
    stemLeaf: stemAndLeaf(v),
    qq: normalQQPoints(v),
    normality: dagostinoPearson(v),
  );
}

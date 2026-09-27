/// 加权统计与 SPLIT FILE 分组辅助（v0.2）
library;

import 'dart:math' as math;

import 'correlation.dart';
import 'distributions.dart';
import 'hypothesis.dart';

/// 加权描述统计（频数权：每个观测代表 w 个个案）
class WeightedDescriptives {
  final int nUnweighted;
  final double nWeighted;
  final double mean;
  final double variance;
  final double sd;
  final double se;
  final double min;
  final double max;
  final double sumW;
  final double sumWX;
  final double sumWX2;
  final double? ciLower95;
  final double? ciUpper95;

  const WeightedDescriptives({
    required this.nUnweighted,
    required this.nWeighted,
    required this.mean,
    required this.variance,
    required this.sd,
    required this.se,
    required this.min,
    required this.max,
    required this.sumW,
    required this.sumWX,
    required this.sumWX2,
    this.ciLower95,
    this.ciUpper95,
  });

  /// values + 权重（freq weight，w>0）；缺失/非有限值跳过
  static WeightedDescriptives compute(List<double> values, List<double> weights) {
    final n = math.min(values.length, weights.length);
    double sw = 0, swx = 0, swx2 = 0;
    var min = double.infinity;
    var max = double.negativeInfinity;
    var used = 0;
    for (var i = 0; i < n; i++) {
      final x = values[i];
      final w = weights[i];
      if (!x.isFinite || !w.isFinite || w <= 0) continue;
      used++;
      sw += w;
      swx += w * x;
      swx2 += w * x * x;
      if (x < min) min = x;
      if (x > max) max = x;
    }
    if (sw <= 0 || used == 0) {
      return const WeightedDescriptives(
        nUnweighted: 0,
        nWeighted: 0,
        mean: double.nan,
        variance: double.nan,
        sd: double.nan,
        se: double.nan,
        min: double.nan,
        max: double.nan,
        sumW: 0,
        sumWX: 0,
        sumWX2: 0,
      );
    }
    final mean = swx / sw;
    // 频数权方差：Σw(x-μ)² / (Σw - 1)
    final ss = swx2 - 2 * mean * swx + mean * mean * sw;
    final variance = sw > 1 ? ss / (sw - 1) : 0.0;
    final sd = math.sqrt(variance);
    final se = sd / math.sqrt(sw);
    final df = (sw - 1).clamp(1, 100000000).toInt();
    final half = tCritical(df, 0.05) * se;
    return WeightedDescriptives(
      nUnweighted: used,
      nWeighted: sw,
      mean: mean,
      variance: variance,
      sd: sd,
      se: se,
      min: min,
      max: max,
      sumW: sw,
      sumWX: swx,
      sumWX2: swx2,
      ciLower95: mean - half,
      ciUpper95: mean + half,
    );
  }
}

/// 加权单样本 t
class WeightedTTest {
  static TTestResult oneSample(
    List<double> data,
    List<double> weights, {
    required double mu0,
  }) {
    final w = WeightedDescriptives.compute(data, weights);
    final t = w.se > 0 ? (w.mean - mu0) / w.se : double.nan;
    final df = (w.nWeighted - 1).clamp(1, 100000000).toInt();
    return TTestResult(
      mode: 'weighted-one-sample',
      t: t,
      df: df.toDouble(),
      pTwoTail: tTwoTail(t, df),
      pOneTail: tUpper(t.abs(), df),
      meanDiff: w.mean - mu0,
      seDiff: w.se,
      ciLower95: w.ciLower95 ?? double.nan,
      ciUpper95: w.ciUpper95 ?? double.nan,
      cohensD: w.sd > 0 ? (w.mean - mu0) / w.sd : double.nan,
      mean1: w.mean,
      mean2: mu0,
      n1: w.nUnweighted,
      n2: 1,
      sd1: w.sd,
      sd2: 0,
    );
  }

  /// 加权独立样本 t（合并方差）
  static TTestResult independent(
    List<double> a,
    List<double> wa,
    List<double> b,
    List<double> wb,
  ) {
    final da = WeightedDescriptives.compute(a, wa);
    final db = WeightedDescriptives.compute(b, wb);
    final df1 = (da.nWeighted - 1).clamp(1, 100000000).toInt();
    final df2 = (db.nWeighted - 1).clamp(1, 100000000).toInt();
    final df = (df1 + df2).toDouble();
    final sp = math.sqrt(
        (df1 * da.variance + df2 * db.variance) / math.max(df, 1));
    final se = sp * math.sqrt(1 / da.nWeighted + 1 / db.nWeighted);
    final meanDiff = da.mean - db.mean;
    final t = se > 0 ? meanDiff / se : double.nan;
    final dfi = df.round().clamp(1, 100000);
    final half = tCritical(dfi, 0.05) * se;
    return TTestResult(
      mode: 'weighted-independent',
      t: t,
      df: df,
      pTwoTail: tTwoTail(t, dfi),
      pOneTail: tUpper(t.abs(), dfi),
      meanDiff: meanDiff,
      seDiff: se,
      ciLower95: meanDiff - half,
      ciUpper95: meanDiff + half,
      cohensD: sp > 0 ? meanDiff / sp : double.nan,
      mean1: da.mean,
      mean2: db.mean,
      n1: da.nUnweighted,
      n2: db.nUnweighted,
      sd1: da.sd,
      sd2: db.sd,
      equalVarAssumed: true,
    );
  }
}

/// 加权 Pearson 相关
class WeightedCorrelation {
  static CorrelationResult pearson(
    List<double> x,
    List<double> y,
    List<double> w,
  ) {
    final n = math.min(x.length, math.min(y.length, w.length));
    double sw = 0, sx = 0, sy = 0, sxx = 0, syy = 0, sxy = 0;
    var used = 0;
    for (var i = 0; i < n; i++) {
      if (!x[i].isFinite || !y[i].isFinite || !w[i].isFinite || w[i] <= 0) {
        continue;
      }
      used++;
      sw += w[i];
      sx += w[i] * x[i];
      sy += w[i] * y[i];
      sxx += w[i] * x[i] * x[i];
      syy += w[i] * y[i] * y[i];
      sxy += w[i] * x[i] * y[i];
    }
    if (used < 3 || sw <= 0) {
      return CorrelationResult(
          r: double.nan, p: double.nan, n: used, t: double.nan);
    }
    final mx = sx / sw, my = sy / sw;
    final cov = sxy - mx * sy - my * sx + sw * mx * my;
    final vx = sxx - 2 * mx * sx + sw * mx * mx;
    final vy = syy - 2 * my * sy + sw * my * my;
    final r = (vx <= 0 || vy <= 0) ? 0.0 : cov / math.sqrt(vx * vy);
    final df = used - 2;
    final t = r.abs() >= 1 ? 1e10 : r * math.sqrt(df / (1 - r * r));
    return CorrelationResult(r: r, p: tTwoTail(t, df), n: used, t: t);
  }
}

/// 加权线性回归（简单最小二乘 + 频数权）
WeightedLinFit weightedSimpleRegression(
  List<double> x,
  List<double> y,
  List<double> w,
) {
  final n = math.min(x.length, math.min(y.length, w.length));
  double sw = 0, sx = 0, sy = 0, sxx = 0, sxy = 0, syy = 0;
  for (var i = 0; i < n; i++) {
    if (!x[i].isFinite || !y[i].isFinite || !w[i].isFinite || w[i] <= 0) {
      continue;
    }
    sw += w[i];
    sx += w[i] * x[i];
    sy += w[i] * y[i];
    sxx += w[i] * x[i] * x[i];
    sxy += w[i] * x[i] * y[i];
    syy += w[i] * y[i] * y[i];
  }
  final mx = sx / sw, my = sy / sw;
  final ssxx = sxx - sw * mx * mx;
  final ssxy = sxy - sw * mx * my;
  final ssyy = syy - sw * my * my;
  final slope = ssxx == 0 ? 0.0 : ssxy / ssxx;
  final intercept = my - slope * mx;
  final r = (ssxx <= 0 || ssyy <= 0) ? 0.0 : ssxy / math.sqrt(ssxx * ssyy);
  final r2 = r * r;
  final ssReg = r2 * ssyy;
  final ssRes = ssyy - ssReg;
  final df = (sw - 2).clamp(1, 100000000).toInt();
  final mse = ssRes / df;
  final seSlope = ssxx > 0 ? math.sqrt(mse / ssxx) : double.nan;
  final seInt = ssxx > 0
      ? math.sqrt(mse * (1 / sw + mx * mx / ssxx))
      : double.nan;
  final tSlope = seSlope > 0 && seSlope.isFinite ? slope / seSlope : double.nan;
  return WeightedLinFit(
    intercept: intercept,
    slope: slope,
    r: r,
    r2: r2,
    seSlope: seSlope,
    seIntercept: seInt,
    tSlope: tSlope,
    pSlope: tTwoTail(tSlope, df),
    ssResidual: ssRes,
    ssRegression: ssReg,
    ssTotal: ssyy,
    dfResidual: df,
    f: mse > 0 ? ssReg / mse : double.nan,
    pF: fSf(mse > 0 ? ssReg / mse : double.nan, 1, df),
    stdErrorEstimate: math.sqrt(mse),
  );
}

/// SPLIT FILE：按分组键拆分行索引
/// 返回 Map<组标签, List<行索引>>
Map<String, List<int>> splitGroups(
  List<Object?> groupColumn, {
  Map<Object?, String>? valueLabels,
}) {
  final out = <String, List<int>>{};
  for (var i = 0; i < groupColumn.length; i++) {
    final raw = groupColumn[i];
    if (raw == null) continue;
    final label = valueLabels != null && valueLabels.containsKey(raw)
        ? valueLabels[raw]!
        : raw.toString();
    out.putIfAbsent(label, () => []).add(i);
  }
  return out;
}

/// 按权重向量过滤后的副本
(List<double> values, List<double> weights) applyWeights(
  List<double> values,
  List<double> weights,
) {
  final n = math.min(values.length, weights.length);
  final v = <double>[];
  final w = <double>[];
  for (var i = 0; i < n; i++) {
    if (weights[i] > 0 && values[i].isFinite) {
      v.add(values[i]);
      w.add(weights[i]);
    }
  }
  return (v, w);
}


/// 加权简单回归结果
class WeightedLinFit {
  final double intercept;
  final double slope;
  final double r;
  final double r2;
  final double seSlope;
  final double seIntercept;
  final double tSlope;
  final double pSlope;
  final double ssResidual;
  final double ssRegression;
  final double ssTotal;
  final int dfResidual;
  final double f;
  final double pF;
  final double stdErrorEstimate;

  const WeightedLinFit({
    required this.intercept,
    required this.slope,
    required this.r,
    required this.r2,
    required this.seSlope,
    required this.seIntercept,
    required this.tSlope,
    required this.pSlope,
    required this.ssResidual,
    required this.ssRegression,
    required this.ssTotal,
    required this.dfResidual,
    required this.f,
    required this.pF,
    required this.stdErrorEstimate,
  });

  double predict(double x) => intercept + slope * x;
}

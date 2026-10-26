/// LOGISTIC 增强：Wald SE、OR CI、分类表、Hosmer-Lemeshow（v0.4）
library;

import 'dart:math' as math;


import 'distributions.dart';

class LogisticWald {
  final String name;
  final double beta;
  final double se;
  final double wald;
  final double df;
  final double p;
  final double oddsRatio;
  final double orLower95;
  final double orUpper95;
  final double ciLower95;
  final double ciUpper95;
  const LogisticWald({
    required this.name,
    required this.beta,
    required this.se,
    required this.wald,
    required this.df,
    required this.p,
    required this.oddsRatio,
    required this.orLower95,
    required this.orUpper95,
    required this.ciLower95,
    required this.ciUpper95,
  });
}

class ClassificationTable {
  final int tp, fp, tn, fn;
  const ClassificationTable({
    required this.tp,
    required this.fp,
    required this.tn,
    required this.fn,
  });
  double get accuracy => (tp + tn) / math.max(1, tp + tn + fp + fn);
  double get sensitivity => tp / math.max(1, tp + fn);
  double get specificity => tn / math.max(1, tn + fp);
  double get precision => tp / math.max(1, tp + fp);
}

class HosmerLemeshow {
  final double chiSquare;
  final int groups;
  final int df;
  final double p;
  const HosmerLemeshow({
    required this.chiSquare,
    required this.groups,
    required this.df,
    required this.p,
  });
}

class LogisticFullResult {
  final List<LogisticWald> coefficients;
  final double logLikelihood;
  final double pseudoR2; // McFadden
  final double omnibusChi;
  final double omnibusP;
  final int dfModel;
  final int n;
  final ClassificationTable table;
  final HosmerLemeshow hl;
  final List<double> probabilities;
  final List<int> actual;
  final List<String> names;

  /// IRLS 实际迭代次数
  final int iterations;

  /// 是否达到收敛判据（未收敛时返回的是最后一个有限迭代点）
  final bool converged;

  const LogisticFullResult({
    required this.coefficients,
    required this.logLikelihood,
    required this.pseudoR2,
    required this.omnibusChi,
    required this.omnibusP,
    required this.dfModel,
    required this.n,
    required this.table,
    required this.hl,
    required this.probabilities,
    required this.actual,
    required this.names,
    this.iterations = 0,
    this.converged = true,
  });
}

/// 二分类逻辑回归（IRLS / 牛顿-拉夫逊），支持 SE / Wald / OR CI
LogisticFullResult logisticRegressionFull(
  List<List<double>> xs,
  List<int> y, {
  List<String>? names,
  double threshold = 0.5,
  int hlGroups = 10,
  int maxIter = 50,
}) {
  final p = xs.length;
  final n = y.length;
  final nameList = (names != null && names.length == p)
      ? names
      : [for (var j = 0; j < p; j++) 'X${j + 1}'];
  final labels = ['(Constant)', ...nameList];

  // 标准化数值稳定的 X
  final means = List<double>.filled(p, 0);
  final stds = List<double>.filled(p, 1);
  for (var j = 0; j < p; j++) {
    final col = xs[j];
    final m = col.reduce((a, b) => a + b) / n;
    means[j] = m;
    final ss = col.fold<double>(0, (a, b) => a + (b - m) * (b - m));
    final s = math.sqrt(ss / (n > 1 ? n - 1 : 1));
    stds[j] = s > 1e-12 ? s : 1;
  }
  final Z = List.generate(n, (i) {
    final row = List<double>.filled(p + 1, 1);
    for (var j = 0; j < p; j++) {
      row[j + 1] = (xs[j][i] - means[j]) / stds[j];
    }
    return row;
  });

  var beta = List<double>.filled(p + 1, 0.0);
  var converged = false;
  var iterations = 0;
  // IRLS（牛顿–拉夫逊）
  for (var iter = 1; iter <= maxIter; iter++) {
    iterations = iter;
    // Hessian and score
    final xtWX = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0));
    final xtWz = List<double>.filled(p + 1, 0);
    for (var i = 0; i < n; i++) {
      var z = 0.0;
      for (var j = 0; j <= p; j++) {
        z += beta[j] * Z[i][j];
      }
      final mu = 1 / (1 + math.exp(-z.clamp(-30, 30)));
      final w = math.max(mu * (1 - mu), 1e-10);
      final residual = y[i] - mu;
      for (var a = 0; a <= p; a++) {
        // 加权工作响应：X'Wz 的第 a 项是 Σ w·x_a·z_work，
        // 而 z_work = η + W⁻¹(y−μ)，左乘 W 后即 w·η + (y−μ)。
        // 原实现写成 z + residual/w（漏了左乘的 w），迭代步长被放大成
        // w⁻¹ 倍，在 μ 靠边（w 小）的样本上会来回震荡、收敛不到极大似然点。
        xtWz[a] += Z[i][a] * (w * z + residual);
        for (var b = 0; b <= p; b++) {
          xtWX[a][b] += w * Z[i][a] * Z[i][b];
        }
        // ridge for separation
      }
    }
    for (var d = 0; d <= p; d++) {
      xtWX[d][d] += 1e-6;
    }
    final newBeta = _solve(xtWX, xtWz);
    var diverged = false;
    for (final v in newBeta) {
      if (!v.isFinite || v.abs() > 20) diverged = true;
    }
    if (diverged) {
      // 完全分离之类：保留上一个有限迭代点，标记未收敛
      break;
    }
    var delta = 0.0;
    for (var j = 0; j <= p; j++) {
      delta = math.max(delta, (newBeta[j] - beta[j]).abs());
      beta[j] = newBeta[j];
    }
    if (delta < 1e-10) {
      converged = true;
      break;
    }
  }

  // Covariance = (X'WX)^-1
  // recompute xtWX at solution
  final xtWX = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0));
  for (var i = 0; i < n; i++) {
    var z = 0.0;
    for (var j = 0; j <= p; j++) {
      z += beta[j] * Z[i][j];
    }
    final mu = 1 / (1 + math.exp(-z.clamp(-30, 30)));
    final w = math.max(mu * (1 - mu), 1e-10);
    for (var a = 0; a <= p; a++) {
      for (var b = 0; b <= p; b++) {
        xtWX[a][b] += w * Z[i][a] * Z[i][b];
      }
    }
  }
  final cov = _invert(xtWX);

  // Metrics
  double ll = 0;
  final probs = <double>[];
  int tp = 0, fp = 0, tn = 0, fn = 0;
  for (var i = 0; i < n; i++) {
    var z = 0.0;
    for (var j = 0; j <= p; j++) {
      z += beta[j] * Z[i][j];
    }
    final mu = 1 / (1 + math.exp(-z.clamp(-30, 30)));
    probs.add(mu);
    final yi = y[i].clamp(0, 1);
    ll += yi == 1 ? math.log(mu.clamp(1e-12, 1)) : math.log((1 - mu).clamp(1e-12, 1));
    final pred = mu >= threshold ? 1 : 0;
    if (yi == 1 && pred == 1) {
      tp++;
    } else if (yi == 0 && pred == 1) {
      fp++;
    } else if (yi == 0 && pred == 0) {
      tn++;
    } else {
      fn++;
    }
  }
  final pi = y.where((e) => e == 1).length / math.max(n, 1);
  double ll0 = 0;
  for (final yi in y) {
    ll0 += yi == 1
        ? math.log(pi.clamp(1e-12, 1))
        : math.log((1 - pi).clamp(1e-12, 1));
  }
  final pseudoR2 = ll0 != 0 ? (1 - ll / ll0).clamp(0.0, 1.0) : 0.0;
  final omnibus = -2 * (ll0 - ll);
  final dfModel = p;

  // 还原到原始尺度：betaOrig = A · betaZ（每个方程共用同一个线性变换）
  //   intercept: β0 − Σ_j β_j·mean_j/sd_j
  //   x_j:       β_j / sd_j
  final a = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0.0));
  a[0][0] = 1;
  for (var j = 0; j < p; j++) {
    a[0][j + 1] = -means[j] / stds[j];
    a[j + 1][j + 1] = 1 / stds[j];
  }
  final betaOrig = List<double>.filled(p + 1, 0);
  for (var r = 0; r <= p; r++) {
    var s = 0.0;
    for (var c = 0; c <= p; c++) {
      s += a[r][c] * beta[c];
    }
    betaOrig[r] = s;
  }
  // 原尺度协方差 = A·cov·A'：截距的标准误必须走这个变换，
  // 直接用标准化尺度上的 SE 是错的（截距是多个 β 的线性组合）。
  final covOrig = List.generate(p + 1, (r) => List<double>.filled(p + 1, 0.0));
  for (var r = 0; r <= p; r++) {
    for (var c = 0; c <= p; c++) {
      var s = 0.0;
      for (var i2 = 0; i2 <= p; i2++) {
        for (var j2 = 0; j2 <= p; j2++) {
          s += a[r][i2] * cov[i2][j2] * a[c][j2];
        }
      }
      covOrig[r][c] = s;
    }
  }
  final coefs = <LogisticWald>[];
  for (var j = 0; j <= p; j++) {
    final se = math.sqrt(math.max(0, covOrig[j][j]));
    final b = betaOrig[j];
    final wald = se > 0 ? (b / se) * (b / se) : double.nan;
    final half = 1.959964 * se;
    final or = math.exp(b.clamp(-30, 30));
    coefs.add(LogisticWald(
      name: labels[j],
      beta: b,
      se: se,
      wald: wald,
      df: 1,
      p: chiSquareSf(wald.isNaN ? 0 : wald, 1),
      oddsRatio: or,
      orLower95: math.exp((b - half).clamp(-30, 30)),
      orUpper95: math.exp((b + half).clamp(-30, 30)),
      ciLower95: b - half,
      ciUpper95: b + half,
    ));
  }

  return LogisticFullResult(
    coefficients: coefs,
    logLikelihood: ll,
    pseudoR2: pseudoR2,
    omnibusChi: omnibus,
    omnibusP: chiSquareSf(omnibus, dfModel),
    dfModel: dfModel,
    n: n,
    table: ClassificationTable(tp: tp, fp: fp, tn: tn, fn: fn),
    hl: hosmerLemeshow(probs, y, groups: hlGroups),
    probabilities: probs,
    actual: y,
    names: labels,
    iterations: iterations,
    converged: converged,
  );
}

HosmerLemeshow hosmerLemeshow(
  List<double> probs,
  List<int> y, {
  int groups = 10,
}) {
  final n = probs.length;
  if (n < groups) groups = math.max(2, n ~/ 2);
  final idx = List.generate(n, (i) => i)
    ..sort((a, b) => probs[a].compareTo(probs[b]));
  double chi = 0;
  var used = 0;
  for (var g = 0; g < groups; g++) {
    final start = g * n ~/ groups;
    final end = (g + 1) * n ~/ groups;
    if (start >= end) continue;
    double og = 0, eg = 0, pm = 0;
    var m = 0;
    for (var k = start; k < end; k++) {
      og += y[idx[k]];
      eg += probs[idx[k]];
      pm += probs[idx[k]] * (1 - probs[idx[k]]);
      m++;
    }
    if (m == 0 || pm <= 1e-12) continue;
    chi += math.pow(og - eg, 2) / pm;
    used++;
  }
  final df = math.max(1, used - 2);
  return HosmerLemeshow(
    chiSquare: chi,
    groups: used,
    df: df,
    p: chiSquareSf(chi, df),
  );
}

/// 多项 logistic 回归的一个系数（某条 logit 方程中的某一项）
class MultinomialWald {
  /// 该方程对应的响应类别（与 [MultinomialResult.reference] 对比）
  final String level;
  final String name;
  final double beta;
  final double se;
  final double wald;
  final double df;
  final double p;
  final double oddsRatio;
  final double orLower95;
  final double orUpper95;
  final double ciLower95;
  final double ciUpper95;
  const MultinomialWald({
    required this.level,
    required this.name,
    required this.beta,
    required this.se,
    required this.wald,
    required this.df,
    required this.p,
    required this.oddsRatio,
    required this.orLower95,
    required this.orUpper95,
    required this.ciLower95,
    required this.ciUpper95,
  });
}

/// 多项 logistic 回归结果（softmax / 参考类别参数化）
class MultinomialResult {
  /// 全部响应类别（升序，即原始响应取值）
  final List<int> levels;

  /// 类别显示名（与 [levels] 一一对应）
  final List<String> levelLabels;

  /// 参考类别（其 logit 恒为 0，不估计）
  final String reference;

  /// 全部系数（按类别分组后展开，便于直接出表）
  final List<MultinomialWald> coefficients;

  /// 按「非参考类别」分组的系数
  final List<List<MultinomialWald>> byLevel;

  /// 每个类别的样本数
  final List<int> levelCounts;

  final double logLikelihood;

  /// 截距唯一模型的似然（零模型）
  final double logLikelihoodNull;

  /// McFadden 伪 R² = 1 − ll / ll0
  final double pseudoR2;

  /// 整体似然比 χ² = −2(ll0 − ll)
  final double lrChi;
  final int dfModel;
  final double lrP;
  final int n;

  /// 类别数 k
  final int k;

  /// n × k 的预测概率
  final List<List<double>> probabilities;
  final List<int> actual;
  final List<int> predicted;

  /// 项名：[reference] 之后的顺序与 [byLevel] 一致
  final List<String> names;

  /// 原始尺度上的协方差（维度 (k−1)(p+1)，按 (方程, 项) 展平）
  final List<List<double>> covariance;

  /// 收敛点上得分向量（梯度）的范数，用于检查是否真的落在极值点
  final double gradientNorm;
  final int iterations;
  final bool converged;

  /// 混淆矩阵：行 = 实际类别，列 = 预测类别（取概率最大者）
  final List<List<int>> confusion;

  /// 整体命中率
  final double accuracy;

  const MultinomialResult({
    required this.levels,
    required this.levelLabels,
    required this.reference,
    required this.coefficients,
    required this.byLevel,
    required this.levelCounts,
    required this.logLikelihood,
    required this.logLikelihoodNull,
    required this.pseudoR2,
    required this.lrChi,
    required this.dfModel,
    required this.lrP,
    required this.n,
    required this.k,
    required this.probabilities,
    required this.actual,
    required this.predicted,
    required this.names,
    required this.covariance,
    required this.gradientNorm,
    required this.iterations,
    required this.converged,
    required this.confusion,
    required this.accuracy,
  });
}

/// 多项 logistic 回归（softmax，牛顿–拉夫逊，参考类别参数化）。
///
/// 对每个非参考类别 c 估计一条 logit η_c = β_c' x：
/// P(y = c) = exp(η_c) / (1 + Σ_{j≠ref} exp(η_j))，参考类别的 β ≡ 0。
/// 默认参考类别取数值最大的类别（SPSS NOMREG 口径），可用 [referenceLevel] 指定。
///
/// [xs] 按「自变量优先」组织（xs[j] 是第 j 个自变量的 n 个观测），与
/// [logisticRegressionFull] 一致；[names] 给变量名，[levelLabels] 给类别显示名
/// （按升序类别一一对应）。
MultinomialResult multinomialLogistic(
  List<List<double>> xs,
  List<int> y, {
  List<String>? names,
  List<String>? levelLabels,
  int? referenceLevel,
  int maxIter = 100,
  double ridge = 1e-6,
  double tol = 1e-10,
}) {
  final n = y.length;
  if (n == 0) throw ArgumentError('数据为空');
  final p = xs.length;
  for (final col in xs) {
    if (col.length != n) throw ArgumentError('自变量与因变量的样本数不一致');
  }
  final levels = y.toSet().toList()..sort();
  final k = levels.length;
  if (k < 2) throw ArgumentError('响应变量至少需要两个类别');
  final refLevel = referenceLevel ?? levels.last;
  final refIdx = levels.indexOf(refLevel);
  if (refIdx < 0) throw ArgumentError('参考类别 $refLevel 不在数据中');
  final nameList = (names != null && names.length == p)
      ? names
      : [for (var j = 0; j < p; j++) 'X${j + 1}'];
  final labels = ['(Constant)', ...nameList];
  final display = (levelLabels != null && levelLabels.length == k)
      ? levelLabels
      : [for (final l in levels) '$l'];
  final otherIdx = [
    for (var i = 0; i < k; i++)
      if (i != refIdx) i
  ];
  final m = k - 1;
  final yi = [for (final v in y) levels.indexOf(v)];
  final levelCounts = List<int>.filled(k, 0);
  for (final v in yi) {
    levelCounts[v]++;
  }
  if (levelCounts[refIdx] == 0) throw ArgumentError('参考类别没有观测');

  // 自变量标准化（与二分类同一套：中心化 + 单位化，最后再还原）
  final means = List<double>.filled(p, 0);
  final stds = List<double>.filled(p, 1);
  for (var j = 0; j < p; j++) {
    final col = xs[j];
    final mu = col.reduce((a, b) => a + b) / n;
    means[j] = mu;
    final ss = col.fold<double>(0, (a, b) => a + (b - mu) * (b - mu));
    final s = math.sqrt(ss / (n > 1 ? n - 1 : 1));
    stds[j] = s > 1e-12 ? s : 1;
  }
  final z = List.generate(n, (i) {
    final row = List<double>.filled(p + 1, 1);
    for (var j = 0; j < p; j++) {
      row[j + 1] = (xs[j][i] - means[j]) / stds[j];
    }
    return row;
  });

  final dim = m * (p + 1);
  final beta = List.generate(m, (_) => List<double>.filled(p + 1, 0.0));
  var converged = false;
  var iterations = 0;

  // 给定 β 时每个观测的类别概率（按最大 η 平移，数值稳定）
  List<List<double>> probabilitiesAt(List<List<double>> b) {
    final prob = List.generate(n, (_) => List<double>.filled(k, 0.0));
    for (var i = 0; i < n; i++) {
      final eta = List<double>.filled(m, 0.0);
      var mx = 0.0; // 参考类别的 η ≡ 0，一起参与取最大值
      for (var t = 0; t < m; t++) {
        var e = 0.0;
        for (var a2 = 0; a2 <= p; a2++) {
          e += b[t][a2] * z[i][a2];
        }
        eta[t] = e;
        mx = math.max(mx, e);
      }
      var sum = math.exp(-mx);
      for (var t = 0; t < m; t++) {
        final v = math.exp(eta[t] - mx);
        eta[t] = v;
        sum += v;
      }
      prob[i][refIdx] = math.exp(-mx) / sum;
      for (var t = 0; t < m; t++) {
        prob[i][otherIdx[t]] = eta[t] / sum;
      }
    }
    return prob;
  }

  // 得分向量（和可选的观测信息阵）
  List<double> scoreAt(List<List<double>> prob, {List<List<double>>? info}) {
    final score = List<double>.filled(dim, 0.0);
    for (var i = 0; i < n; i++) {
      for (var q = 0; q < m; q++) {
        final pq = prob[i][otherIdx[q]];
        final ind = yi[i] == otherIdx[q] ? 1.0 : 0.0;
        for (var a2 = 0; a2 <= p; a2++) {
          score[q * (p + 1) + a2] += (ind - pq) * z[i][a2];
        }
        if (info == null) continue;
        for (var r = 0; r < m; r++) {
          final pr = prob[i][otherIdx[r]];
          final c = (q == r ? pq : 0.0) - pq * pr;
          for (var a2 = 0; a2 <= p; a2++) {
            final za = z[i][a2];
            for (var d = 0; d <= p; d++) {
              info[q * (p + 1) + a2][r * (p + 1) + d] += c * za * z[i][d];
            }
          }
        }
      }
    }
    return score;
  }

  for (var iter = 1; iter <= maxIter; iter++) {
    iterations = iter;
    final prob = probabilitiesAt(beta);
    final info = List.generate(dim, (_) => List<double>.filled(dim, 0.0));
    final score = scoreAt(prob, info: info);
    for (var d = 0; d < dim; d++) {
      info[d][d] += ridge;
    }
    final delta = _solve(info, score);
    var step = 0.0;
    var bad = false;
    for (var q = 0; q < m; q++) {
      for (var a2 = 0; a2 <= p; a2++) {
        final nv = beta[q][a2] + delta[q * (p + 1) + a2];
        if (!nv.isFinite || nv.abs() > 50) bad = true;
        step = math.max(step, (nv - beta[q][a2]).abs());
      }
    }
    if (bad) break; // 完全分离之类：保留上一步结果，标记未收敛
    for (var q = 0; q < m; q++) {
      for (var a2 = 0; a2 <= p; a2++) {
        beta[q][a2] += delta[q * (p + 1) + a2];
      }
    }
    if (step < tol) {
      converged = true;
      break;
    }
  }

  // 收敛点上的概率、得分与信息阵
  final prob = probabilitiesAt(beta);
  final info = List.generate(dim, (_) => List<double>.filled(dim, 0.0));
  final score = scoreAt(prob, info: info);
  final gradientNorm = math.sqrt(score.fold<double>(0, (a2, v) => a2 + v * v));
  for (var d = 0; d < dim; d++) {
    info[d][d] += ridge;
  }
  final covZ = _invert(info);

  // 还原到原始尺度（每个方程同一个线性变换 A）
  final a = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0.0));
  a[0][0] = 1;
  for (var j = 0; j < p; j++) {
    a[0][j + 1] = -means[j] / stds[j];
    a[j + 1][j + 1] = 1 / stds[j];
  }
  final betaOrig = List.generate(m, (_) => List<double>.filled(p + 1, 0.0));
  for (var q = 0; q < m; q++) {
    for (var r = 0; r <= p; r++) {
      var s = 0.0;
      for (var c = 0; c <= p; c++) {
        s += a[r][c] * beta[q][c];
      }
      betaOrig[q][r] = s;
    }
  }
  final covOrig = List.generate(dim, (_) => List<double>.filled(dim, 0.0));
  for (var q = 0; q < m; q++) {
    for (var r = 0; r < m; r++) {
      for (var aa = 0; aa <= p; aa++) {
        for (var bb = 0; bb <= p; bb++) {
          var s = 0.0;
          for (var i2 = 0; i2 <= p; i2++) {
            for (var j2 = 0; j2 <= p; j2++) {
              s += a[aa][i2] *
                  covZ[q * (p + 1) + i2][r * (p + 1) + j2] *
                  a[bb][j2];
            }
          }
          covOrig[q * (p + 1) + aa][r * (p + 1) + bb] = s;
        }
      }
    }
  }

  final byLevel = <List<MultinomialWald>>[];
  final all = <MultinomialWald>[];
  for (var q = 0; q < m; q++) {
    final list = <MultinomialWald>[];
    final lvl = display[otherIdx[q]];
    for (var j = 0; j <= p; j++) {
      final idx = q * (p + 1) + j;
      final se = math.sqrt(math.max(0, covOrig[idx][idx]));
      final b = betaOrig[q][j];
      final wald = se > 0 ? (b / se) * (b / se) : double.nan;
      final half = 1.959964 * se;
      final w = MultinomialWald(
        level: lvl,
        name: labels[j],
        beta: b,
        se: se,
        wald: wald,
        df: 1,
        p: chiSquareSf(wald.isNaN ? 0 : wald, 1),
        oddsRatio: math.exp(b.clamp(-30, 30)),
        orLower95: math.exp((b - half).clamp(-30, 30)),
        orUpper95: math.exp((b + half).clamp(-30, 30)),
        ciLower95: b - half,
        ciUpper95: b + half,
      );
      list.add(w);
      all.add(w);
    }
    byLevel.add(list);
  }

  // 拟合优度与分类
  var ll = 0.0;
  final predicted = <int>[];
  final confusion = List.generate(k, (_) => List<int>.filled(k, 0));
  var hits = 0;
  for (var i = 0; i < n; i++) {
    ll += math.log(prob[i][yi[i]].clamp(1e-300, 1));
    var best = 0;
    for (var c = 1; c < k; c++) {
      if (prob[i][c] > prob[i][best]) best = c;
    }
    predicted.add(levels[best]);
    confusion[yi[i]][best]++;
    if (best == yi[i]) hits++;
  }
  var ll0 = 0.0;
  for (var c = 0; c < k; c++) {
    if (levelCounts[c] == 0) continue;
    final pc = levelCounts[c] / n;
    ll0 += levelCounts[c] * math.log(pc);
  }
  final pseudoR2 = ll0 != 0 ? (1 - ll / ll0).clamp(0.0, 1.0) : 0.0;
  final lrChi = -2 * (ll0 - ll);
  final dfModel = (k - 1) * p;

  return MultinomialResult(
    levels: levels,
    levelLabels: display,
    reference: display[refIdx],
    coefficients: all,
    byLevel: byLevel,
    levelCounts: levelCounts,
    logLikelihood: ll,
    logLikelihoodNull: ll0,
    pseudoR2: pseudoR2,
    lrChi: lrChi,
    dfModel: dfModel,
    lrP: dfModel > 0 ? chiSquareSf(lrChi, dfModel) : double.nan,
    n: n,
    k: k,
    probabilities: prob,
    actual: y,
    predicted: predicted,
    names: labels,
    covariance: covOrig,
    gradientNorm: gradientNorm,
    iterations: iterations,
    converged: converged,
    confusion: confusion,
    accuracy: n > 0 ? hits / n : double.nan,
  );
}

List<double> _solve(List<List<double>> A, List<double> b) {
  final n = A.length;
  final M = List.generate(n, (i) => [...A[i], b[i]]);
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (M[r][col].abs() > M[pivot][col].abs()) pivot = r;
    }
    if (M[pivot][col].abs() < 1e-12) continue;
    final tmp = M[col];
    M[col] = M[pivot];
    M[pivot] = tmp;
    for (var r = 0; r < n; r++) {
      if (r == col) continue;
      final factor = M[r][col] / M[col][col];
      for (var c = col; c <= n; c++) {
        M[r][c] -= factor * M[col][c];
      }
    }
  }
  return List.generate(
      n, (i) => M[i][n] / (M[i][i].abs() < 1e-15 ? 1e-15 : M[i][i]));
}

List<List<double>> _invert(List<List<double>> A) {
  final n = A.length;
  final M = List.generate(n, (i) => [
        ...A[i],
        ...List.generate(n, (j) => i == j ? 1.0 : 0.0)
      ]);
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (M[r][col].abs() > M[pivot][col].abs()) pivot = r;
    }
    if (M[pivot][col].abs() < 1e-12) M[col][col] += 1e-10;
    final tmp = M[col];
    M[col] = M[pivot];
    M[pivot] = tmp;
    final div = M[col][col];
    for (var c = 0; c < 2 * n; c++) {
      M[col][c] /= div;
    }
    for (var r = 0; r < n; r++) {
      if (r == col) continue;
      final factor = M[r][col];
      for (var c = 0; c < 2 * n; c++) {
        M[r][c] -= factor * M[col][c];
      }
    }
  }
  return List.generate(n, (i) => List.generate(n, (j) => M[i][n + j]));
}

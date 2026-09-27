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
  // IRLS
  for (var iter = 0; iter < maxIter; iter++) {
    // Hessian and score
    final XtWX = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0));
    final XtWz = List<double>.filled(p + 1, 0);
    for (var i = 0; i < n; i++) {
      var z = 0.0;
      for (var j = 0; j <= p; j++) {
        z += beta[j] * Z[i][j];
      }
      final mu = 1 / (1 + math.exp(-z.clamp(-30, 30)));
      final w = math.max(mu * (1 - mu), 1e-10);
      final residual = y[i] - mu;
      for (var a = 0; a <= p; a++) {
        XtWz[a] += Z[i][a] * (z + residual / w);
        for (var b = 0; b <= p; b++) {
          XtWX[a][b] += w * Z[i][a] * Z[i][b];
        }
        // ridge for separation
      }
    }
    for (var d = 0; d <= p; d++) {
      XtWX[d][d] += 1e-6;
    }
    final newBeta = _solve(XtWX, XtWz);
    var diverged = false;
    for (final v in newBeta) {
      if (!v.isFinite || v.abs() > 20) diverged = true;
    }
    if (diverged) {
      // keep previous and stop
      break;
    }
    var delta = 0.0;
    for (var j = 0; j <= p; j++) {
      delta = math.max(delta, (newBeta[j] - beta[j]).abs());
      beta[j] = newBeta[j];
    }
    if (delta < 1e-8) break;
  }

  // Covariance = (X'WX)^-1
  // recompute XtWX at solution
  final XtWX = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0));
  for (var i = 0; i < n; i++) {
    var z = 0.0;
    for (var j = 0; j <= p; j++) {
      z += beta[j] * Z[i][j];
    }
    final mu = 1 / (1 + math.exp(-z.clamp(-30, 30)));
    final w = math.max(mu * (1 - mu), 1e-10);
    for (var a = 0; a <= p; a++) {
      for (var b = 0; b <= p; b++) {
        XtWX[a][b] += w * Z[i][a] * Z[i][b];
      }
    }
  }
  final cov = _invert(XtWX);

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

  // Convert beta to original scale
  final betaOrig = List<double>.filled(p + 1, 0);
  betaOrig[0] = beta[0];
  for (var j = 0; j < p; j++) {
    betaOrig[j + 1] = beta[j + 1] / stds[j];
    betaOrig[0] -= beta[j + 1] * means[j] / stds[j];
  }
  // SE on original scale: se_orig_j = se_z_j / sd_j
  final coefs = <LogisticWald>[];
  for (var j = 0; j <= p; j++) {
    final seZ = math.sqrt(math.max(0, cov[j][j]));
    final se = j == 0 ? seZ : seZ / stds[j - 1];
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

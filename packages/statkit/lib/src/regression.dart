/// 回归分析：简单 / 多元线性
library;

import 'dart:math' as math;

import 'distributions.dart';

class RegressionCoefficient {
  final String name;
  final double beta;
  final double stdBeta;
  final double se;
  final double t;
  final double p;
  final double ciLower95;
  final double ciUpper95;
  final double? vif;
  const RegressionCoefficient({
    required this.name,
    required this.beta,
    required this.stdBeta,
    required this.se,
    required this.t,
    required this.p,
    required this.ciLower95,
    required this.ciUpper95,
    this.vif,
  });
}

class RegressionResult {
  final double r;
  final double r2;
  final double adjR2;
  final double f;
  final double pF;
  final int dfModel;
  final int dfResidual;
  final double ssRegression;
  final double ssResidual;
  final double ssTotal;
  final double msRegression;
  final double msResidual;
  final double stdError;
  final double durbinWatson;
  final List<RegressionCoefficient> coefficients;
  final double intercept;
  final List<String> predictors;
  final List<double> fitted;
  final List<double> residuals;
  final List<double> stdResiduals;

  const RegressionResult({
    required this.r,
    required this.r2,
    required this.adjR2,
    required this.f,
    required this.pF,
    required this.dfModel,
    required this.dfResidual,
    required this.ssRegression,
    required this.ssResidual,
    required this.ssTotal,
    required this.msRegression,
    required this.msResidual,
    required this.stdError,
    required this.durbinWatson,
    required this.coefficients,
    required this.intercept,
    required this.predictors,
    required this.fitted,
    required this.residuals,
    required this.stdResiduals,
  });

  double predict(List<double> x) {
    var y = intercept;
    for (var i = 0; i < coefficients.length - 1 && i < x.length; i++) {
      y += coefficients[i + 1].beta * x[i];
    }
    return y;
  }
}

class Regression {
  static RegressionResult simple(List<double> x, List<double> y,
      {String xName = 'X', String yName = 'Y'}) {
    return multiple([x], y, predictorNames: [xName], yName: yName);
  }

  static RegressionResult multiple(
    List<List<double>> xs,
    List<double> y, {
    List<String>? predictorNames,
    String yName = 'Y',
  }) {
    final p = xs.length;
    final n = y.length;
    final names = predictorNames ?? List.generate(p, (i) => 'X${i + 1}');
    if (p == 0 || n < p + 2) {
      throw ArgumentError('样本量不足或预测变量为空');
    }

    final X = List.generate(n, (i) {
      final row = List<double>.filled(p + 1, 1);
      for (var j = 0; j < p; j++) {
        row[j + 1] = xs[j][i];
      }
      return row;
    });

    final xtX = List.generate(p + 1, (_) => List<double>.filled(p + 1, 0));
    final xtY = List<double>.filled(p + 1, 0);
    for (var i = 0; i < n; i++) {
      for (var a = 0; a <= p; a++) {
        xtY[a] += X[i][a] * y[i];
        for (var b = 0; b <= p; b++) {
          xtX[a][b] += X[i][a] * X[i][b];
        }
      }
    }

    final beta = _solve(xtX, xtY);

    final fitted = List<double>.filled(n, 0);
    final resid = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      var f = 0.0;
      for (var j = 0; j <= p; j++) {
        f += X[i][j] * beta[j];
      }
      fitted[i] = f;
      resid[i] = y[i] - f;
    }

    final my = y.reduce((a, b) => a + b) / n;
    double sst = 0, sse = 0;
    for (var i = 0; i < n; i++) {
      sst += math.pow(y[i] - my, 2);
      sse += resid[i] * resid[i];
    }
    final ssr = sst - sse;
    final dfModel = p;
    final dfResid = n - p - 1;
    final msr = ssr / dfModel;
    final mse = sse / dfResid;
    final f = mse > 0 ? msr / mse : double.nan;
    final r2 = sst > 0 ? ssr / sst : 0.0;
    final adjR2 = 1 - (1 - r2) * (n - 1) / dfResid;
    final seEst = math.sqrt(mse);

    final xtXInv = _invert(xtX);
    final coefs = <RegressionCoefficient>[];
    double dw = 0;
    for (var i = 1; i < n; i++) {
      dw += math.pow(resid[i] - resid[i - 1], 2);
    }
    for (var j = 0; j <= p; j++) {
      final se = math.sqrt(math.max(0, mse * xtXInv[j][j]));
      final t = se > 0 ? beta[j] / se : double.nan;
      final half = tCritical(dfResid, 0.05) * se;
      double stdBeta = 0;
      if (j > 0) {
        final sdx = _sd(xs[j - 1]);
        final sdy = _sd(y);
        stdBeta = sdx > 0 && sdy > 0 ? beta[j] * sdx / sdy : 0;
      }
      coefs.add(RegressionCoefficient(
        name: j == 0 ? '(Constant)' : names[j - 1],
        beta: beta[j],
        stdBeta: stdBeta,
        se: se,
        t: t,
        p: tTwoTail(t, dfResid),
        ciLower95: beta[j] - half,
        ciUpper95: beta[j] + half,
      ));
    }

    for (var j = 0; j < p; j++) {
      if (p == 1) {
        coefs[j + 1] = RegressionCoefficient(
          name: coefs[j + 1].name,
          beta: coefs[j + 1].beta,
          stdBeta: coefs[j + 1].stdBeta,
          se: coefs[j + 1].se,
          t: coefs[j + 1].t,
          p: coefs[j + 1].p,
          ciLower95: coefs[j + 1].ciLower95,
          ciUpper95: coefs[j + 1].ciUpper95,
          vif: 1.0,
        );
        continue;
      }
      final others = [
        for (var k = 0; k < p; k++)
          if (k != j) xs[k]
      ];
      try {
        final r = multiple(others, xs[j], predictorNames: [
          for (var k = 0; k < p; k++)
            if (k != j) names[k]
        ]);
        final vif = 1 / (1 - r.r2).clamp(0.0001, 1e12);
        coefs[j + 1] = RegressionCoefficient(
          name: coefs[j + 1].name,
          beta: coefs[j + 1].beta,
          stdBeta: coefs[j + 1].stdBeta,
          se: coefs[j + 1].se,
          t: coefs[j + 1].t,
          p: coefs[j + 1].p,
          ciLower95: coefs[j + 1].ciLower95,
          ciUpper95: coefs[j + 1].ciUpper95,
          vif: vif,
        );
      } catch (_) {}
    }

    return RegressionResult(
      r: math.sqrt(r2.clamp(0, 1)),
      r2: r2,
      adjR2: adjR2,
      f: f,
      pF: fSf(f, dfModel, dfResid),
      dfModel: dfModel,
      dfResidual: dfResid,
      ssRegression: ssr,
      ssResidual: sse,
      ssTotal: sst,
      msRegression: msr,
      msResidual: mse,
      stdError: seEst,
      durbinWatson: sse > 0 ? dw / sse : double.nan,
      coefficients: coefs,
      intercept: beta[0],
      predictors: names,
      fitted: fitted,
      residuals: resid,
      stdResiduals: resid.map((e) => seEst > 0 ? e / seEst : 0.0).toList(),
    );
  }
}

double _sd(List<double> v) {
  if (v.length < 2) return 0;
  final m = v.reduce((a, b) => a + b) / v.length;
  final ss = v.fold<double>(0, (a, b) => a + (b - m) * (b - m));
  return math.sqrt(ss / (v.length - 1));
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
      n,
      (i) =>
          M[i][n] / (M[i][i].abs() < 1e-15 ? 1e-15 : M[i][i]));
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
    if (M[pivot][col].abs() < 1e-12) {
      M[col][col] += 1e-10;
      pivot = col;
    }
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

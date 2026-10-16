/// FACTOR（主成分）与 LOGISTIC（梯度下降基础版）
library;

import 'dart:math' as math;

import 'correlation.dart';
import 'logistic_full.dart';

class FactorResult {
  final List<double> eigenvalues;
  final List<List<double>> loadings; // p x k
  final double totalVarianceExplained;
  final List<String> variables;
  final List<List<double>> correlation;
  const FactorResult({
    required this.eigenvalues,
    required this.loadings,
    required this.totalVarianceExplained,
    required this.variables,
    required this.correlation,
  });
}

/// 主成分因子分析（相关矩阵特征分解，雅可比）
FactorResult factorPca(
  List<List<double>> columns, {
  List<String>? names,
  int maxFactors = 3,
}) {
  final p = columns.length;
  final labels = names ?? List.generate(p, (i) => 'X${i + 1}');
  final r = Correlation.matrix(columns);

  // 雅可比求特征值/向量
  final a = List.generate(p, (i) => List.of(r[i]));
  final v = List.generate(p, (i) => List.generate(p, (j) => i == j ? 1.0 : 0.0));

  for (var sweep = 0; sweep < 60; sweep++) {
    // 找最大非对角
    var maxVal = 0.0, mu = 0, nu = 1;
    for (var i = 0; i < p; i++) {
      for (var j = i + 1; j < p; j++) {
        if (a[i][j].abs() > maxVal) {
          maxVal = a[i][j].abs();
          mu = i;
          nu = j;
        }
      }
    }
    if (maxVal < 1e-10) break;
    final app = a[mu][mu];
    final aqq = a[nu][nu];
    final apq = a[mu][nu];
    final theta = (aqq - app) / (2 * apq);
    final t = (theta >= 0 ? 1 : -1) /
        (theta.abs() + math.sqrt(theta * theta + 1));
    final c = 1 / math.sqrt(t * t + 1);
    final s = t * c;
    for (var k = 0; k < p; k++) {
      final akp = a[k][mu];
      final akq = a[k][nu];
      a[k][mu] = c * akp - s * akq;
      a[k][nu] = s * akp + c * akq;
    }
    for (var k = 0; k < p; k++) {
      final apk = a[mu][k];
      final aqk = a[nu][k];
      a[mu][k] = c * apk - s * aqk;
      a[nu][k] = s * apk + c * aqk;
    }
    for (var k = 0; k < p; k++) {
      final vkp = v[k][mu];
      final vkq = v[k][nu];
      v[k][mu] = c * vkp - s * vkq;
      v[k][nu] = s * vkp + c * vkq;
    }
    a[mu][nu] = 0;
    a[nu][mu] = 0;
  }

  // 排序特征对
  final pairs = <(double, List<double>)>[];
  for (var i = 0; i < p; i++) {
    pairs.add((
      a[i][i],
      [for (var k = 0; k < p; k++) v[k][i]]
    ));
  }
  pairs.sort((x, y) => y.$1.compareTo(x.$1));

  final k = math.min(maxFactors, p);
  final eigen = <double>[for (var i = 0; i < k; i++) pairs[i].$1.clamp(0, double.infinity).toDouble()];
  final loadings = List.generate(p, (i) {
    return List.generate(k, (f) {
      final lam = pairs[f].$1 > 0 ? math.sqrt(pairs[f].$1) : 0.0;
      return pairs[f].$2[i] * lam;
    });
  });

  final totalVar = pairs.take(k).fold<double>(0, (s, e) => s + e.$1) / p;

  return FactorResult(
    eigenvalues: eigen,
    loadings: loadings,
    totalVarianceExplained: totalVar,
    variables: labels,
    correlation: r,
  );
}

class LogisticResult {
  final List<double> coefficients; // 含截距
  final List<String> names;
  final int iterations;
  final double logLikelihood;
  final double pseudoR2; // McFadden
  final double accuracy;
  final List<double> probabilities;
  const LogisticResult({
    required this.coefficients,
    required this.names,
    required this.iterations,
    required this.logLikelihood,
    required this.pseudoR2,
    required this.accuracy,
    required this.probabilities,
  });
}

/// 逻辑回归（二分类）。
///
/// 与 [logisticRegressionFull] 共用同一套 IRLS（牛顿–拉夫逊）拟合引擎。
/// 这里原来是固定步长的批梯度下降，收敛不到极大似然点：同样数据算出的系数与
/// 对数似然都偏（例如截距唯一模型给出的系数不是 log(n₁/n₀) 这个闭式解）。
/// [maxIter] 继续生效；[lr] 为兼容旧调用保留，已不再使用。
LogisticResult logisticRegression(
  List<List<double>> xs,
  List<int> y, {
  List<String>? names,
  int maxIter = 100,
  double lr = 0.1,
}) {
  final full = logisticRegressionFull(xs, y, names: names, maxIter: maxIter);
  return LogisticResult(
    coefficients: [for (final c in full.coefficients) c.beta],
    names: full.names,
    iterations: full.iterations,
    logLikelihood: full.logLikelihood,
    pseudoR2: full.pseudoR2,
    accuracy: full.table.accuracy,
    probabilities: full.probabilities,
  );
}

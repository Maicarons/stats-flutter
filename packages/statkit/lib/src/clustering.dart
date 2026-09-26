/// 聚类：K-Means
library;

import 'dart:math' as math;

class ClusterCenter {
  final List<double> centroid;
  final int size;
  const ClusterCenter({required this.centroid, required this.size});
}

class KMeansResult {
  final List<int> assignments;
  final List<ClusterCenter> centers;
  final double inertia;
  final int iterations;
  final int k;
  final List<String> variableNames;

  const KMeansResult({
    required this.assignments,
    required this.centers,
    required this.inertia,
    required this.iterations,
    required this.k,
    required this.variableNames,
  });
}

class KMeans {
  /// points: 每行一个观测，每列一个变量
  static KMeansResult cluster(
    List<List<double>> points, {
    required int k,
    int maxIter = 100,
    int? seed,
    List<String>? variableNames,
  }) {
    final n = points.length;
    if (n == 0 || k <= 0 || k > n) {
      throw ArgumentError('k 必须在 1..n 之间');
    }
    final dim = points[0].length;
    final rng = math.Random(seed ?? 42);
    final names = variableNames ?? List.generate(dim, (i) => 'V${i + 1}');

    // k-means++ 初始化
    final centers = <List<double>>[];
    centers.add(List.of(points[rng.nextInt(n)]));
    while (centers.length < k) {
      final d2 = points.map((p) {
        var best = double.infinity;
        for (final c in centers) {
          best = math.min(best, _dist2(p, c));
        }
        return best;
      }).toList();
      final total = d2.fold<double>(0, (a, b) => a + b);
      if (total <= 0) {
        centers.add(List.of(points[rng.nextInt(n)]));
        continue;
      }
      var r = rng.nextDouble() * total;
      for (var i = 0; i < n; i++) {
        r -= d2[i];
        if (r <= 0) {
          centers.add(List.of(points[i]));
          break;
        }
      }
    }

    var assignments = List.filled(n, 0);
    var iterations = 0;
    for (var iter = 0; iter < maxIter; iter++) {
      iterations = iter + 1;
      var changed = false;
      // 分配
      for (var i = 0; i < n; i++) {
        var best = 0;
        var bestD = double.infinity;
        for (var c = 0; c < k; c++) {
          final d = _dist2(points[i], centers[c]);
          if (d < bestD) {
            bestD = d;
            best = c;
          }
        }
        if (assignments[i] != best) {
          assignments[i] = best;
          changed = true;
        }
      }
      // 更新中心
      final sums = List.generate(k, (_) => List<double>.filled(dim, 0));
      final counts = List.filled(k, 0);
      for (var i = 0; i < n; i++) {
        counts[assignments[i]]++;
        for (var j = 0; j < dim; j++) {
          sums[assignments[i]][j] += points[i][j];
        }
      }
      for (var c = 0; c < k; c++) {
        if (counts[c] == 0) {
          centers[c] = List.of(points[rng.nextInt(n)]);
          continue;
        }
        for (var j = 0; j < dim; j++) {
          centers[c][j] = sums[c][j] / counts[c];
        }
      }
      if (!changed) break;
    }

    double inertia = 0;
    for (var i = 0; i < n; i++) {
      inertia += _dist2(points[i], centers[assignments[i]]);
    }

    return KMeansResult(
      assignments: assignments,
      centers: List.generate(
        k,
        (c) => ClusterCenter(
          centroid: List.of(centers[c]),
          size: assignments.where((a) => a == c).length,
        ),
      ),
      inertia: inertia,
      iterations: iterations,
      k: k,
      variableNames: names,
    );
  }

  static double _dist2(List<double> a, List<double> b) {
    double s = 0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      s += d * d;
    }
    return s;
  }
}

/// 信度分析（Cronbach α）
library;

import 'correlation.dart';

class ReliabilityItem {
  final String name;
  final double mean;
  final double variance;
  final double itemTotalCorrelation;
  final double alphaIfDeleted;
  const ReliabilityItem({
    required this.name,
    required this.mean,
    required this.variance,
    required this.itemTotalCorrelation,
    required this.alphaIfDeleted,
  });
}

class ReliabilityResult {
  final double alpha;
  final int nItems;
  final int nCases;
  final double standardizedAlpha;
  final List<ReliabilityItem> items;
  final double totalMean;
  final double totalVariance;

  const ReliabilityResult({
    required this.alpha,
    required this.nItems,
    required this.nCases,
    required this.standardizedAlpha,
    required this.items,
    required this.totalMean,
    required this.totalVariance,
  });
}

class Reliability {
  /// items: 每列一个题目得分
  static ReliabilityResult cronbachAlpha(
    List<List<double>> items, {
    List<String>? names,
  }) {
    final k = items.length;
    final n = items[0].length;
    final labels = names ?? List.generate(k, (i) => 'Item${i + 1}');

    final means = List<double>.filled(k, 0);
    final vars = List<double>.filled(k, 0);
    for (var j = 0; j < k; j++) {
      final m = items[j].reduce((a, b) => a + b) / n;
      means[j] = m;
      final ss = items[j].fold<double>(0, (a, b) => a + (b - m) * (b - m));
      vars[j] = n > 1 ? ss / (n - 1) : 0;
    }

    final total = List<double>.filled(n, 0);
    for (var j = 0; j < k; j++) {
      for (var i = 0; i < n; i++) {
        total[i] += items[j][i];
      }
    }
    final tm = total.reduce((a, b) => a + b) / n;
    final tv = total.fold<double>(0, (a, b) => a + (b - tm) * (b - tm)) / (n - 1);

    final sumVar = vars.fold<double>(0, (a, b) => a + b);
    final alpha = k > 1 && tv > 0 ? k / (k - 1) * (1 - sumVar / tv) : 0.0;

    // 标准化 α（基于平均相关）
    double rBar = 0;
    int pairs = 0;
    for (var a = 0; a < k; a++) {
      for (var b = a + 1; b < k; b++) {
        rBar += Correlation.pearson(items[a], items[b]).r;
        pairs++;
      }
    }
    rBar = pairs > 0 ? rBar / pairs : 0;
    final stdAlpha = k > 1 && rBar < 1
        ? k * rBar / (1 + (k - 1) * rBar)
        : 0.0;

    final itemResults = <ReliabilityItem>[];
    for (var j = 0; j < k; j++) {
      // 校正项总相关
      final restTotal = List<double>.filled(n, 0);
      for (var t = 0; t < k; t++) {
        if (t == j) continue;
        for (var i = 0; i < n; i++) {
          restTotal[i] += items[t][i];
        }
      }
      final itc = Correlation.pearson(items[j], restTotal).r;

      // 删除该项后的 α
      final sub = [
        for (var t = 0; t < k; t++)
          if (t != j) items[t]
      ];
      double alphaDel = 0;
      if (sub.length > 1) {
        final subVars = sub.map((col) {
          final m = col.reduce((a, b) => a + b) / n;
          return col.fold<double>(0, (a, b) => a + (b - m) * (b - m)) / (n - 1);
        }).toList();
        final subTotal = List<double>.filled(n, 0);
        for (final col in sub) {
          for (var i = 0; i < n; i++) {
            subTotal[i] += col[i];
          }
        }
        final stm = subTotal.reduce((a, b) => a + b) / n;
        final stv =
            subTotal.fold<double>(0, (a, b) => a + (b - stm) * (b - stm)) /
                (n - 1);
        final kk = sub.length;
        alphaDel = kk > 1 && stv > 0
            ? kk / (kk - 1) * (1 - subVars.fold<double>(0, (a, b) => a + b) / stv)
            : 0;
      }

      itemResults.add(ReliabilityItem(
        name: labels[j],
        mean: means[j],
        variance: vars[j],
        itemTotalCorrelation: itc,
        alphaIfDeleted: alphaDel,
      ));
    }

    return ReliabilityResult(
      alpha: alpha,
      nItems: k,
      nCases: n,
      standardizedAlpha: stdAlpha,
      items: itemResults,
      totalMean: tm,
      totalVariance: tv,
    );
  }
}

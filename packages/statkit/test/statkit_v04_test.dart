import 'dart:math' as math;

import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

void main() {
  group('LogisticFull', () {
    test('截距唯一模型与闭式解一致（v0.5 IRLS 修正）', () {
      // 12 个 1、9 个 0：β = log(n₁/n₀)，Var = 1/n₁ + 1/n₀
      final y = <int>[...List.filled(12, 1), ...List.filled(9, 0)];
      final r = logisticRegressionFull(const [], y);
      expect(r.converged, isTrue);
      expect(r.iterations, lessThan(10));
      expect(r.coefficients.length, 1);
      expect(r.coefficients[0].name, '(Constant)');
      expect(r.coefficients[0].beta, closeTo(math.log(12 / 9), 1e-6));
      expect(r.coefficients[0].se, closeTo(math.sqrt(1 / 12 + 1 / 9), 1e-6));
      final ll0 = 12 * math.log(12 / 21) + 9 * math.log(9 / 21);
      // 拟合里加了 λ = 1e-6 的岭（仅为数值可逆），会让解偏离极大似然点
      // O(λβ/I) ≈ 5e-8，因此这里按 1e-6 判定
      expect(r.logLikelihood, closeTo(ll0, 1e-6));
      expect(r.probabilities.first, closeTo(12 / 21, 1e-6));
    });

    test('logisticRegression（梯度下降版）也落在极大似然点', () {
      // 原来这里是固定步长批梯度下降，截距唯一模型给不出 log(n₁/n₀)
      final y = <int>[...List.filled(12, 1), ...List.filled(9, 0)];
      final r = logisticRegression(const [], y);
      expect(r.coefficients[0], closeTo(math.log(12 / 9), 1e-6));
      final ll0 = 12 * math.log(12 / 21) + 9 * math.log(9 / 21);
      expect(r.logLikelihood, closeTo(ll0, 1e-6));
      // 截距唯一模型把所有个体都判给多数类：12 / 21
      expect(r.accuracy, closeTo(12 / 21, 1e-12));
    });

    test('两个自变量时两个入口给出同一解', () {
      final rng = math.Random(4);
      final a = <double>[], b = <double>[], y = <int>[];
      for (var i = 0; i < 70; i++) {
        final u = rng.nextDouble() * 4 - 2;
        final v = rng.nextDouble() * 4 - 2;
        a.add(u);
        b.add(v);
        final p = 1 / (1 + math.exp(-(0.8 * u - 0.5 * v - 0.3)));
        y.add(rng.nextDouble() < p ? 1 : 0);
      }
      final full = logisticRegressionFull([a, b], y, names: ['A', 'B']);
      final simple = logisticRegression([a, b], y, names: ['A', 'B']);
      expect(full.converged, isTrue);
      for (var j = 0; j < 3; j++) {
        expect(simple.coefficients[j], closeTo(full.coefficients[j].beta, 1e-9));
        expect(simple.names[j], full.coefficients[j].name);
      }
      expect(simple.logLikelihood, closeTo(full.logLikelihood, 1e-9));
      expect(simple.pseudoR2, closeTo(full.pseudoR2, 1e-9));
      expect(simple.accuracy, closeTo(full.table.accuracy, 1e-12));
      expect(simple.probabilities.first,
          closeTo(full.probabilities.first, 1e-12));
    });

    test('separates two clusters', () {
      final x = [
        <double>[1, 1.2, 0.9, 1.1, 0.8, 4, 4.2, 3.9, 4.1, 3.8],
      ];
      final y = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1];
      final r = logisticRegressionFull(x, y, names: ['x1']);
      expect(r.coefficients.length, 2);
      expect(r.table.accuracy, greaterThan(0.8));
      expect(r.probabilities.length, 10);
      expect(r.hl.groups, greaterThan(0));
      expect(r.coefficients[1].oddsRatio, greaterThan(1));
    });
  });

  group('GLM', () {
    test('one-way', () {
      final g = {
        'A': <double>[1, 2, 3],
        'B': <double>[4, 5, 6],
        'C': <double>[7, 8, 9],
      };
      final r = glmOneWay(g);
      expect(r.terms.length, 1);
      expect(r.terms[0].f, greaterThan(0));
      expect(r.n, 9);
    });

    test('two-way terms', () {
      final cells = {
        ('A1', 'B1'): <double>[1, 2],
        ('A1', 'B2'): <double>[3, 4],
        ('A2', 'B1'): <double>[5, 6],
        ('A2', 'B2'): <double>[7, 8],
      };
      final r = glmTwoWay(cells);
      expect(r.terms.length, 3);
      expect(r.kA, 2);
      expect(r.kB, 2);
      expect(r.dfError, greaterThan(0));
    });
  });

  group('Stepwise', () {
    test('forward selects true predictors', () {
      final n = 20;
      final x1 = [for (var i = 0; i < n; i++) i * 1.0];
      final x2 = [for (var i = 0; i < n; i++) (i % 3) * 1.0];
      final y = [for (var i = 0; i < n; i++) 2.0 * i + 0.5];
      final r = stepwiseRegression(
        [x1, x2],
        y,
        names: ['x1', 'x2'],
        method: StepwiseMethod.forward,
      );
      expect(r.selected, contains('x1'));
      expect(r.r2, greaterThan(0.9));
    });
  });

  group('CTables', () {
    test('count cross tab', () {
      final r = crosstabSummary(
        rowKeys: ['M', 'F', 'M', 'F', 'M'],
        colKeys: ['Y', 'Y', 'N', 'N', 'Y'],
        rowVar: 'gender',
        colVar: 'passed',
      );
      expect(r.rowLabels.toSet(), {'M', 'F'});
      expect(r.colLabels.toSet(), {'Y', 'N'});
      expect(r.cells.length, 2);
      expect(r.cells[0].length, 2);
    });

    test('mean summary', () {
      final r = crosstabSummary(
        rowKeys: ['A', 'A', 'B', 'B'],
        colKeys: ['X', 'Y', 'X', 'Y'],
        values: [1.0, 3.0, 5.0, 7.0],
        rowVar: 'g',
        colVar: 't',
        summary: CellSummary.mean,
      );
      expect(r.grandTotal.value, closeTo(4.0, 1e-9));
    });
  });
}

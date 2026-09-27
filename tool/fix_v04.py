from pathlib import Path

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\stepwise.dart")
t = p.read_text(encoding="utf-8")
if "dart:math" not in t:
    t = t.replace(
        "import 'distributions.dart';",
        "import 'dart:math' as math;\n\nimport 'distributions.dart';",
    )
    p.write_text(t, encoding="utf-8")
    print("math")

p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\statkit.dart")
t = p.read_text(encoding="utf-8")
for exp in [
    "logistic_full.dart",
    "glm.dart",
    "stepwise.dart",
    "ctables.dart",
]:
    line = "export 'src/%s';" % exp
    if exp not in t:
        t = t.rstrip() + "\n" + line + "\n"
p.write_text(t, encoding="utf-8")
print("exports")

# rewrite tests file
Path(r"F:\workspace\stats-flutter\packages\statkit\test\statkit_v04_test.dart").write_text(
    """import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

void main() {
  group('LogisticFull', () {
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
""",
    encoding="utf-8",
)
print("tests")

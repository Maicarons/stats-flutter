from pathlib import Path

# 1) weights.dart import regression
p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\weights.dart")
t = p.read_text(encoding="utf-8")
if "regression.dart" not in t:
    t = t.replace(
        "import 'hypothesis.dart';",
        "import 'hypothesis.dart';\nimport 'regression.dart';",
    )
    p.write_text(t, encoding="utf-8")
    print("weights import")
else:
    print("weights already ok")

# 2) rewrite v02 tests with proper types
Path(r"F:\workspace\stats-flutter\packages\statkit\test\statkit_v02_test.dart").write_text(
    r'''import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

void main() {
  group('WeightedDescriptives', () {
    test('equals unweighted when all weights are 1', () {
      final v = <double>[1, 2, 3, 4, 5];
      final w = <double>[1, 1, 1, 1, 1];
      final ww = WeightedDescriptives.compute(v, w);
      final u = Descriptives.compute(v);
      expect(ww.mean, closeTo(u.mean, 1e-9));
      expect(ww.nWeighted, closeTo(5, 1e-9));
    });

    test('frequency weights shift the mean', () {
      final v = <double>[1, 1, 1, 10];
      final w = <double>[1, 1, 1, 1];
      final ww = WeightedDescriptives.compute(v, w);
      expect(ww.mean, closeTo((1 + 1 + 1 + 10) / 4, 1e-9));

      final v2 = <double>[1, 10];
      final w2 = <double>[3, 1];
      final ww2 = WeightedDescriptives.compute(v2, w2);
      expect(ww2.mean, closeTo(ww.mean, 1e-9));
      expect(ww2.nWeighted, closeTo(4, 1e-9));
    });
  });

  group('WeightedTTest', () {
    test('one-sample with unit weights matches unweighted', () {
      final v = <double>[2.1, 2.4, 2.8, 2.2, 2.6];
      final w = <double>[1, 1, 1, 1, 1];
      final a = WeightedTTest.oneSample(v, w, mu0: 2.0);
      final b = TTest.oneSample(v, mu0: 2.0);
      expect(a.t, closeTo(b.t, 1e-6));
    });
  });

  group('WeightedCorrelation', () {
    test('perfect linear relation', () {
      final x = <double>[1, 2, 3, 4];
      final y = <double>[2, 4, 6, 8];
      final w = <double>[1, 1, 1, 1];
      final r = WeightedCorrelation.pearson(x, y, w);
      expect(r.r, closeTo(1.0, 1e-9));
    });
  });

  group('splitGroups', () {
    test('splits by key', () {
      final g = <double>[1, 2, 1, 2, 1];
      final m = splitGroups(g);
      expect(m['1.0'], [0, 2, 4]);
      expect(m['2.0'], [1, 3]);
    });

    test('respects value labels', () {
      final g = <double>[1, 2, 1];
      final m = splitGroups(g, valueLabels: {1.0: 'A', 2.0: 'B'});
      expect(m.keys.toSet(), {'A', 'B'});
    });
  });

  group('exact tests', () {
    test('binomial p0=0.5 n=10 k=5 is not extreme', () {
      final r = exactBinomial(5, 10);
      expect(r.pTwoTail, greaterThan(0.5));
    });

    test('binomial extreme k=0', () {
      final r = exactBinomial(0, 10, p0: 0.5);
      expect(r.pTwoTail, lessThan(0.01));
    });

    test('fisher exact 2x2', () {
      final r = fisherExact(1, 9, 11, 3);
      expect(r.n, 24);
      expect(r.pTwoTail, lessThan(0.05));
    });

    test('fisher equal tables p near 1', () {
      final r = fisherExact(5, 5, 5, 5);
      expect(r.pTwoTail, greaterThan(0.5));
    });
  });

  group('NparExtended', () {
    test('binomial npar', () {
      final r =
          NparExtended.binomial(<double>[1, 1, 0, 1, 0, 1, 1], splitValue: 0.5);
      expect(r.n1, 7);
      expect(r.p, greaterThan(0));
    });

    test('kendall tau perfect', () {
      final r =
          NparExtended.kendallTau(<double>[1, 2, 3, 4], <double>[10, 20, 30, 40]);
      expect(r.r, closeTo(1.0, 1e-9));
    });

    test('mcnemar', () {
      final r = NparExtended.mcnemar(20, 5);
      expect(r.n1, 25);
      expect(r.p, lessThan(0.05));
    });

    test('cochran Q', () {
      final t = [
        [true, true, false, true],
        [true, false, false, true],
        [false, true, false, true],
      ];
      final r = NparExtended.cochranQ(t);
      expect(r.n1, 4);
      expect(r.p, greaterThan(0));
    });

    test('median test', () {
      final r = NparExtended.medianTest([
        <double>[1, 2, 3, 4],
        <double>[3, 4, 5, 6],
      ]);
      expect(r.n1, 8);
    });
  });

  group('weighted regression', () {
    test('unit weights match simple regression', () {
      final x = <double>[1, 2, 3, 4, 5];
      final y = <double>[2, 4, 6, 8, 10];
      final w = <double>[1, 1, 1, 1, 1];
      final a = weightedSimpleRegression(x, y, w);
      final b = Regression.simple(x, y);
      expect(a.slope, closeTo(b.slope, 1e-6));
      expect(a.r2, closeTo(b.r2, 1e-6));
    });
  });
}
''',
    encoding="utf-8",
)
print("tests rewritten")

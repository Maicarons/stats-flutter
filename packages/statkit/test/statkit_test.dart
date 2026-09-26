import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

void main() {
  group('Descriptives', () {
    test('basic stats', () {
      final d = Descriptives.compute([1, 2, 3, 4, 5].map((e) => e.toDouble()).toList());
      expect(d.n, 5);
      expect(d.mean, closeTo(3.0, 1e-9));
      expect(d.median, closeTo(3.0, 1e-9));
      expect(d.min, 1);
      expect(d.max, 5);
      expect(d.sd, closeTo(1.5811, 1e-3));
    });

    test('percentile', () {
      final v = [1.0, 2.0, 3.0, 4.0, 5.0];
      expect(percentile(v, 50), closeTo(3.0, 1e-9));
      expect(percentile(v, 25), closeTo(2.0, 1e-9));
    });
  });

  group('Distributions', () {
    test('normCdf', () {
      expect(normCdf(0), closeTo(0.5, 1e-4));
      expect(normCdf(1.96), closeTo(0.975, 1e-3));
    });

    test('tTwoTail', () {
      // t=2.228, df=10 → p≈0.05
      expect(tTwoTail(2.228, 10), closeTo(0.05, 0.005));
    });

    test('chiSquareSf', () {
      // χ²=3.84, df=1 → p≈0.05
      expect(chiSquareSf(3.841, 1), closeTo(0.05, 0.005));
    });
  });

  group('TTest', () {
    test('one sample', () {
      final r = TTest.oneSample([5.0, 6, 7, 8, 9], mu0: 5);
      expect(r.n1, 5);
      expect(r.meanDiff, closeTo(2.0, 1e-9));
      expect(r.pTwoTail, lessThan(0.05));
    });

    test('independent', () {
      final r = TTest.independentSamples(
        [1.0, 2, 3, 4, 5],
        [3.0, 4, 5, 6, 7],
      );
      expect(r.mode, 'independent');
      expect(r.pTwoTail, greaterThan(0.01));
    });
  });

  group('Anova', () {
    test('oneway', () {
      final r = OnewayAnova.compute([
        [1.0, 2, 3],
        [4.0, 5, 6],
        [7.0, 8, 9],
      ]);
      expect(r.dfBetween, 2);
      expect(r.dfWithin, 6);
      expect(r.f, greaterThan(0));
    });
  });

  group('Correlation', () {
    test('perfect positive', () {
      final r = Correlation.pearson([1, 2, 3, 4].map((e) => e.toDouble()).toList(),
          [2, 4, 6, 8].map((e) => e.toDouble()).toList());
      expect(r.r, closeTo(1.0, 1e-9));
    });
  });

  group('Regression', () {
    test('simple linear', () {
      final x = <double>[1, 2, 3, 4, 5];
      final y = <double>[2, 4, 6, 8, 10];
      final r = Regression.simple(x, y);
      expect(r.r2, closeTo(1.0, 1e-9));
      expect(r.intercept, closeTo(0, 1e-9));
      expect(r.coefficients[1].beta, closeTo(2.0, 1e-9));
    });
  });

  group('Nonparametric', () {
    test('mann-whitney', () {
      final r = Nonparametric.mannWhitney([1.0, 2, 3], [4.0, 5, 6]);
      expect(r.n1, 3);
      expect(r.p, lessThan(0.1));
    });
  });

  group('Reliability', () {
    test('cronbach alpha', () {
      final items = <List<double>>[
        [1, 2, 3, 4, 5],
        [1, 2, 3, 4, 5],
        [1, 2, 3, 4, 5],
      ];
      final r = Reliability.cronbachAlpha(items);
      expect(r.alpha, closeTo(1.0, 1e-6));
    });
  });

  group('KMeans', () {
    test('two clusters', () {
      final pts = <List<double>>[
        [0, 0],
        [0.1, 0.1],
        [10, 10],
        [10.1, 9.9],
      ];
      final r = KMeans.cluster(pts, k: 2, seed: 1);
      expect(r.assignments[0], r.assignments[1]);
      expect(r.assignments[2], r.assignments[3]);
      expect(r.assignments[0], isNot(r.assignments[2]));
    });
  });
}

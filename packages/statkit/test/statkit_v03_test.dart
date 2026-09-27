import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

void main() {
  final data = <double>[2.1, 3.4, 4.0, 5.5, 6.1, 7.8, 8.2, 9.0, 10.5, 12.0, 1.2];

  group('BoxPlot', () {
    test('quartiles and whiskers', () {
      final b = boxPlot(data);
      expect(b.median, greaterThan(b.q1));
      expect(b.q3, greaterThan(b.median));
      expect(b.lowerWhisker, lessThanOrEqualTo(b.q1));
      expect(b.upperWhisker, greaterThanOrEqualTo(b.q3));
      expect(b.iqr, closeTo(b.q3 - b.q1, 1e-9));
    });

    test('detects outliers', () {
      final b = boxPlot([1.0, 2, 3, 4, 5, 6, 7, 8, 9, 100]);
      expect(b.outliers, isNotEmpty);
    });
  });

  group('Percentiles', () {
    test('table has median', () {
      final t = percentiles(data);
      expect(t.rows, isNotEmpty);
      final med = t.rows.firstWhere((r) => r.p == 50);
      expect(med.value, closeTo(percentile(List.of(data)..sort(), 50), 1e-9));
    });
  });

  group('Extremes', () {
    test('lowest and highest', () {
      final e = extremes(data, nShow: 3);
      expect(e.lowest.length, 3);
      expect(e.highest.length, 3);
      expect(e.lowest.first.value, lessThan(e.highest.first.value));
    });
  });

  group('StemLeaf', () {
    test('produces rows', () {
      final s = stemAndLeaf(data);
      expect(s.rows, isNotEmpty);
      final total = s.rows.fold<int>(0, (a, b) => a + b.frequency);
      expect(total, data.length);
    });
  });

  group('QQ', () {
    test('points count matches n', () {
      final q = normalQQPoints(data);
      expect(q.length, data.length);
    });
  });

  group('Dagostino', () {
    test('near-normal sample', () {
      final r = dagostinoPearson(data);
      expect(r.chiSquare, greaterThan(0));
      expect(r.p, greaterThanOrEqualTo(0));
      expect(r.p, lessThanOrEqualTo(1));
    });
  });

  group('ErrorBars', () {
    test('from groups', () {
      final bars = errorBarsFromGroups({
        'A': [1.0, 2, 3, 4],
        'B': [2.0, 3, 4, 5],
      });
      expect(bars.length, 2);
      expect(bars.first.low, lessThan(bars.first.mean));
    });
  });

  group('Examine', () {
    test('full pack', () {
      final r = examine(data);
      expect(r.desc.n, data.length);
      expect(r.box.median, isNotNaN);
      expect(r.qq.length, data.length);
    });
  });

  group('KMO / Bartlett', () {
    test('kmo in [0,1]', () {
      final cols = [
        <double>[1, 2, 3, 4, 5, 6, 7, 8],
        <double>[2, 4, 5, 7, 8, 9, 11, 12],
        <double>[1, 3, 4, 6, 7, 8, 10, 11],
      ];
      final k = kmo(cols);
      expect(k.overall, greaterThan(0));
      expect(k.overall, lessThanOrEqualTo(1.01));
    });

    test('bartlett rejects identity for correlated data', () {
      final cols = [
        <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        <double>[2, 4, 5, 7, 8, 9, 11, 12, 14, 15],
        <double>[3, 5, 7, 8, 10, 11, 13, 14, 16, 17],
      ];
      final b = bartlettSphericity(cols);
      expect(b.df, 3);
      expect(b.chiSquare, greaterThan(0));
    });
  });

  group('Varimax / factorAnalyze', () {
    test('varimax keeps number of factors', () {
      final L = [
        [0.8, 0.1],
        [0.75, 0.2],
        [0.1, 0.85],
        [0.15, 0.8],
      ];
      final (rot, _) = varimax(L);
      expect(rot.length, 4);
      expect(rot[0].length, 2);
    });

    test('factorAnalyze returns diagnostics', () {
      final cols = [
        <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        <double>[2, 3, 5, 6, 7, 9, 10, 11, 12, 14],
        <double>[5, 6, 7, 8, 9, 10, 11, 12, 13, 15],
        <double>[1, 1, 2, 3, 3, 4, 5, 5, 6, 7],
      ];
      final r = factorAnalyze(cols, maxFactors: 2);
      expect(r.communalities.length, 4);
      expect(r.kmo.overall, greaterThan(0));
      expect(r.bartlett.chiSquare, greaterThan(0));
      expect(r.scree, isNotEmpty);
    });
  });
}

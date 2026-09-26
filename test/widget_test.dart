import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';

void main() {
  test('demo dataset and descriptives integrate', () {
    final values = <double>[1, 2, 3, 4, 5];
    final d = Descriptives.compute(values);
    expect(d.mean, 3.0);
    expect(TTest.oneSample(values, mu0: 3).pTwoTail, greaterThan(0.5));
  });
}

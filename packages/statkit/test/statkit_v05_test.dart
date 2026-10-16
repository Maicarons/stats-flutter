import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

void main() {
  group('Jonckheere-Terpstra', () {
    test('无结时与闭式公式一致', () {
      // 两组各 3 例，全部前者小于后者：J = 3 x 3 = 9
      // E[J] = (N² - Σn²)/4 = (36 - 18)/4 = 4.5
      // Var[J] = [N(N-1)(2N+5) - Σn(n-1)(2n+5)]/72 = [6·5·17 - 2·3·2·11]/72 = 5.25
      final r = NparExtended.jonckheereTerpstra([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      expect(r.statistic, closeTo(9.0, 1e-12));
      expect(r.extra['meanJ'] as double, closeTo(4.5, 1e-12));
      expect(r.extra['variance'] as double, closeTo(5.25, 1e-12));
      expect(r.z!, closeTo(1.9639607, 1e-6));
      expect(r.p, closeTo(0.049537, 1e-4));
      expect(r.n1, 6);
      expect(r.n2, 2);
      expect(r.extra['levels'], 2);
    });

    test('结按每对 0.5 计，并用结校正方差', () {
      // A = [1,2]、B = [2,3]：J = (1<2)(1<3)(2<3) 三次 + (2==2) 0.5 = 3.5
      // Var = 102/72 + 0/problem + 4·2/(8·12) = 1.41667 + 0.08333 = 1.5
      final r = NparExtended.jonckheereTerpstra([
        [1, 2],
        [2, 3],
      ]);
      expect(r.statistic, closeTo(3.5, 1e-12));
      expect(r.extra['meanJ'] as double, closeTo(2.0, 1e-12));
      expect(r.extra['variance'] as double, closeTo(1.5, 1e-12));
      expect(r.extra['sdJ'] as double, closeTo(1.224744871, 1e-9));
      expect(r.z!, closeTo(1.224744871, 1e-9));
      expect(r.p, closeTo(0.220677, 1e-4));
      expect(r.extra['pOneTail'] as double, closeTo(0.110339, 1e-4));
    });

    test('一组内同时有并列与更大取值时按定义计数', () {
      // A = [5,5]、B = [5,5,7]：J = 2·(0.5·2) + 2·1 = 4
      final r = NparExtended.jonckheereTerpstra([
        [5, 5],
        [5, 5, 7],
      ]);
      expect(r.statistic, closeTo(4.0, 1e-12));
      expect(r.extra['meanJ'] as double, closeTo((25 - (4 + 9)) / 4, 1e-12));
    });

    test('三组单调上升显著，倒序后 z 反号', () {
      final up = NparExtended.jonckheereTerpstra([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
      ]);
      // J = 3·16 = 48，E[J] = (144 - 48)/4 = 24
      // Var = [12·11·29 - 3·4·3·13]/72 = 46.6667
      expect(up.statistic, closeTo(48.0, 1e-12));
      expect(up.extra['meanJ'] as double, closeTo(24.0, 1e-12));
      expect(up.extra['variance'] as double, closeTo(46.66666667, 1e-6));
      expect(up.z!, closeTo(3.51324, 1e-4));
      expect(up.p, lessThan(0.001));
      expect(up.extra['pOneTail'] as double, lessThan(0.001));

      final down = NparExtended.jonckheereTerpstra([
        [9, 10, 11, 12],
        [5, 6, 7, 8],
        [1, 2, 3, 4],
      ]);
      expect(down.statistic, closeTo(0.0, 1e-12));
      expect(down.z!, closeTo(-3.51324, 1e-4));
      expect(down.p, closeTo(up.p, 1e-12));
      expect(down.extra['pOneTail'] as double, greaterThan(0.99));
    });

    test('整数权重等价于重复个案', () {
      final weighted = NparExtended.jonckheereTerpstra(
        [
          [1, 2],
          [2, 3],
        ],
        weights: [
          [2, 3],
          [1, 4],
        ],
      );
      final repeated = NparExtended.jonckheereTerpstra([
        [1, 1, 2, 2, 2],
        [2, 3, 3, 3, 3],
      ]);
      expect(weighted.statistic, closeTo(repeated.statistic, 1e-12));
      expect(weighted.extra['meanJ'] as double,
          closeTo(repeated.extra['meanJ'] as double, 1e-12));
      expect(weighted.extra['variance'] as double,
          closeTo(repeated.extra['variance'] as double, 1e-12));
      expect(weighted.z!, closeTo(repeated.z!, 1e-12));
      expect(weighted.p, closeTo(repeated.p, 1e-12));
    });

    test('数据不足时返回 NaN 而不是硬给一个 p 值', () {
      final one = NparExtended.jonckheereTerpstra([
        [1, 2, 3],
      ]);
      expect(one.p.isNaN, isTrue);
      expect(one.statistic.isNaN, isTrue);
      expect(one.extra['levels'], 0);

      final none = NparExtended.jonckheereTerpstra([[], []]);
      expect(none.p.isNaN, isTrue);
      expect(none.n1, 0);
    });

    test('忽略非有限值与非正权重', () {
      final r = NparExtended.jonckheereTerpstra(
        [
          [1, double.nan, 2],
          [double.infinity, 3],
        ],
        weights: [
          [1, 1, 0],
          [1, 1],
        ],
      );
      expect(r.n1, 2); // 只剩 1 与 3
      expect(r.statistic, closeTo(1.0, 1e-12));
    });
  });
}

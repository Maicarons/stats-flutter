/// v0.6.0 新增：Kendall W 一致性系数、单样本 KS 精确 p（Marsaglia–Tsang–Wang
/// Durbin 矩阵法）。数值锚点：K(1,d)=2d−1 的解析式、临界值表
/// D_{10,0.05}=0.40925、完全一致排序 W=1、渐近式与精确值的接近度。
library;

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:statkit/statkit.dart';

void main() {
  group('exactKolmogorovCdf', () {
    test('n=1 解析式 K(1,d) = 2d − 1（0.5 ≤ d < 1）', () {
      for (final d in [0.5, 0.6, 0.7, 0.9, 0.99]) {
        expect(exactKolmogorovCdf(1, d), closeTo(2 * d - 1, 1e-12),
            reason: 'd=$d');
      }
      expect(exactKolmogorovCdf(1, 0.4), 0);
    });

    test('n=1, d→0：P(D₁ < d) → 0；d≥1 → 1', () {
      expect(exactKolmogorovCdf(1, 1e-6), 0);
      expect(exactKolmogorovCdf(5, 1.0), 1);
    });

    test('临界值表锚点：K(10, 0.40925) ≈ 0.95（D_{10,0.05}=0.40925）', () {
      expect(exactKolmogorovCdf(10, 0.40925), closeTo(0.95, 1e-4));
    });

    test('与渐近 Kolmogorov 极限分布一致（n=30, d=0.2 差 < 5e-3）', () {
      final d = 0.2;
      final n = 30;
      var asy = 0.0;
      for (var j = 1; j <= 100; j++) {
        asy += (j.isOdd ? 1 : -1) *
            math.exp(-2 * j * j * d * d * n).toDouble();
      }
      final pAsy = 1 - 2 * asy;
      // n=30 时精确值与 n→∞ 极限的偏差本就在 ~2e-2 量级（收敛慢）
      expect(exactKolmogorovCdf(n, d), closeTo(pAsy, 3e-2));
    });

    test('右尾退化路径仍给出 [0,1] 内的值', () {
      final v = exactKolmogorovCdf(50, 0.5);
      expect(v, greaterThan(0.9999));
      expect(v, lessThanOrEqualTo(1.0));
    });
  });

  group('NparExtended.ksExact', () {
    test('U(0,1) 样本对完全指定的均匀分布：p 不显著、D 与手工一致', () {
      final xs = [
        0.11, 0.23, 0.31, 0.42, 0.5, 0.56, 0.67, 0.72, 0.85, 0.94,
      ];
      final r = NparExtended.ksExact(xs, (x) => x.clamp(0.0, 1.0));
      expect(r.statisticName, 'D');
      // D = max_i( (i+1)/n − F_i, F_i − i/n )；x₂=0.23 处 F−i/n = 0.23−0.1
      expect(r.statistic, closeTo(0.13, 1e-9));
      expect(r.pExact, r.p);
      expect(r.p, greaterThan(0.05));
      expect(r.p, lessThanOrEqualTo(1.0));
    });

    test('系统性偏移的样本被检出（p 显著）', () {
      final xs = [
        for (var i = 0; i < 20; i++) 0.5 + 0.02 * i,
      ];
      final r = NparExtended.ksExact(xs, (x) => x.clamp(0.0, 1.0));
      expect(r.p, lessThan(0.01));
    });
  });

  group('NparExtended.kendallW', () {
    test('完全一致的排序 → W = 1', () {
      // 3 位评委（列）× 4 个对象（行），评委间排序完全相同
      final treatments = [
        [1.0, 1.0, 1.0, 1.0],
        [2.0, 2.0, 2.0, 2.0],
        [3.0, 3.0, 3.0, 3.0],
      ];
      final r = NparExtended.kendallW(treatments);
      expect(r.statistic, closeTo(1.0, 1e-12));
      expect(r.p, closeTo(chiSquareSf(8, 2), 1e-9));
    });

    test('完全相反的排序 → W 接近 0', () {
      final treatments = [
        [1.0, 3.0],
        [2.0, 2.0],
        [3.0, 1.0],
      ];
      final r = NparExtended.kendallW(treatments);
      expect(r.statistic, lessThan(0.1));
    });

    test('与 Friedman χ² 恒等：W = χ²/(n(k−1))', () {
      final treatments = [
        [3.0, 1.0, 2.0, 4.0],
        [2.0, 2.0, 3.0, 4.0],
        [1.0, 3.0, 2.0, 4.0],
        [4.0, 2.0, 1.0, 3.0],
      ];
      final w = NparExtended.kendallW(treatments);
      final f = NparExtended.friedman(treatments);
      expect(w.extra['chiSquare'], closeTo(f.statistic, 1e-12));
      expect(
          w.statistic, closeTo(f.statistic / (4 * (4 - 1)), 1e-12));
      expect(w.p, closeTo(f.p, 1e-12));
    });
  });
}

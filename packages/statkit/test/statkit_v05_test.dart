import 'dart:math' as math;

import 'package:statkit/statkit.dart';
import 'package:test/test.dart';

/// 测试内独立实现：估计均值/标准差后的 KS 统计量（带符号 D+ / D−）
double _ksD(List<double> data) {
  final v = [...data]..sort();
  final n = v.length;
  final mean = v.reduce((a, b) => a + b) / n;
  final varSum = v.fold<double>(0, (a, x) => a + (x - mean) * (x - mean));
  final sd = math.sqrt(varSum / (n - 1));
  double dp = 0, dn = 0;
  for (var i = 0; i < n; i++) {
    final cdf = normCdf((v[i] - mean) / sd);
    dp = math.max(dp, (i + 1) / n - cdf);
    dn = math.max(dn, cdf - i / n);
  }
  return math.max(dp, dn);
}

/// 测试内独立实现：由分位点构造「完全正态」样本（对 normCdf 做二分求逆）
List<double> _normalQuantileSample(int n) {
  final out = <double>[];
  for (var i = 0; i < n; i++) {
    final target = (i + 0.5) / n;
    var lo = -8.0, hi = 8.0;
    for (var it = 0; it < 60; it++) {
      final mid = (lo + hi) / 2;
      if (normCdf(mid) < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    out.add((lo + hi) / 2);
  }
  return out;
}

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

  group('置换检验', () {
    test('完全枚举与手算一致', () {
      // a=[1,2,3]、b=[4,6,8]：合并后共 C(6,3)=20 种分组
      // 统计量 = mean(前三) - mean(其余) = 2c̄ - 8（c̄ 为被选三数的均值）
      // 观察值 -4；|统计量| ≥ 4 只在三数和为 6 或 18 时出现（各 1 种）
      // 加一校正：(1 + 2) / (1 + 20) = 3/21
      const a = [1.0, 2.0, 3.0];
      const b = [4.0, 6.0, 8.0];
      final pooled = [...a, ...b];
      final stats = <double>[];
      for (var i = 0; i < pooled.length; i++) {
        for (var j = i + 1; j < pooled.length; j++) {
          for (var k = j + 1; k < pooled.length; k++) {
            final chosen = [pooled[i], pooled[j], pooled[k]];
            final rest = <double>[];
            for (var t = 0; t < pooled.length; t++) {
              if (t != i && t != j && t != k) rest.add(pooled[t]);
            }
            final mc = chosen.reduce((x, y) => x + y) / 3;
            final mr = rest.reduce((x, y) => x + y) / 3;
            stats.add(mc - mr);
          }
        }
      }
      final exact = Permutation.exact(observed: -4.0, permutedStatistics: stats);
      expect(exact.permutations, 20);
      expect(exact.exact, isTrue);
      expect(exact.pTwoTail, closeTo(3 / 21, 1e-12));
      // 观察值恰好是置换分布的最小值：单侧「≤」只有它自己（(1+1)/21），
      // 单侧「≥」包含全部 20 个置换（(1+20)/21 = 1）
      expect(exact.pLess, closeTo(2 / 21, 1e-12));
      expect(exact.pGreater, closeTo(1.0, 1e-12));
      expect(exact.meanPermuted, closeTo(0, 1e-12)); // 对称分布
    });

    test('完全枚举：观察值居中时双侧与两个单侧都可手算', () {
      // 差值 [3,-1,2]：8 种符号翻转下统计量（均值）
      //   [2, 0, 4/3, -2/3, 2/3, -4/3, 0, -2]，观察值 4/3
      //   |s| ≥ 4/3：2、4/3、-2、-4/3 共 4 个 → 双侧 (1+4)/9
      //   s ≥ 4/3：2、4/3 共 2 个 → (1+2)/9
      //   s ≤ 4/3：除 2 以外的 7 个 → (1+7)/9
      const diffs = [3.0, -1.0, 2.0];
      final stats = <double>[];
      for (var mask = 0; mask < 8; mask++) {
        var s = 0.0;
        for (var i = 0; i < diffs.length; i++) {
          s += ((mask >> i) & 1) == 1 ? diffs[i] : -diffs[i];
        }
        stats.add(s / diffs.length);
      }
      final exact = Permutation.exact(
        observed: 4 / 3,
        permutedStatistics: stats,
      );
      expect(exact.permutations, 8);
      expect(exact.pTwoTail, closeTo(5 / 9, 1e-12));
      expect(exact.pGreater, closeTo(3 / 9, 1e-12));
      expect(exact.pLess, closeTo(8 / 9, 1e-12));
    });

    test('随机置换收敛到真实尾概率，且同种子完全可复现', () {
      const a = [1.0, 2.0, 3.0];
      const b = [4.0, 6.0, 8.0];
      // 真实尾概率 2/20 = 0.1（加一校正在 B=20000 时可忽略）
      final r1 = Permutation.twoSampleMeanDifference(a, b, permutations: 20000);
      expect(r1.pTwoTail, closeTo(0.10, 0.01));
      expect(r1.observed, closeTo(-4.0, 1e-12));
      expect(r1.z, lessThan(0)); // 观察值在置换分布左侧

      final r2 = Permutation.twoSampleMeanDifference(a, b, permutations: 20000);
      expect(r2.pTwoTail, r1.pTwoTail);
      expect(r2.meanPermuted, r1.meanPermuted);

      final r3 = Permutation.twoSampleMeanDifference(a, b,
          permutations: 20000, seed: 7);
      expect((r3.pTwoTail - r1.pTwoTail).abs(), lessThan(0.02));
      expect(r3.seed, 7);
    });

    test('配对符号翻转：完全枚举与手算一致', () {
      // 差值 [1,2,3,4,5]，观察均值 3；|Σ±d| ≥ 15 只有全正/全负两种
      const diffs = [1.0, 2.0, 3.0, 4.0, 5.0];
      final stats = <double>[];
      for (var mask = 0; mask < 32; mask++) {
        var s = 0.0;
        for (var i = 0; i < 5; i++) {
          s += ((mask >> i) & 1) == 1 ? diffs[i] : -diffs[i];
        }
        stats.add(s / 5);
      }
      final exact = Permutation.exact(observed: 3.0, permutedStatistics: stats);
      expect(exact.permutations, 32);
      expect(exact.pTwoTail, closeTo(3 / 33, 1e-12));

      final mc = Permutation.pairedDifference(
        const [0.0, 0.0, 0.0, 0.0, 0.0],
        diffs,
        permutations: 20000,
      );
      expect(mc.observed, closeTo(3.0, 1e-12));
      expect(mc.pTwoTail, closeTo(2 / 32, 0.01)); // 真实尾概率 0.0625
    });

    test('数据不足返回 NaN', () {
      final r = Permutation.twoSampleMeanDifference(const [], const [1.0]);
      expect(r.pTwoTail.isNaN, isTrue);
      expect(r.permutations, 0);
    });
  });

  group('Lilliefors 正态性', () {
    test('p 值在已知 5% 临界值附近（0.886/√n）', () {
      // Lilliefors 的渐近 5% 临界值 ≈ 0.886/√n
      expect(Nonparametric.lillieforsP(0.886 / math.sqrt(100), 100),
          closeTo(0.05, 0.02));
      expect(Nonparametric.lillieforsP(0.886 / math.sqrt(40), 40),
          closeTo(0.05, 0.02));
    });

    test('p 随 D 单调下降且在 [0,1] 内', () {
      var last = 1.1;
      for (var d = 0.02; d <= 0.4; d += 0.01) {
        final p = Nonparametric.lillieforsP(d, 50);
        expect(p, lessThanOrEqualTo(last));
        expect(p, inInclusiveRange(0, 1));
        last = p;
      }
      expect(Nonparametric.lillieforsP(0, 50), 1);
    });

    test('与蒙特卡洛模拟的零分布一致（n=20, D=0.2）', () {
      // 独立验证：从正态分布抽样、每次重新估计均值/标准差后算 D，
      // 统计 D ≥ 0.2 的比例，应与 Dallal-Wilkinson 近似吻合。
      final rng = math.Random(7);
      const b = 2000;
      var hits = 0;
      for (var i = 0; i < b; i++) {
        final sample = <double>[];
        for (var j = 0; j < 20; j++) {
          final u1 = rng.nextDouble();
          final u2 = rng.nextDouble();
          sample.add(math.sqrt(-2 * math.log(u1 <= 0 ? 1e-12 : u1)) *
              math.cos(2 * math.pi * u2));
        }
        if (_ksD(sample) >= 0.2) hits++;
      }
      final pMc = hits / b;
      expect((pMc - Nonparametric.lillieforsP(0.2, 20)).abs(),
          lessThan(0.03), reason: 'MC=$pMc');
    });

    test('完全正态样本不拒绝、明显非正态样本拒绝', () {
      final normal = _normalQuantileSample(100);
      final rn = normalityTest(normal);
      expect(rn.p, greaterThan(0.05));
      expect(rn.looksNormal, isTrue);
      expect(rn.test, contains('Lilliefors'));

      // 双峰样本：D ≈ 0.34，p 远小于 0.01
      final bimodal = <double>[
        ...List.filled(30, 0.0),
        ...List.filled(30, 10.0),
      ];
      final rb = normalityTest(bimodal);
      expect(rb.statistic, greaterThan(0.3));
      expect(rb.p, lessThan(0.01));
      expect(rb.looksNormal, isFalse);
    });

    test('均匀样本与正态的 KS 距离其实很小（记录真实口径）', () {
      // 反直觉但真实：等距均匀样本对「最贴合的正态」的 KS 距离只有 0.067，
      // n=40 时 Lilliefors 不拒绝。正态性检验对均匀这类「平顶」分布不敏感，
      // 这不是实现缺陷，验收口径据此改成用双峰/强偏态样本。
      final uniform = List<double>.generate(40, (i) => i / 40.0);
      final r = normalityTest(uniform);
      expect(r.statistic, lessThan(0.08));
      expect(r.p, greaterThan(0.05));
    });

    test('修掉了「用 Kolmogorov 渐近 p 代替 Lilliefors p」的偏大问题', () {
      // 立方均匀（强右偏）：D ≈ 0.19，n=80
      final skewed = List<double>.generate(
          80, (i) => math.pow(i / 80.0, 3).toDouble());
      final r = Nonparametric.kolmogorovSmirnovNormal(skewed);
      final pKol = r.extra['pKolmogorovAsymptotic'] as double;
      // 参数被估计时 D 被抬高，Kolmogorov 渐近 p 系统性偏大（这里 0.005 对 1e-7）
      expect(r.p, lessThan(pKol));
      expect(r.p, lessThan(0.001));
      expect(pKol, greaterThan(0.001));
      expect(r.extra['pMethod'], 'lilliefors-dallal-wilkinson-1986');
      expect(r.extra['z'] as double,
          closeTo(math.sqrt(r.n1.toDouble()) * r.statistic, 1e-9));
      expect(r.statisticName, 'D');
    });
  });
}

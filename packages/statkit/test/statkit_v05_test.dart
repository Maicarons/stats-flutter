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

  group('多项 logistic', () {
    test('截距唯一模型：系数、标准误、似然都是闭式', () {
      // 计数 (8, 5, 7)，参考类别 = 2（默认取最大类别）
      //   β_k = log(n_k / n_ref)，Var(β_k) = 1/n_k + 1/n_ref（精确，非渐近）
      final y = <int>[
        ...List.filled(8, 0),
        ...List.filled(5, 1),
        ...List.filled(7, 2),
      ];
      final r = multinomialLogistic(const [], y);
      expect(r.reference, '2');
      expect(r.levels, [0, 1, 2]);
      expect(r.converged, isTrue);
      expect(r.coefficients.length, 2); // 只有非参考类别有方程
      expect(r.byLevel.length, 2);
      expect(r.byLevel[0][0].name, '(Constant)');
      expect(r.byLevel[0][0].beta, closeTo(math.log(8 / 7), 1e-9));
      expect(r.byLevel[1][0].beta, closeTo(math.log(5 / 7), 1e-9));
      expect(r.byLevel[0][0].se, closeTo(math.sqrt(1 / 8 + 1 / 7), 1e-6));
      expect(r.byLevel[1][0].se, closeTo(math.sqrt(1 / 5 + 1 / 7), 1e-6));
      // 截距唯一模型就是零模型：ll = ll0、伪 R² = 0
      final ll0 = 8 * math.log(8 / 20) + 5 * math.log(5 / 20) + 7 * math.log(7 / 20);
      expect(r.logLikelihood, closeTo(ll0, 1e-9));
      expect(r.logLikelihoodNull, closeTo(ll0, 1e-12));
      expect(r.pseudoR2, closeTo(0, 1e-9));
      expect(r.gradientNorm, lessThan(1e-8));
      // 概率等于样本比例，全部预测到众数类别
      for (final row in r.probabilities) {
        expect(row[0], closeTo(0.4, 1e-9));
        expect(row[1], closeTo(0.25, 1e-9));
        expect(row[2], closeTo(0.35, 1e-9));
      }
      expect(r.accuracy, closeTo(0.4, 1e-12));
      expect(r.confusion[0][0], 8);
      expect(r.confusion[1][0], 5);
      expect(r.confusion[2][0], 7);
    });

    test('饱和设计（x∈{0,1}）：系数与标准误都是闭式', () {
      // 组 0 计数 (10,5,5)、组 1 计数 (3,12,5)，参考类别 2
      //   α_k = log(n_0k/n_02)，γ_k = log(n_1k/n_12) − log(n_0k/n_02)
      //   Var(α_k) = 1/n_0k + 1/n_02（观测信息与 y 无关，是精确值）
      //   Var(γ_k) = (1/n_0k + 1/n_02) + (1/n_1k + 1/n_12)，两组信息块对角
      final x = <double>[], y = <int>[];
      for (var g = 0; g < 2; g++) {
        final counts = g == 0 ? const [10, 5, 5] : const [3, 12, 5];
        for (var k = 0; k < 3; k++) {
          for (var i = 0; i < counts[k]; i++) {
            x.add(g.toDouble());
            y.add(k);
          }
        }
      }
      final r = multinomialLogistic([x], y, names: ['G']);
      expect(r.converged, isTrue);
      expect(r.dfModel, 2); // (k−1)·p = 2·1
      final alpha = [math.log(10 / 5), math.log(5 / 5)];
      final gamma = [
        math.log(3 / 5) - math.log(10 / 5),
        math.log(12 / 5) - math.log(5 / 5),
      ];
      final seAlpha = [math.sqrt(1 / 10 + 1 / 5), math.sqrt(1 / 5 + 1 / 5)];
      final seGamma = [
        math.sqrt(1 / 10 + 1 / 5 + 1 / 3 + 1 / 5),
        math.sqrt(1 / 5 + 1 / 5 + 1 / 12 + 1 / 5),
      ];
      for (var q = 0; q < 2; q++) {
        expect(r.byLevel[q][0].beta, closeTo(alpha[q], 1e-8));
        expect(r.byLevel[q][1].beta, closeTo(gamma[q], 1e-8));
        expect(r.byLevel[q][0].se, closeTo(seAlpha[q], 1e-6));
        expect(r.byLevel[q][1].se, closeTo(seGamma[q], 1e-6));
      }
      // 饱和模型的拟合概率 = 各组内的样本比例
      expect(r.probabilities[0][0], closeTo(0.5, 1e-9));
      expect(r.probabilities[0][1], closeTo(0.25, 1e-9));
      expect(r.probabilities[20][1], closeTo(12 / 20, 1e-9));
    });

    test('二分类时与 logisticRegressionFull 完全一致（含正负号）', () {
      // 真实的 Bernoulli 抽样（避免完全分离）
      final rng = math.Random(3);
      final x1 = <double>[], x2 = <double>[], y = <int>[];
      for (var i = 0; i < 60; i++) {
        final a = rng.nextDouble() * 4 - 2;
        final b = rng.nextDouble() * 4 - 2;
        x1.add(a);
        x2.add(b);
        final p = 1 / (1 + math.exp(-(0.9 * a - 0.6 * b + 0.2)));
        y.add(rng.nextDouble() < p ? 1 : 0);
      }
      final bin = logisticRegressionFull([x1, x2], y, names: ['X1', 'X2']);
      final mul = multinomialLogistic([x1, x2], y, names: ['X1', 'X2']);
      expect(mul.converged, isTrue);
      expect(bin.converged, isTrue);
      // 参考类别是 1，所以多项式的方程是「0 对 1」，与二分类互为相反数
      for (var q = 0; q < 3; q++) {
        expect(mul.byLevel[0][q].beta, closeTo(-bin.coefficients[q].beta, 1e-6));
        expect(mul.byLevel[0][q].se, closeTo(bin.coefficients[q].se, 1e-6));
      }
      // 两条路径的收敛点相差 O(λβ/I) ≈ 5e-8（岭引起的极小偏差）
      expect(mul.logLikelihood, closeTo(bin.logLikelihood, 1e-6));
      expect(mul.pseudoR2, closeTo(bin.pseudoR2, 1e-6));
      expect(mul.accuracy, closeTo(bin.table.accuracy, 1e-12));
      expect(mul.byLevel[0][0].oddsRatio,
          closeTo(1 / bin.coefficients[0].oddsRatio, 1e-6));
    });

    test('换参考类别：系数按理论平移，预测不变', () {
      // 真实 softmax 生成（避免完全分离）：e = [0, 1.1v−0.4, −0.8v+0.6]
      final rng = math.Random(5);
      final x = <double>[], y = <int>[];
      for (var i = 0; i < 80; i++) {
        final v = rng.nextDouble() * 3 - 1.5;
        x.add(v);
        final eta = [0.0, 1.1 * v - 0.4, -0.8 * v + 0.6];
        final mx = eta.reduce(math.max);
        final p = [for (final e in eta) math.exp(e - mx)];
        final s = p.reduce((a, b) => a + b);
        final u = rng.nextDouble() * s;
        y.add(u < p[0] ? 0 : (u < p[0] + p[1] ? 1 : 2));
      }
      final r2 = multinomialLogistic([x], y, referenceLevel: 2);
      final r0 = multinomialLogistic([x], y, referenceLevel: 0);
      expect(r2.converged, isTrue);
      expect(r0.converged, isTrue);
      expect(r2.reference, '2');
      expect(r0.reference, '0');
      // r2 的方程是「0 对 2」「1 对 2」；r0 是「1 对 0」「2 对 0」
      //   β(1|0) = β(1|2) − β(0|2)，β(2|0) = −β(0|2)
      for (var j = 0; j < 2; j++) {
        expect(r0.byLevel[0][j].beta,
            closeTo(r2.byLevel[1][j].beta - r2.byLevel[0][j].beta, 1e-8));
        expect(r0.byLevel[1][j].beta,
            closeTo(-r2.byLevel[0][j].beta, 1e-8));
      }
      // 概率与命中率与参考类别无关
      for (var i = 0; i < 80; i++) {
        for (var c = 0; c < 3; c++) {
          expect(r0.probabilities[i][c], closeTo(r2.probabilities[i][c], 1e-9));
        }
      }
      expect(r0.accuracy, r2.accuracy);
      expect(r0.logLikelihood, closeTo(r2.logLikelihood, 1e-9));
    });

    test('概率归一、类别标签与异常输入', () {
      final rng = math.Random(9);
      final x = <double>[], y = <int>[];
      for (var i = 0; i < 60; i++) {
        final v = rng.nextDouble() * 4 - 2;
        x.add(v);
        final eta = [0.0, 0.6 * v, -0.9 * v + 0.8];
        final mx = eta.reduce(math.max);
        final p = [for (final e in eta) math.exp(e - mx)];
        final s = p.reduce((a, b) => a + b);
        final u = rng.nextDouble() * s;
        y.add(u < p[0] ? 0 : (u < p[0] + p[1] ? 1 : 2));
      }
      final r = multinomialLogistic(
        [x],
        y,
        names: ['X'],
        levelLabels: ['低', '中', '高'],
      );
      expect(r.converged, isTrue);
      for (final row in r.probabilities) {
        expect(row.reduce((a, b) => a + b), closeTo(1, 1e-12));
        for (final v in row) {
          expect(v, inInclusiveRange(0, 1));
        }
      }
      expect(r.levelLabels, ['低', '中', '高']);
      expect(r.reference, '高'); // 默认取最大类别，标签跟着走
      expect(r.coefficients.map((c) => c.level).toSet(), {'低', '中'});
      expect(r.names, ['(Constant)', 'X']);
      expect(r.levels, [0, 1, 2]);
      expect(r.levelCounts.reduce((a, b) => a + b), 60);
      expect(() => multinomialLogistic([x], List<int>.filled(60, 7)),
          throwsArgumentError); // 只有一个类别
      // 自变量长度与因变量不一致 / 参考类别不存在
      expect(() => multinomialLogistic([x.sublist(0, 59)], y),
          throwsArgumentError);
      expect(() => multinomialLogistic([x], y, referenceLevel: 9),
          throwsArgumentError);
      expect(multinomialLogistic([x], y).lrP, inInclusiveRange(0, 1));
    });
  });

  group('协方差分析 ANCOVA', () {
    /// 单元 ANCOVA 的同一份数据：3 组 × 10 例，组内 x 均值不同（1..10 + 0.7g）
    ({List<String> a, List<double> y, List<double> x}) oneWayData() {
      final a = <String>[], y = <double>[], x = <double>[];
      for (var g = 0; g < 3; g++) {
        for (var i = 1; i <= 10; i++) {
          final xv = i + g * 0.7;
          a.add('G$g');
          x.add(xv);
          // 真值：截距 5 + 组效应 2g + 斜率 1.5x，叠加确定性的小扰动
          y.add(5 + g * 2 + 1.5 * xv + (((i * 7 + g) % 5) - 2) * 0.1);
        }
      }
      return (a: a, y: y, x: x);
    }

    test('类型 III 平方和与 FWL 残差化一致（两条独立路径）', () {
      final d = oneWayData();
      final r = ancova(
        y: d.y,
        a: d.a,
        covariates: {'x': d.x},
        aName: 'G',
        yName: 'Y',
      );
      expect(r.n, 30);
      expect(r.nParams, 4); // 截距 + (3−1) 个组效应列 + 1 个协变量列
      expect(r.dfError, 26);
      expect(r.yName, 'Y');
      expect(r.factorNames, ['G']);
      expect(r.covariateNames, ['x']);
      expect(r.terms.length, 2);
      expect(r.terms[0].name, 'G');
      expect(r.terms[0].isCovariate, isFalse);
      expect(r.terms[0].df, 2);
      expect(r.terms[0].ss, closeTo(77.38887829, 1e-6));
      expect(r.terms[0].ms, closeTo(38.69443915, 1e-6));
      expect(r.terms[0].f, closeTo(1723.1745, 1e-3));
      expect(r.terms[0].partialEta2, greaterThan(0.99));
      expect(r.terms[1].name, 'x');
      expect(r.terms[1].isCovariate, isTrue);
      expect(r.terms[1].df, 1);
      expect(r.terms[1].ss, closeTo(550.891162, 1e-6));
      expect(r.ssError, closeTo(0.58383838, 1e-8));
      expect(r.ssTotal, closeTo(737.525, 1e-8));
      expect(r.ssModel, closeTo(r.ssTotal - r.ssError, 1e-9));
      expect(r.msError, closeTo(r.ssError / 26, 1e-12));
      expect(r.r2, closeTo(0.999208, 1e-6));
      expect(r.rmse, closeTo(math.sqrt(r.ssError / 26), 1e-12));
      expect(r.covariateMeans['x'], closeTo(6.2, 1e-12));

      // 独立路径（Frisch–Waugh–Lovell）：SS_G = Σỹ² − SSE(ỹ ~ 残差化后的效应编码列)
      // 用 regression.dart 的另一套 OLS 实现，与 ancova 内部的求解无关
      final yRes = Regression.multiple([d.x], d.y).residuals;
      final eff = <List<double>>[
        for (var g = 0; g < 2; g++)
          [
            for (var i = 0; i < d.a.length; i++)
              d.a[i] == 'G$g' ? 1.0 : (d.a[i] == 'G2' ? -1.0 : 0.0)
          ]
      ];
      final eRes = [for (final e in eff) Regression.multiple([d.x], e).residuals];
      final residFit = Regression.multiple(eRes, yRes);
      final ssG = yRes.fold<double>(0, (s, v) => s + v * v) -
          residFit.ssResidual;
      expect(ssG, closeTo(r.terms[0].ss, 1e-8));
    });

    test('协变量斜率 = 组内合并斜率（经典 ANCOVA 恒等式）', () {
      final d = oneWayData();
      final r = ancova(y: d.y, a: d.a, covariates: {'x': d.x}, aName: 'G');
      expect(r.slopes.length, 1);
      expect(r.slopes[0].name, 'x');
      // 分组分别做一元回归，再按组内 SS_x 合并（同斜率的极大似然解）
      var num = 0.0, den = 0.0;
      for (var g = 0; g < 3; g++) {
        final xx = <double>[], yy = <double>[];
        for (var i = 0; i < d.a.length; i++) {
          if (d.a[i] == 'G$g') {
            xx.add(d.x[i]);
            yy.add(d.y[i]);
          }
        }
        final fit = Regression.simple(xx, yy);
        final xb = xx.reduce((p, q) => p + q) / xx.length;
        final yb = yy.reduce((p, q) => p + q) / yy.length;
        var sxx = 0.0, sxy = 0.0;
        for (var i = 0; i < xx.length; i++) {
          sxx += (xx[i] - xb) * (xx[i] - xb);
          sxy += (xx[i] - xb) * (yy[i] - yb);
        }
        num += sxy;
        den += sxx;
        // 各组自己的斜率
        expect(fit.coefficients[1].beta, closeTo(sxy / sxx, 1e-12));
      }
      // 内部求解加了 1e-12 量级的岭（仅为数值可逆），偏差 ~1e-10
      expect(r.slopes[0].b, closeTo(num / den, 1e-9));
      expect(r.slopes[0].b, closeTo(1.491919, 1e-6));
      expect(r.slopes[0].se, closeTo(0.009525, 1e-6));
      expect(r.slopes[0].t, closeTo(r.slopes[0].b / r.slopes[0].se, 1e-12));
      expect(r.slopes[0].p, lessThan(1e-30));
      expect(r.slopes[0].ciLower95, lessThan(r.slopes[0].b));
      expect(r.slopes[0].ciUpper95, greaterThan(r.slopes[0].b));
    });

    test('调整均值等于 ȳ_g − b(x̄_g − x̄)，且确实与原始均值不同', () {
      final d = oneWayData();
      final r = ancova(y: d.y, a: d.a, covariates: {'x': d.x}, aName: 'G');
      final b = r.slopes[0].b;
      final xBar = d.x.reduce((p, q) => p + q) / d.x.length;
      expect(r.means.length, 3);
      for (var g = 0; g < 3; g++) {
        final idx = [
          for (var i = 0; i < d.a.length; i++)
            if (d.a[i] == 'G$g') i
        ];
        final yBar =
            idx.map((i) => d.y[i]).reduce((p, q) => p + q) / idx.length;
        final xBarG =
            idx.map((i) => d.x[i]).reduce((p, q) => p + q) / idx.length;
        final m = r.means.firstWhere((e) => e.level == 'G$g');
        expect(m.factor, 'G');
        expect(m.n, 10);
        expect(m.raw, closeTo(yBar, 1e-12));
        expect(m.adjusted, closeTo(yBar - b * (xBarG - xBar), 1e-8));
        // 0、2 两组的 x 均值偏离总体均值 0.7 → 调整量恰好是 0.7b ≈ 1.044；
        // 1 组的 x 均值恰好等于总体均值 6.2，调整量为 0（对称设计）
        if (g == 1) {
          expect((m.adjusted - m.raw).abs(), lessThan(1e-8));
        } else {
          expect((m.adjusted - m.raw).abs(), closeTo(0.7 * b, 1e-8));
        }
        expect(m.se, greaterThan(0));
        expect(m.ciLower95, closeTo(m.adjusted - tCritical(26, 0.05) * m.se, 1e-9));
        expect(m.ciUpper95, closeTo(m.adjusted + tCritical(26, 0.05) * m.se, 1e-9));
      }
      expect(r.means[0].adjusted, closeTo(14.29434343, 1e-7));
      expect(r.means[1].adjusted, closeTo(16.30000000, 1e-7));
      expect(r.means[2].adjusted, closeTo(18.30565657, 1e-7));
      // 调整后组间仍保持约 2.0 的间隔（真值），且三段间隔严格相等
      // （各组 x 均值等差 + 共斜率 → 相邻调整均值之差相同）
      final d1 = r.means[1].adjusted - r.means[0].adjusted;
      final d2 = r.means[2].adjusted - r.means[1].adjusted;
      expect(d1, closeTo(d2, 1e-9));
      expect(d1, closeTo(2.0, 0.01));
    });

    test('无协变量的平衡双因子退化为 glmTwoWay 的经典 ANOVA', () {
      final cells = <(String, String), List<double>>{};
      final a = <String>[], b = <String>[], y = <double>[];
      for (final av in ['a1', 'a2']) {
        for (final bv in ['b1', 'b2', 'b3']) {
          final vals = <double>[];
          for (var i = 0; i < 5; i++) {
            final v = 3.0 +
                (av == 'a1' ? 0 : 2.0) +
                (bv == 'b1' ? 0 : (bv == 'b2' ? -1.0 : 0.5)) +
                (av == 'a2' && bv == 'b2' ? 1.5 : 0) +
                ((i * 3 + av.codeUnitAt(1) + bv.codeUnitAt(1)) % 4 - 1.5) * 0.3;
            vals.add(v);
            a.add(av);
            b.add(bv);
            y.add(v);
          }
          cells[(av, bv)] = vals;
        }
      }
      final g = glmTwoWay(cells);
      final r = ancova(y: y, a: a, b: b, aName: 'A', bName: 'B');
      expect(r.nParams, 6); // 截距 + 1 + 2 + 2
      expect(r.dfError, 24);
      expect(r.covariateNames, isEmpty);
      expect(r.slopes, isEmpty);
      for (var i = 0; i < 3; i++) {
        expect(r.terms[i].name, g.terms[i].name);
        expect(r.terms[i].df, g.terms[i].df);
        // 平衡设计里类型 I = II = III
        expect(r.terms[i].ss, closeTo(g.terms[i].ss, 1e-9));
        expect(r.terms[i].ms, closeTo(g.terms[i].ms, 1e-9));
        expect(r.terms[i].f, closeTo(g.terms[i].f, 1e-9));
        expect(r.terms[i].p, closeTo(g.terms[i].p, 1e-9));
      }
      expect(r.ssError, closeTo(g.ssError, 1e-9));
      expect(r.dfError, g.dfError);
      expect(r.r2, closeTo(g.r2, 1e-9));
      // 两因子时给出 A、B 与 A×B 三套调整均值（无协变量 → 等于原始均值）
      expect(r.means.length, 2 + 3 + 6);
      for (final m in r.means) {
        expect(m.adjusted, closeTo(m.raw, 1e-9));
      }
    });

    test('协变量显著时组间差异被正确剥离', () {
      // 两组的 x 完全不重叠：未调整看差异巨大，控制 x 后差异消失
      final a = <String>[], y = <double>[], x = <double>[];
      for (var g = 0; g < 2; g++) {
        for (var i = 0; i < 20; i++) {
          final xv = g == 0 ? 1.0 + i * 0.5 : 11.0 + i * 0.5;
          a.add('T$g');
          x.add(xv);
          y.add(10 + 2.0 * xv + ((i * 5) % 7 - 3) * 0.05);
        }
      }
      final r = ancova(y: y, a: a, covariates: {'x': x}, aName: 'T');
      final unadj = glmOneWay({
        'T0': [for (var i = 0; i < 20; i++) y[i]],
        'T1': [for (var i = 20; i < 40; i++) y[i]],
      });
      // 未调整：组效应极显著
      expect(unadj.terms[0].f, greaterThan(100));
      expect(unadj.terms[0].p, lessThan(1e-10));
      // 调整后：组效应不再显著
      expect(r.terms[0].f, lessThan(1));
      expect(r.terms[0].p, greaterThan(0.1));
      // 斜率恢复真值 2.0
      expect(r.slopes[0].b, closeTo(2.0, 5e-3));
      expect(r.slopes[0].p, lessThan(1e-30));
      // 原始均值差 > 15，调整均值差 < 0.1
      final raw = [for (final m in r.means) m.raw];
      final adj = [for (final m in r.means) m.adjusted];
      expect((raw[0] - raw[1]).abs(), greaterThan(15));
      expect((adj[0] - adj[1]).abs(), lessThan(0.1));
    });

    test('双因子 + 协变量：类型 III 平方和与独立手算一致', () {
      final a = <String>[], b = <String>[], y = <double>[], x = <double>[];
      for (final av in ['a1', 'a2']) {
        for (final bv in ['b1', 'b2']) {
          for (var i = 0; i < 8; i++) {
            final xv = 1.0 + i;
            a.add(av);
            b.add(bv);
            x.add(xv);
            y.add(2 +
                (av == 'a2' ? 1.0 : 0) +
                (bv == 'b2' ? -0.8 : 0) +
                (av == 'a2' && bv == 'b2' ? 2.2 : 0) +
                1.2 * xv +
                ((i * 3 + av.codeUnitAt(1)) % 4 - 1.5) * 0.2);
          }
        }
      }
      final r = ancova(y: y, a: a, b: b, covariates: {'x': x});
      expect(r.n, 32);
      expect(r.nParams, 5); // 截距 + 1 + 1 + 1 + 1
      expect(r.dfError, 27);
      expect(r.terms.map((t) => t.name).toList(), ['A', 'B', 'A×B', 'x']);
      expect(r.terms.map((t) => t.isCovariate).toList(),
          [false, false, false, true]);

      // 独立手算：效应编码列 + regression.dart 的 OLS，逐项去掉求差
      List<double> eff2(List<String> v, String first) => [
            for (var i = 0; i < v.length; i++) v[i] == first ? 1.0 : -1.0
          ];
      final ca = eff2(a, 'a1');
      final cb = eff2(b, 'b1');
      final cab = [for (var i = 0; i < y.length; i++) ca[i] * cb[i]];
      final all = <List<double>>[ca, cb, cab, x];
      final full = Regression.multiple(all, y).ssResidual;
      final names = ['A', 'B', 'A×B', 'x'];
      for (var t = 0; t < 4; t++) {
        final reduced = [
          for (var j = 0; j < 4; j++)
            if (j != t) all[j]
        ];
        final sseRed = Regression.multiple(reduced, y).ssResidual;
        expect(r.terms[t].ss, closeTo(sseRed - full, 1e-8), reason: names[t]);
      }
      expect(r.ssError, closeTo(full, 1e-8));
      expect(r.slopes[0].b, closeTo(1.219048, 1e-6));
      expect(r.slopes[0].se, closeTo(0.018420, 1e-6));

      // A×B 单元调整均值（在 x 的总体均值处求值），边缘均值 = 单元均值的等权平均
      final cell = {
        for (final m in r.means.where((m) => m.factor == 'A×B')) m.level: m.adjusted
      };
      expect(cell['a1 × b1'], closeTo(7.4, 1e-3));
      expect(cell['a1 × b2'], closeTo(6.6, 1e-3));
      expect(cell['a2 × b1'], closeTo(8.4, 1e-3));
      expect(cell['a2 × b2'], closeTo(9.8, 1e-3));
      final ma = {
        for (final m in r.means.where((m) => m.factor == 'A')) m.level: m.adjusted
      };
      expect(ma['a1'], closeTo((cell['a1 × b1']! + cell['a1 × b2']!) / 2, 1e-9));
      expect(ma['a2'], closeTo((cell['a2 × b1']! + cell['a2 × b2']!) / 2, 1e-9));
      final mb = {
        for (final m in r.means.where((m) => m.factor == 'B')) m.level: m.adjusted
      };
      expect(mb['b1'],
          closeTo((cell['a1 × b1']! + cell['a2 × b1']!) / 2, 1e-9));
      expect(mb['b2'],
          closeTo((cell['a1 × b2']! + cell['a2 × b2']!) / 2, 1e-9));
      expect(r.covariateMeans['x'], closeTo(4.5, 1e-12));
    });

    test('各格样本数不等时类型 III 不偏（与序列平方和不同）', () {
      // 三组样本数不等（8 / 14 / 5），且各组 x 的分布不同
      final a = <String>[], y = <double>[], x = <double>[];
      const sizes = [8, 14, 5];
      for (var g = 0; g < 3; g++) {
        for (var i = 0; i < sizes[g]; i++) {
          final xv = 1.0 + i * 0.9 + g * 2.5;
          a.add('K$g');
          x.add(xv);
          y.add(4 + g * 1.5 + 1.8 * xv + (((i * 11 + g * 3) % 7) - 3) * 0.08);
        }
      }
      final r = ancova(y: y, a: a, covariates: {'x': x}, aName: 'K');
      expect(r.n, 27);
      expect(r.nParams, 4);
      expect(r.dfError, 23);

      // 类型 III：独立手算 = SSE(截距 + x) − SSE(截距 + x + 组效应列)
      final eff = <List<double>>[
        for (var g = 0; g < 2; g++)
          [
            for (var i = 0; i < a.length; i++)
              a[i] == 'K$g' ? 1.0 : (a[i] == 'K2' ? -1.0 : 0.0)
          ]
      ];
      final withX = Regression.multiple([x], y).ssResidual;
      final full = Regression.multiple([x, ...eff], y).ssResidual;
      expect(r.terms[0].ss, closeTo(withX - full, 1e-8));
      expect(r.ssError, closeTo(full, 1e-8));

      // 序列（类型 I，先组后协变量）平方和：Σ(y − ȳ)² − SSE(截距 + 组)
      final yBar = y.reduce((p, q) => p + q) / y.length;
      final ssTotal = y.fold<double>(0, (s, v) => s + (v - yBar) * (v - yBar));
      final ssA1 = ssTotal - Regression.multiple(eff, y).ssResidual;
      // 协变量与分组相关 → 两种口径必须明显不同；类型 III 才是「控制协变量后」的组效应
      expect((ssA1 - r.terms[0].ss).abs(), greaterThan(1));
    });

    test('多个协变量与参数校验', () {
      final rng = math.Random(17);
      final a = <String>[], y = <double>[], x1 = <double>[], x2 = <double>[];
      for (var g = 0; g < 2; g++) {
        for (var i = 0; i < 25; i++) {
          final u = rng.nextDouble() * 3;
          final v = rng.nextDouble() * 2;
          a.add('P$g');
          x1.add(u);
          x2.add(v);
          y.add(1.0 + g * 0.5 + 1.4 * u - 0.9 * v + rng.nextDouble() * 0.05);
        }
      }
      final r = ancova(y: y, a: a, covariates: {'x1': x1, 'x2': x2});
      expect(r.covariateNames, ['x1', 'x2']);
      expect(r.slopes.length, 2);
      expect(r.nParams, 4); // 截距 + 1 个组效应列 + 2 个协变量列
      expect(r.dfError, 46);
      expect(r.slopes[0].b, closeTo(1.4, 0.02));
      expect(r.slopes[1].b, closeTo(-0.9, 0.02));
      expect(r.terms.length, 3);
      expect(r.terms[2].isCovariate, isTrue);

      // 长度不一致
      expect(() => ancova(y: [1.0, 2.0], a: ['a', 'b'], covariates: {'x': [1.0]}),
          throwsArgumentError);
      expect(() => ancova(y: [1.0, 2.0], a: ['a', 'b'], b: ['u']),
          throwsArgumentError);
      // 因子只有一个水平
      expect(() => ancova(y: [1.0, 2.0], a: ['a', 'a']), throwsArgumentError);
      // 空单元：A×B 有一个组合没有观测 → 交互项不可估计
      expect(
          () => ancova(
                y: [1.0, 2.0, 3.0, 4.0],
                a: ['a1', 'a1', 'a1', 'a2'],
                b: ['b1', 'b1', 'b2', 'b1'],
              ),
          throwsArgumentError);
      // 数据为空
      expect(() => ancova(y: const [], a: const []), throwsArgumentError);
    });
  });

  group('正态分位数 normalQuantile', () {
    test('与已知临界值一致（Acklam 近似，误差 < 1.5e-9）', () {
      // 双侧 0.05 / 0.01 的临界值
      expect(normalQuantile(0.975), closeTo(1.959963985, 1e-8));
      expect(normalQuantile(0.995), closeTo(2.575829304, 1e-8));
      // 常用单侧临界值
      expect(normalQuantile(0.90), closeTo(1.281551566, 1e-8));
      expect(normalQuantile(0.99), closeTo(2.326347874, 1e-8));
      // 尾部与中位数
      expect(normalQuantile(0.5), closeTo(0, 1e-12));
      expect(normalQuantile(0.025), closeTo(-1.959963985, 1e-8));
      expect(normalQuantile(0.001), closeTo(-3.090232306, 1e-7));
    });

    test('是 normCdf 的反函数（含两端钳制）', () {
      for (final p in [0.001, 0.01, 0.2, 0.5, 0.8, 0.99, 0.999]) {
        expect(normCdf(normalQuantile(p)), closeTo(p, 1e-6));
      }
      // 越界钳到 ±6
      expect(normalQuantile(0), -6);
      expect(normalQuantile(1), 6);
      expect(normalQuantile(-0.5), -6);
    });

    test('严格单调递增', () {
      var prev = double.negativeInfinity;
      for (var i = 1; i <= 999; i++) {
        final z = normalQuantile(i / 1000);
        expect(z, greaterThan(prev));
        prev = z;
      }
    });
  });

  group('Levene 方差齐性：默认对组均值（PSPP / SPSS 口径）', () {
    // PSPP tests/language/commands/oneway.at「ONEWAY basic operation」的三组
    const g1 = [3.0, 2.0, 1.0, 1.0, 4.0];
    const g2 = [4.0, 2.0, 3.0, 5.0, 2.0];
    const g3 = [7.0, 4.0, 5.0, 3.0, 6.0];

    test('默认（组均值）：F = 0.0917，PSPP 打印 .09（2,12）p=.913', () {
      final r = leveneTest([g1, g2, g3]);
      expect(r.f, closeTo(0.0917, 0.0001));
      expect(r.df1, 2);
      expect(r.df2, 12);
      expect(r.p, closeTo(0.913, 0.001));
    });

    test('useMean: false 时是 Brown-Forsythe（组中位数）：F = 0.1176', () {
      final r = leveneTest([g1, g2, g3], useMean: false);
      expect(r.f, closeTo(0.1176, 0.0001));
    });

    test('独立样本 t 检验沿用同一口径（均值中心）', () {
      final r = TTest.independentSamples(g1, g2);
      final direct = leveneTest([g1, g2]);
      expect(r.leveneF, closeTo(direct.f, 1e-12));
      expect(r.leveneP, closeTo(direct.p, 1e-12));
    });
  });
}

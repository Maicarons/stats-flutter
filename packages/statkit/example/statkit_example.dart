// A tour of statkit.
//
// Run it with:
//
//   dart run example/statkit_example.dart
//
// Every number is computed from the small samples declared in this file, so
// the output is reproducible without any data files.
import 'package:statkit/statkit.dart';

void main() {
  // ---- Descriptive statistics ---------------------------------------------
  const scores = <double>[88, 92, 79, 93, 85, 90, 76, 89, 95, 81];
  final d = Descriptives.compute(scores);
  print('Descriptives     n=${d.n} mean=${formatNum(d.mean)} sd=${formatNum(d.sd)} '
      '95% CI=[${formatNum(d.ciLower95)}, ${formatNum(d.ciUpper95)}]');

  // ---- t tests ------------------------------------------------------------
  final one = TTest.oneSample(scores, mu0: 85);
  print('One-sample t     t=${formatNum(one.t)} df=${formatNum(one.df)} '
      'p=${formatP(one.pTwoTail)} d=${formatNum(one.cohensD)}');

  const methodA = <double>[78, 84, 75, 88, 82, 79];
  const methodB = <double>[91, 87, 94, 85, 90, 92, 89];
  final ind = TTest.independentSamples(methodA, methodB);
  print('Independent t    t=${formatNum(ind.t)} p=${formatP(ind.pTwoTail)} '
      'Levene p=${formatP(ind.leveneP ?? double.nan)} '
      'equal variances assumed=${ind.equalVarAssumed}');

  // ---- One-way ANOVA (Levene is mean-centred, the PSPP / SPSS convention) --
  const methodC = <double>[70, 74, 68, 79, 72, 76];
  final anova =
      OnewayAnova.compute([methodA, methodB, methodC], labels: ['A', 'B', 'C']);
  print('One-way ANOVA    F=${formatNum(anova.f)} p=${formatP(anova.p)} '
      'eta2=${formatNum(anova.etaSquared)} '
      'Levene F=${formatNum(anova.levene.f)} p=${formatP(anova.levene.p)}');

  // ---- Correlation and simple regression ----------------------------------
  const hours = <double>[1, 2, 3, 4, 5, 6, 7, 8];
  const exam = <double>[52, 58, 63, 69, 74, 76, 84, 88];
  final corr = Correlation.pearson(hours, exam);
  final reg = Regression.simple(hours, exam);
  print('Correlation      r=${formatNum(corr.r)} n=${corr.n}');
  print('Simple regression R2=${formatNum(reg.r2)} '
      'slope=${formatNum(reg.coefficients[1].beta)} '
      'p=${formatP(reg.coefficients[1].p)}');

  // ---- Chi-square test of independence ------------------------------------
  final chi = ChiSquareTest.independence([
    [30, 20],
    [15, 35],
  ]);
  print('Chi-square       chi2=${formatNum(chi.chiSquare)} df=${chi.df} '
      'p=${formatP(chi.p)} CramersV=${formatNum(chi.cramersV ?? double.nan)}');

  // ---- Nonparametric: Mann-Whitney U (tie-corrected, PSPP's p) ------------
  const group1 = <double>[88, 99, 55, 69, 91, 201, 88, 75, 99, 81];
  const group2 = <double>[201, 84, 83, 94, 86, 79, 88, 85, 82, 72];
  final mw = Nonparametric.mannWhitney(group1, group2);
  print('Mann-Whitney U   U=${formatNum(mw.statistic)} '
      'z=${formatNum(mw.z ?? double.nan)} '
      'p=${formatP(mw.p)} mean ranks=${formatNum(mw.meanRank1 ?? double.nan)}'
      ' / ${formatNum(mw.meanRank2 ?? double.nan)}');

  // ---- Kendall W: judge x object agreement --------------------------------
  final kw = NparExtended.kendallW([
    [1, 1, 1, 1],
    [2, 2, 2, 2],
    [3, 3, 3, 3],
  ]);
  print('Kendall W        W=${formatNum(kw.statistic)} '
      'chi2=${formatNum(kw.extra['chiSquare'] as double)} '
      'p=${formatP(kw.p)}');

  // ---- Exact one-sample KS against a fully specified U(0,1) ---------------
  final ksx = NparExtended.ksExact(group1.map((v) => v / 250).toList(),
      (x) => x.clamp(0.0, 1.0));
  print('KS exact         D=${formatNum(ksx.statistic)} '
      'p=${formatP(ksx.p)} (Marsaglia-Tsang-Wang)');

  // ---- One-way MANOVA: Wilks / Pillai / Hotelling-Lawley / Roy ------------
  final mv = oneWayManova(
    groups: {
      'A': [for (var i = 0; i < 20; i++) [i * 0.1, i * 0.05 + 1]],
      'B': [for (var i = 0; i < 20; i++) [i * 0.1 + 2, i * 0.05 + 2]],
    },
    dvNames: ['y1', 'y2'],
    factorName: 'grp',
  );
  print('MANOVA Wilks     L=${formatNum(mv.wilks.value)} '
      'F=${formatNum(mv.wilks.f)} p=${formatP(mv.wilks.p)}');
  print('MANOVA Pillai    V=${formatNum(mv.pillai.value)} '
      'F=${formatNum(mv.pillai.f)} p=${formatP(mv.pillai.p)}');

  // ---- Permutation test: no distributional assumption ---------------------
  final perm =
      Permutation.twoSampleMeanDifference(group1, group2, permutations: 5000);
  print('Permutation      observed diff=${formatNum(perm.observed)} '
      'p=${formatP(perm.pTwoTail)} (${perm.permutations} resamples)');

  // ---- Normality: KS with the Lilliefors correction -----------------------
  final norm = normalityTest(scores);
  print('Normality        ${norm.test} D=${formatNum(norm.statistic)} '
      'p=${formatP(norm.p)} looks normal=${norm.looksNormal}');

  // ---- Reliability: Cronbach alpha ----------------------------------------
  final alpha = Reliability.cronbachAlpha([
    <double>[4, 5, 3, 4, 5, 2],
    <double>[3, 4, 4, 5, 4, 3],
    <double>[5, 5, 4, 4, 5, 4],
  ], names: ['q1', 'q2', 'q3']);
  print('Cronbach alpha   alpha=${formatNum(alpha.alpha)} '
      'standardised=${formatNum(alpha.standardizedAlpha)} '
      'items=${alpha.nItems} cases=${alpha.nCases}');

  // ---- K-means clustering -------------------------------------------------
  final points = List.generate(
    12,
    (i) => <double>[
      i < 6 ? (i % 3) * 0.4 : 10 + (i % 3) * 0.3,
      i < 6 ? (i % 2) * 0.5 : 10 + (i % 2) * 0.4,
    ],
  );
  final km = KMeans.cluster(points, k: 2, seed: 42, variableNames: ['x', 'y']);
  print('K-means          k=${km.k} iterations=${km.iterations} '
      'inertia=${formatNum(km.inertia)} '
      'sizes=${km.centers.map((c) => c.size).toList()}');

  print('');
  print('Significance stars: p=.004 -> ${significanceStars(0.004)}, '
      'p=.037 -> ${significanceStars(0.037)}, p=.21 -> '
      '"${significanceStars(0.21)}"');
}

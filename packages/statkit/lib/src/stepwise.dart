/// 逐步回归：前进 / 后退 / 双向（v0.4）
library;

import 'dart:math' as math;

import 'distributions.dart';
import 'regression.dart';

enum StepwiseMethod { forward, backward, both }

class StepwiseStep {
  final String action; // 'enter' | 'remove'
  final String variable;
  final double r2;
  final double adjR2;
  final double f;
  final double p;
  final List<String> inModel;
  const StepwiseStep({
    required this.action,
    required this.variable,
    required this.r2,
    required this.adjR2,
    required this.f,
    required this.p,
    required this.inModel,
  });
}

class StepwiseResult {
  final List<String> selected;
  final List<StepwiseStep> steps;
  final RegressionResult? model;
  final double r2;
  final double adjR2;
  const StepwiseResult({
    required this.selected,
    required this.steps,
    required this.model,
    required this.r2,
    required this.adjR2,
  });
}

StepwiseResult stepwiseRegression(
  List<List<double>> xs,
  List<double> y, {
  required List<String> names,
  StepwiseMethod method = StepwiseMethod.both,
  double enterP = 0.05,
  double removeP = 0.10,
}) {
  final p = xs.length;
  final inModel = <int>[];
  final steps = <StepwiseStep>[];

  RegressionResult? fitModel() {
    if (inModel.isEmpty) return null;
    try {
      return Regression.multiple(
        [for (final i in inModel) xs[i]],
        y,
        predictorNames: [for (final i in inModel) names[i]],
      );
    } catch (_) {
      return null;
    }
  }

  bool tryEnter() {
    int? best;
    double bestGain = 0;
    RegressionResult? bestModel;
    final base = fitModel();
    for (var j = 0; j < p; j++) {
      if (inModel.contains(j)) continue;
      final cand = [...inModel, j];
      RegressionResult? nm;
      try {
        nm = Regression.multiple(
          [for (final i in cand) xs[i]],
          y,
          predictorNames: [for (final i in cand) names[i]],
        );
      } catch (_) {
        continue;
      }
      final gain = nm.r2 - (base?.r2 ?? 0);
      final df2 = nm.dfResidual;
      final double pInc;
      if (gain <= 0) {
        pInc = 1.0;
      } else if (nm.msResidual <= 1e-12 || nm.msResidual.isNaN) {
        pInc = 0.0; // perfect / near-perfect fit
      } else {
        final fInc = (gain * nm.ssTotal / 1) / nm.msResidual;
        pInc = df2 > 0 ? fSf(fInc, 1, df2) : 1.0;
      }
      if (pInc <= enterP && gain > bestGain) {
        bestGain = gain;
        best = j;
        bestModel = nm;
      }
    }
    if (best == null || bestModel == null) return false;
    inModel.add(best);
    steps.add(StepwiseStep(
      action: 'enter',
      variable: names[best],
      r2: bestModel.r2,
      adjR2: bestModel.adjR2,
      f: bestModel.f,
      p: bestModel.pF,
      inModel: [for (final i in inModel) names[i]],
    ));
    return true;
  }

  bool tryRemove() {
    if (inModel.length <= 1) return false;
    int? worst;
    double worstP = -1;
    final full = fitModel();
    if (full == null) return false;
    for (final j in List.of(inModel)) {
      final cand = [for (final i in inModel)
        if (i != j) i];
      if (cand.isEmpty) continue;
      RegressionResult? nm;
      try {
        nm = Regression.multiple(
          [for (final i in cand) xs[i]],
          y,
          predictorNames: [for (final i in cand) names[i]],
        );
      } catch (_) {
        continue;
      }
      final df2 = full.dfResidual;
      final fRem = (df2 > 0 && full.msResidual > 0)
          ? math.max(0, (full.r2 - nm.r2) * full.ssTotal / 1) / full.msResidual
          : 0.0;
      final pRem = df2 > 0 ? fSf(fRem, 1, df2) : 1.0;
      if (pRem > worstP) {
        worstP = pRem;
        worst = j;
      }
    }
    if (worst == null) return false;
    if (worstP > removeP) {
      inModel.remove(worst);
      final m = fitModel();
      steps.add(StepwiseStep(
        action: 'remove',
        variable: names[worst],
        r2: m?.r2 ?? 0,
        adjR2: m?.adjR2 ?? 0,
        f: m?.f ?? 0,
        p: m?.pF ?? 1,
        inModel: [for (final i in inModel) names[i]],
      ));
      return true;
    }
    return false;
  }

  if (method == StepwiseMethod.backward) {
    inModel.addAll(List.generate(p, (i) => i));
    while (tryRemove()) {}
  } else if (method == StepwiseMethod.forward) {
    while (tryEnter()) {}
  } else {
    var changed = true;
    while (changed) {
      changed = tryEnter() || tryRemove();
    }
  }

  final model = fitModel();
  return StepwiseResult(
    selected: [for (final i in inModel) names[i]],
    steps: steps,
    model: model,
    r2: model?.r2 ?? 0,
    adjR2: model?.adjR2 ?? 0,
  );
}

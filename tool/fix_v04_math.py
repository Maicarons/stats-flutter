from pathlib import Path

# Fix stepwise p-value for perfect fit
p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\stepwise.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    """      final gain = nm.r2 - (base?.r2 ?? 0);
      final df2 = nm.dfResidual;
      final fInc = (df2 > 0 && nm.msResidual > 0 && gain > 0)
          ? (gain * nm.ssTotal / 1) / nm.msResidual
          : 0.0;
      final pInc = df2 > 0 ? fSf(fInc, 1, df2) : 1.0;
      if (pInc <= enterP && gain > bestGain) {""",
    """      final gain = nm.r2 - (base?.r2 ?? 0);
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
      if (pInc <= enterP && gain > bestGain) {""",
)
p.write_text(t, encoding="utf-8")
print("stepwise")

# Fix logistic IRLS with ridge + separation guard
p = Path(r"F:\workspace\stats-flutter\packages\statkit\lib\src\logistic_full.dart")
t = p.read_text(encoding="utf-8")
t = t.replace(
    "        for (var b = 0; b <= p; b++) {\n          XtWX[a][b] += w * Z[i][a] * Z[i][b];\n        }",
    "        for (var b = 0; b <= p; b++) {\n          XtWX[a][b] += w * Z[i][a] * Z[i][b];\n        }\n        // ridge for separation",
)
# add ridge before solve
t = t.replace(
    "    final newBeta = _solve(XtWX, XtWz);",
    """    for (var d = 0; d <= p; d++) {
      XtWX[d][d] += 1e-6;
    }
    final newBeta = _solve(XtWX, XtWz);
    var diverged = false;
    for (final v in newBeta) {
      if (!v.isFinite || v.abs() > 20) diverged = true;
    }
    if (diverged) {
      // keep previous and stop
      break;
    }""",
)
p.write_text(t, encoding="utf-8")
print("logistic ridge")

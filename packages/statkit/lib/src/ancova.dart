/// 协方差分析（ANCOVA）：y ~ A [* B] + 连续协变量，类型 III 平方和
///
/// 类型 III 的判据用「模型比较」定义：某项的 SS = 去掉该项后（保留其余所有项）
/// 的残差平方和 − 完整模型的残差平方和。这与 SAS 的 Type III 一致，不受
/// 各格样本数不等的影响，也不需要依赖具体的编码方式（因子用效应编码）。
library;

import 'dart:math' as math;


import 'distributions.dart';

/// 方差分析表的一行（因子项或协变量项）
class AnovaTerm {
  /// 项名：因子名、`A×B` 交互，或协变量名
  final String name;

  /// 类型 III 平方和（去掉该项、保留其余所有项后的残差平方和增量）
  final double ss;

  /// 该项的自由度（因子为水平数 − 1，协变量为 1）
  final int df;

  /// 均方 = ss / df
  final double ms;

  /// F 值 = ms / msError
  final double f;

  /// F 检验的 p 值
  final double p;

  /// 偏 η² = ss / (ss + ssError)
  final double partialEta2;

  /// true 表示这一行是协变量（单项 df = 1）
  final bool isCovariate;

  /// 构造方差分析表的一行（通常由 [ancova] 生成）
  const AnovaTerm({
    required this.name,
    required this.ss,
    required this.df,
    required this.ms,
    required this.f,
    required this.p,
    required this.partialEta2,
    required this.isCovariate,
  });
}

/// 协变量斜率（原始尺度，未标准化：每增加 1 个单位因变量的变化）
class AncovaSlope {
  /// 协变量名
  final String name;

  /// 斜率（原始尺度：协变量每增加 1 个单位，因变量的变化）
  final double b;

  /// 斜率的标准误
  final double se;

  /// 斜率显著性的 t 值
  final double t;

  /// t 检验的 p 值
  final double p;

  /// 斜率的 95% 置信区间下界
  final double ciLower95;

  /// 斜率的 95% 置信区间上界
  final double ciUpper95;

  /// 构造一条协变量斜率（通常由 [ancova] 生成）
  const AncovaSlope({
    required this.name,
    required this.b,
    required this.se,
    required this.t,
    required this.p,
    required this.ciLower95,
    required this.ciUpper95,
  });
}

/// 调整均值（EMM）。协变量以相加形式进入模型，因此 EMM 等于
/// 「把协变量固定在各自均值、因子固定在该水平」时的模型预测值；
/// 边缘均值对另一个因子的各水平等权平均。
class AncovaMean {
  /// 'A' / 'B' / 'A×B'
  final String factor;

  /// 水平标签（A×B 时为 'a × b'）
  final String level;

  /// 调整后均值（控制了协变量）
  final double adjusted;

  /// 未调整均值（同组原始均值，用于对照看出「剥离」了多少）
  final double raw;

  /// 调整均值的标准误
  final double se;

  /// 调整均值的 95% 置信区间下界
  final double ciLower95;

  /// 调整均值的 95% 置信区间上界
  final double ciUpper95;

  /// 该格 / 该水平的样本数
  final int n;

  /// 构造一条调整均值（通常由 [ancova] 生成）
  const AncovaMean({
    required this.factor,
    required this.level,
    required this.adjusted,
    required this.raw,
    required this.se,
    required this.ciLower95,
    required this.ciUpper95,
    required this.n,
  });
}

/// 协方差分析结果
class AncovaResult {
  /// 因子项（A、可选 B、可选 A×B）+ 每个协变量一项
  final List<AnovaTerm> terms;

  /// 误差平方和（残差平方和）
  final double ssError;

  /// 误差自由度 = n − 参数个数（含截距）
  final int dfError;

  /// 误差均方 = ssError / dfError
  final double msError;

  /// 校正总平方和 Σ(y − ȳ)²
  final double ssTotal;

  /// 校正模型平方和 = ssTotal − ssError
  final double ssModel;

  /// 模型 R² = ssModel / ssTotal
  final double r2;

  /// 调整 R²（按参数个数校正）
  final double adjR2;

  /// 残差标准误 √msError
  final double rmse;

  /// 进入模型的观测数
  final int n;

  /// 参数个数（含截距），dfError = n − 参数个数
  final int nParams;

  /// 因变量名
  final String yName;

  /// 因子名（只有 A 时一项，A 与 B 时两项）
  final List<String> factorNames;

  /// 协变量名
  final List<String> covariateNames;

  /// 协变量斜率（与 terms 里的协变量项一一对应）
  final List<AncovaSlope> slopes;

  /// 调整均值：先各因子边缘，再（两因子时）A×B 单元
  final List<AncovaMean> means;

  /// 各协变量的均值（EMM 就是在这一点上求值的）
  final Map<String, double> covariateMeans;

  /// 构造协方差分析结果（通常由 [ancova] 生成）
  const AncovaResult({
    required this.terms,
    required this.ssError,
    required this.dfError,
    required this.msError,
    required this.ssTotal,
    required this.ssModel,
    required this.r2,
    required this.adjR2,
    required this.rmse,
    required this.n,
    required this.nParams,
    required this.yName,
    required this.factorNames,
    required this.covariateNames,
    required this.slopes,
    required this.means,
    required this.covariateMeans,
  });
}

class _OlsFit {
  final List<double> beta;
  final double sse;
  final List<List<double>> inv; // (X'X)⁻¹（做了极小岭以保证可逆）
  const _OlsFit(this.beta, this.sse, this.inv);
}

/// 普通最小二乘：[cols] 是列优先的自变量（cols[j] 为第 j 列 n 个观测）
_OlsFit _ols(List<List<double>> cols, List<double> y) {
  final p = cols.length;
  final n = y.length;
  final xtx = List.generate(p, (_) => List<double>.filled(p, 0.0));
  final xty = List<double>.filled(p, 0.0);
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < p; j++) {
      final xj = cols[j][i];
      xty[j] += xj * y[i];
      for (var k = j; k < p; k++) {
        xtx[j][k] += xj * cols[k][i];
      }
    }
  }
  for (var j = 0; j < p; j++) {
    for (var k = 0; k < j; k++) {
      xtx[j][k] = xtx[k][j];
    }
  }
  var trace = 0.0;
  for (var j = 0; j < p; j++) {
    trace += xtx[j][j];
  }
  // 岭只用于保证数值可逆，量级 1e-12；残差平方和仍按残差直接计算，
  // 因此对平方和与 F 的影响远小于任何报告精度（斜率/SE 的偏差 ~1e-10）。
  final ridge = 1e-12 * math.max(1.0, trace / math.max(1, p));
  for (var j = 0; j < p; j++) {
    xtx[j][j] += ridge;
  }
  final inv = _invert(xtx);
  final beta = List<double>.filled(p, 0.0);
  for (var j = 0; j < p; j++) {
    var s = 0.0;
    for (var k = 0; k < p; k++) {
      s += inv[j][k] * xty[k];
    }
    beta[j] = s;
  }
  var sse = 0.0;
  for (var i = 0; i < n; i++) {
    var pred = 0.0;
    for (var j = 0; j < p; j++) {
      pred += beta[j] * cols[j][i];
    }
    sse += (y[i] - pred) * (y[i] - pred);
  }
  return _OlsFit(beta, sse, inv);
}

/// 高斯–约当求逆（列主元）
List<List<double>> _invert(List<List<double>> a) {
  final n = a.length;
  final m = List.generate(n, (i) => [...a[i], ...List<double>.generate(n, (j) => i == j ? 1.0 : 0.0)]);
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
    }
    final tmp = m[col];
    m[col] = m[pivot];
    m[pivot] = tmp;
    final div = m[col][col];
    if (div.abs() < 1e-300) continue;
    for (var c = 0; c < 2 * n; c++) {
      m[col][c] /= div;
    }
    for (var r = 0; r < n; r++) {
      if (r == col) continue;
      final factor = m[r][col];
      if (factor == 0) continue;
      for (var c = 0; c < 2 * n; c++) {
        m[r][c] -= factor * m[col][c];
      }
    }
  }
  return List.generate(n, (i) => List.generate(n, (j) => m[i][n + j]));
}

/// 协方差分析：y ~ A [* B] + 连续协变量
///
/// [y] / [a] / [b] / [covariates] 都是逐观测的，长度必须一致（n）。
/// [a] 的每个水平至少 2 个观测、[b] 提供时要求 A×B 是完整的交叉设计
/// （否则交互项不可估计，会抛 ArgumentError）。
AncovaResult ancova({
  required List<double> y,
  required List<String> a,
  List<String>? b,
  Map<String, List<double>> covariates = const {},
  String yName = 'Y',
  String aName = 'A',
  String bName = 'B',
}) {
  final n = y.length;
  if (n == 0) throw ArgumentError('数据为空');
  if (a.length != n) throw ArgumentError('因子 $aName 与因变量长度不一致');
  if (b != null && b.length != n) {
    throw ArgumentError('因子 $bName 与因变量长度不一致');
  }
  for (final e in covariates.entries) {
    if (e.value.length != n) {
      throw ArgumentError('协变量 ${e.key} 与因变量长度不一致');
    }
  }
  final aLevels = a.toSet().toList()..sort();
  if (aLevels.length < 2) throw ArgumentError('因子 $aName 至少需要两个水平');
  final hasB = b != null;
  final bLevels = hasB ? (b.toSet().toList()..sort()) : <String>[];
  if (hasB && bLevels.length < 2) {
    throw ArgumentError('因子 $bName 至少需要两个水平');
  }
  final covNames = covariates.keys.toList();

  // 效应编码块（sum-to-zero，k−1 列）
  List<List<double>> effectBlock(List<String> levels, List<String> values) {
    final m = levels.length - 1;
    final rows = List.generate(n, (_) => List<double>.filled(m, 0.0));
    for (var i = 0; i < n; i++) {
      final idx = levels.indexOf(values[i]);
      if (idx < m) {
        rows[i][idx] = 1;
      } else {
        for (var j = 0; j < m; j++) {
          rows[i][j] = -1;
        }
      }
    }
    return List.generate(m, (j) => [for (var i = 0; i < n; i++) rows[i][j]]);
  }

  final aBlock = effectBlock(aLevels, a);
  final bBlock = hasB ? effectBlock(bLevels, b) : <List<double>>[];
  final abBlock = <List<double>>[];
  if (hasB) {
    for (final ca in aBlock) {
      for (final cb in bBlock) {
        abBlock.add([for (var i = 0; i < n; i++) ca[i] * cb[i]]);
      }
    }
  }
  if (hasB) {
    // 每个 A×B 单元都要有观测（否则交互项不可估计）
    for (final av in aLevels) {
      for (final bv in bLevels) {
        var cnt = 0;
        for (var i = 0; i < n; i++) {
          if (a[i] == av && b[i] == bv) cnt++;
        }
        if (cnt == 0) {
          throw ArgumentError('A×B 单元 ($av, $bv) 没有观测，交互项不可估计');
        }
      }
    }
  }

  // 项 → 列（顺序与报告一致）
  final termNames = <String>[
    aName,
    if (hasB) bName,
    if (hasB) '$aName×$bName',
    ...covNames,
  ];
  final termIsCov = <bool>[
    false,
    if (hasB) false,
    if (hasB) false,
    ...List<bool>.filled(covNames.length, true),
  ];
  final termCols = <List<List<double>>>[
    aBlock,
    if (hasB) bBlock,
    if (hasB) abBlock,
    for (final name in covNames) [covariates[name]!],
  ];

  final ones = List<double>.filled(n, 1.0);
  final allCols = <List<double>>[ones];
  final allOwner = <int>[-1];
  final termStart = <int>[];
  for (var t = 0; t < termCols.length; t++) {
    termStart.add(allCols.length);
    for (final col in termCols[t]) {
      allCols.add(col);
      allOwner.add(t);
    }
  }
  final full = _ols(allCols, y);
  final nParams = allCols.length;
  final dfError = n - nParams;
  final msError = dfError > 0 ? full.sse / dfError : double.nan;

  final grand = y.reduce((p, q) => p + q) / n;
  final ssTotal = y.fold<double>(0, (s, v) => s + (v - grand) * (v - grand));

  final terms = <AnovaTerm>[];
  for (var t = 0; t < termCols.length; t++) {
    final reduced = <List<double>>[];
    for (var c = 0; c < allCols.length; c++) {
      if (allOwner[c] != t) reduced.add(allCols[c]);
    }
    final sseReduced = _ols(reduced, y).sse;
    final ss = math.max(0.0, sseReduced - full.sse);
    final df = termCols[t].length;
    final ms = ss / df;
    final f = (msError > 0 && msError.isFinite) ? ms / msError : double.nan;
    terms.add(AnovaTerm(
      name: termNames[t],
      ss: ss,
      df: df,
      ms: ms,
      f: f,
      p: dfError > 0 ? fSf(f, df, dfError) : double.nan,
      partialEta2: (ss + full.sse) > 0 ? ss / (ss + full.sse) : double.nan,
      isCovariate: termIsCov[t],
    ));
  }

  // 协变量斜率（原始尺度）
  final covMeans = <String, double>{
    for (final name in covNames)
      name: covariates[name]!.reduce((p, q) => p + q) / n,
  };
  final slopes = <AncovaSlope>[];
  for (var ci = 0; ci < covNames.length; ci++) {
    final ti = termNames.indexOf(covNames[ci]);
    final idx = termStart[ti];
    final b = full.beta[idx];
    final se = math.sqrt(math.max(0, msError * full.inv[idx][idx]));
    final t = se > 0 ? b / se : double.nan;
    final half = tCritical(math.max(1, dfError), 0.05) * se;
    slopes.add(AncovaSlope(
      name: covNames[ci],
      b: b,
      se: se,
      t: t,
      p: tTwoTail(t, math.max(1, dfError)),
      ciLower95: b - half,
      ciUpper95: b + half,
    ));
  }

  // 设计行（与 allCols 的顺序一致）
  List<double> designRow(int ai, int bj) {
    final row = <double>[1.0];
    for (var j = 0; j < aLevels.length - 1; j++) {
      row.add(ai < aLevels.length - 1 ? (ai == j ? 1.0 : 0.0) : -1.0);
    }
    if (hasB) {
      for (var j = 0; j < bLevels.length - 1; j++) {
        row.add(bj < bLevels.length - 1 ? (bj == j ? 1.0 : 0.0) : -1.0);
      }
      for (var ia = 0; ia < aLevels.length - 1; ia++) {
        for (var ib = 0; ib < bLevels.length - 1; ib++) {
          final va = ai < aLevels.length - 1 ? (ai == ia ? 1.0 : 0.0) : -1.0;
          final vb = bj < bLevels.length - 1 ? (bj == ib ? 1.0 : 0.0) : -1.0;
          row.add(va * vb);
        }
      }
    }
    for (final name in covNames) {
      row.add(covMeans[name]!);
    }
    return row;
  }

  double predAt(List<double> row) {
    var s = 0.0;
    for (var j = 0; j < row.length; j++) {
      s += full.beta[j] * row[j];
    }
    return s;
  }

  double seAt(List<double> row) {
    var v = 0.0;
    for (var a2 = 0; a2 < row.length; a2++) {
      for (var b2 = 0; b2 < row.length; b2++) {
        v += row[a2] * full.inv[a2][b2] * row[b2];
      }
    }
    return math.sqrt(math.max(0, msError * v));
  }

  final halfT = tCritical(math.max(1, dfError), 0.05);
  double rawMeanOf(List<double> vals) =>
      vals.isEmpty ? double.nan : vals.reduce((p, q) => p + q) / vals.length;

  final aRaw = <String, List<double>>{for (final l in aLevels) l: <double>[]};
  final bRaw = <String, List<double>>{for (final l in bLevels) l: <double>[]};
  final cellRaw = <(String, String), List<double>>{};
  for (var i = 0; i < n; i++) {
    aRaw[a[i]]!.add(y[i]);
    if (hasB) {
      bRaw[b[i]]!.add(y[i]);
      cellRaw.putIfAbsent((a[i], b[i]), () => <double>[]).add(y[i]);
    }
  }

  final means = <AncovaMean>[];
  // 因子 A 的边缘调整均值：对 B 的各水平等权平均
  final cellRows = <List<List<double>>>[];
  for (var ia = 0; ia < aLevels.length; ia++) {
    cellRows.add(<List<double>>[]);
    for (var ib = 0; ib < (hasB ? bLevels.length : 1); ib++) {
      cellRows[ia].add(designRow(ia, ib));
    }
  }
  List<double> avgRow(List<List<double>> rows) {
    final out = List<double>.filled(rows.first.length, 0.0);
    for (final r in rows) {
      for (var j = 0; j < r.length; j++) {
        out[j] += r[j] / rows.length;
      }
    }
    return out;
  }

  for (var ia = 0; ia < aLevels.length; ia++) {
    final row = avgRow(cellRows[ia]);
    final adj = predAt(row);
    final se = seAt(row);
    means.add(AncovaMean(
      factor: aName,
      level: aLevels[ia],
      adjusted: adj,
      raw: rawMeanOf(aRaw[aLevels[ia]]!),
      se: se,
      ciLower95: adj - halfT * se,
      ciUpper95: adj + halfT * se,
      n: aRaw[aLevels[ia]]!.length,
    ));
  }
  if (hasB) {
    for (var ib = 0; ib < bLevels.length; ib++) {
      final rows = [for (var ia = 0; ia < aLevels.length; ia++) cellRows[ia][ib]];
      final row = avgRow(rows);
      final adj = predAt(row);
      final se = seAt(row);
      means.add(AncovaMean(
        factor: bName,
        level: bLevels[ib],
        adjusted: adj,
        raw: rawMeanOf(bRaw[bLevels[ib]]!),
        se: se,
        ciLower95: adj - halfT * se,
        ciUpper95: adj + halfT * se,
        n: bRaw[bLevels[ib]]!.length,
      ));
    }
    // A×B 单元调整均值
    for (var ia = 0; ia < aLevels.length; ia++) {
      for (var ib = 0; ib < bLevels.length; ib++) {
        final row = cellRows[ia][ib];
        final adj = predAt(row);
        final se = seAt(row);
        final vals = cellRaw[(aLevels[ia], bLevels[ib])] ?? const <double>[];
        means.add(AncovaMean(
          factor: '$aName×$bName',
          level: '${aLevels[ia]} × ${bLevels[ib]}',
          adjusted: adj,
          raw: rawMeanOf(vals),
          se: se,
          ciLower95: adj - halfT * se,
          ciUpper95: adj + halfT * se,
          n: vals.length,
        ));
      }
    }
  }

  final ssModel = ssTotal - full.sse;
  final adjR2 = dfError > 0 && ssTotal > 0
      ? 1 - (full.sse / dfError) / (ssTotal / (n - 1))
      : double.nan;

  return AncovaResult(
    terms: terms,
    ssError: full.sse,
    dfError: dfError,
    msError: msError,
    ssTotal: ssTotal,
    ssModel: ssModel,
    r2: ssTotal > 0 ? ssModel / ssTotal : double.nan,
    adjR2: adjR2,
    rmse: math.sqrt(math.max(0, msError)),
    n: n,
    nParams: nParams,
    yName: yName,
    factorNames: [aName, if (hasB) bName],
    covariateNames: covNames,
    slopes: slopes,
    means: means,
    covariateMeans: covMeans,
  );
}

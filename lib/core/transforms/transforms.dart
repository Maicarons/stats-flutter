/// 数据变换：COMPUTE / RECODE / RANK / SORT / SELECT / WEIGHT / AGGREGATE
library;

import 'dart:math' as math;

import 'package:statkit/statkit.dart';

import '../models/dataset.dart';

// 应用是 statkit 的同仓第一消费者（statkit 0.5.0 ↔ app 1.4.0），
// 因此这里可以有意使用 statkit 标注为 @experimental 的入口。
// ignore_for_file: experimental_member_use

/// 表达式计算（支持 + - * / ( ) 与常用函数的轻量求值）
class ComputeEngine {
  static double? evaluate(String expr, Map<String, double> vars) {
    try {
      final tokens = _tokenize(expr.replaceAll(' ', ''));
      final r = _parseExpr(tokens, vars, 0);
      if (r.pos < tokens.length) return null;
      return r.value;
    } catch (_) {
      return null;
    }
  }

  static List<String> _tokenize(String s) {
    final out = <String>[];
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if ('+-*/()^'.contains(ch)) {
        out.add(ch);
        i++;
      } else if (RegExp(r'[0-9.]').hasMatch(ch)) {
        final start = i;
        while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
          i++;
        }
        out.add(s.substring(start, i));
      } else if (RegExp(r'[A-Za-z_]').hasMatch(ch)) {
        final start = i;
        while (i < s.length && RegExp(r'[A-Za-z0-9_]').hasMatch(s[i])) {
          i++;
        }
        out.add(s.substring(start, i));
      } else {
        i++;
      }
    }
    return out;
  }

  static _Val _parseExpr(List<String> t, Map<String, double> vars, int pos) {
    var cur = _parseTerm(t, vars, pos);
    while (cur.pos < t.length && (t[cur.pos] == '+' || t[cur.pos] == '-')) {
      final op = t[cur.pos];
      final next = _parseTerm(t, vars, cur.pos + 1);
      cur = _Val(
          op == '+' ? cur.value + next.value : cur.value - next.value, next.pos);
    }
    return cur;
  }

  static _Val _parseTerm(List<String> t, Map<String, double> vars, int pos) {
    var cur = _parseFactor(t, vars, pos);
    while (cur.pos < t.length && (t[cur.pos] == '*' || t[cur.pos] == '/')) {
      final op = t[cur.pos];
      final next = _parseFactor(t, vars, cur.pos + 1);
      cur = _Val(
          op == '*'
              ? cur.value * next.value
              : (next.value == 0 ? double.nan : cur.value / next.value),
          next.pos);
    }
    return cur;
  }

  static _Val _parseFactor(List<String> t, Map<String, double> vars, int pos) {
    if (pos >= t.length) throw const FormatException('unexpected end');
    final tok = t[pos];
    if (tok == '(') {
      final inner = _parseExpr(t, vars, pos + 1);
      if (inner.pos >= t.length || t[inner.pos] != ')') {
        throw const FormatException('missing )');
      }
      return _Val(inner.value, inner.pos + 1);
    }
    if (tok == '-') {
      final f = _parseFactor(t, vars, pos + 1);
      return _Val(-f.value, f.pos);
    }
    if (tok == '+') {
      return _parseFactor(t, vars, pos + 1);
    }
    final num = double.tryParse(tok);
    if (num != null) return _Val(num, pos + 1);

    if (pos + 1 < t.length && t[pos + 1] == '(') {
      final name = tok.toLowerCase();
      final arg = _parseExpr(t, vars, pos + 2);
      if (arg.pos >= t.length || t[arg.pos] != ')') {
        throw const FormatException('missing )');
      }
      final a = arg.value;
      final v = switch (name) {
        'abs' => a.abs(),
        'sqrt' => a < 0 ? double.nan : math.sqrt(a),
        'ln' || 'log' => a <= 0 ? double.nan : math.log(a),
        'log10' => a <= 0 ? double.nan : math.log(a) / math.ln10,
        'exp' => math.exp(a),
        'sin' => math.sin(a),
        'cos' => math.cos(a),
        'tan' => math.tan(a),
        'round' => a.roundToDouble(),
        'trunc' => a.truncateToDouble(),
        _ => double.nan,
      };
      return _Val(v, arg.pos + 1);
    }
    final v = vars[tok] ?? vars[tok.toLowerCase()] ?? double.nan;
    return _Val(v, pos + 1);
  }
}

class _Val {
  final double value;
  final int pos;
  const _Val(this.value, this.pos);
}

/// AUTORECODE 的编码表条目
class _ArcItem {
  final Object value;
  final bool missing;
  final String label;

  /// 目标码（1..k），建表排序后回填
  double code = 0;

  _ArcItem({required this.value, required this.missing, required this.label});
}

/// RANK 的输出函数（对应 PSPP `RANK` 的 /RANK /N /RFRACTION /PROPORTION
/// /PERCENT /NORMAL /NTILES）。
enum RankFunction {
  /// 秩（默认，结取平均）
  rank,

  /// 有效个案数（同一常数）
  n,

  /// 秩 / N（0–1）
  rFraction,

  /// Blom 分数的正态得分
  normal,

  /// 秩的比例分数（Blom）
  proportion,

  /// 百分位秩（0–100）
  percent,

  /// n 分位组编号（1..n）
  ntiles,
}

/// 结的处理（PSPP `RANK` 的 /TIES）。
enum RankTies {
  /// 结取平均秩（默认）
  mean,

  /// 结取最小值
  low,

  /// 结取最大值
  high,

  /// 结压缩为同一编号（首个结的位置）
  condense,
}

/// 变换结果
class TransformResult {
  final String message;
  final Dataset dataset;
  final int changed;
  const TransformResult({
    required this.message,
    required this.dataset,
    required this.changed,
  });
}

class Transforms {
  /// COMPUTE：对每个个案计算表达式写入目标变量
  static TransformResult compute(
    Dataset ds, {
    required String targetVar,
    required String expression,
  }) {
    var ti = ds.indexOf(targetVar);
    if (ti < 0) {
      ds.addVariable(Variable(name: targetVar));
      ti = ds.nVars - 1;
    }
    var changed = 0;
    for (final row in ds.cases) {
      final vars = <String, double>{};
      for (var i = 0; i < ds.nVars && i < row.length; i++) {
        final raw = row[i];
        if (raw is num) vars[ds.variables[i].name] = raw.toDouble();
      }
      final val = ComputeEngine.evaluate(expression, vars);
      while (row.length <= ti) {
        row.add(null);
      }
      row[ti] = val;
      if (val != null && val.isFinite) changed++;
    }
    return TransformResult(
      message: 'COMPUTE $targetVar = $expression -> $changed / ${ds.nCases}',
      dataset: ds,
      changed: changed,
    );
  }

  /// RECODE
  static TransformResult recode(
    Dataset ds, {
    required String sourceVar,
    required String targetVar,
    required Map<String, String> rules,
  }) {
    final si = ds.indexOf(sourceVar);
    if (si < 0) throw ArgumentError('source variable not found');
    var ti = ds.indexOf(targetVar);
    if (ti < 0) {
      ds.addVariable(Variable(name: targetVar, type: ds.variables[si].type));
      ti = ds.nVars - 1;
    }
    final map = <Object, Object?>{};
    for (final e in rules.entries) {
      final oldV = double.tryParse(e.key) ?? e.key;
      final newV = double.tryParse(e.value) ?? e.value;
      map[oldV] = newV;
    }
    var changed = 0;
    for (final row in ds.cases) {
      final raw = si < row.length ? row[si] : null;
      while (row.length <= ti) {
        row.add(null);
      }
      if (raw != null && map.containsKey(raw)) {
        row[ti] = map[raw];
        changed++;
      } else {
        row[ti] = raw;
      }
    }
    return TransformResult(
      message:
          'RECODE $sourceVar -> $targetVar (${map.length} rules, $changed hit)',
      dataset: ds,
      changed: changed,
    );
  }

  /// AUTORECODE：把取值编码为 1..k 的数值码，并自动加值标签。
  ///
  /// 语义对齐 PSPP 2.1.2（`src/language/commands/autorecode.c`）：
  /// - 逐个源变量建表，只收录非缺失取值；空值 / 空白仍译为系统缺失；
  /// - 用户缺失值也参与编码，但**恒排在其后**（取最大若干码，与升 / 降序无关），
  ///   并在目标变量上标为缺失（超过 3 个时改用缺失范围）；
  /// - 其余取值按升序编号 1..k，[descending] 时改为降序；
  /// - [group] 时所有源变量共用一张表（要求类型一致，缺失规则取第一个有
  ///   用户缺失值的变量）；
  /// - 目标变量为整数（decimals 0）、名义尺度，沿用源变量的变量标签，
  ///   值标签取「源取值自身已有的值标签，其次取值的显示文本」。
  ///
  /// 目标变量名默认 `源名_n`，可用 [targetVars] 指定；源变量为空、目标名数量
  /// 不匹配或源变量不存在时报错。
  static TransformResult autorecode(
    Dataset ds, {
    required List<String> sourceVars,
    List<String>? targetVars,
    bool descending = false,
    bool group = false,
    bool blankValid = false,
  }) {
    if (sourceVars.isEmpty) throw ArgumentError('no source variables');
    if (targetVars != null && targetVars.length != sourceVars.length) {
      throw ArgumentError('source count (${sourceVars.length}) does not match '
          'target count (${targetVars.length})');
    }
    final srcs = <int>[];
    for (final n in sourceVars) {
      final i = ds.indexOf(n);
      if (i < 0) throw ArgumentError('variable not found: $n');
      srcs.add(i);
    }
    final names = <String>[
      for (var i = 0; i < srcs.length; i++)
        targetVars?[i] ?? '${ds.variables[srcs[i]].name}_n',
    ];
    if (group) {
      final t = ds.variables[srcs.first].type;
      for (final i in srcs) {
        if (ds.variables[i].type != t) {
          throw ArgumentError('GROUP requires variables of the same type');
        }
      }
    }
    // 建表：GROUP 时全部源变量共用第一张
    final tables = <List<_ArcItem>>[];
    if (group) {
      final mvIdx = srcs.firstWhere(
        (i) =>
            ds.variables[i].missingValues.isNotEmpty ||
            ds.variables[i].missingRangeLow != null,
        orElse: () => srcs.first,
      );
      final shared = _arcTable(ds, srcs, descending, blankValid, mvIdx);
      for (var i = 0; i < srcs.length; i++) {
        tables.add(shared);
      }
    } else {
      for (final i in srcs) {
        tables.add(_arcTable(ds, [i], descending, blankValid, i));
      }
    }
    // 先算好每列结果再统一写入：即使目标名与源名相同也不会读到自己写的码
    final outs = <List<double?>>[];
    for (var i = 0; i < srcs.length; i++) {
      final si = srcs[i];
      final lookup = <String, double>{
        for (final it in tables[i]) _arcKey(it.value): it.code,
      };
      final col = <double?>[];
      for (final row in ds.cases) {
        final raw = si < row.length ? row[si] : null;
        col.add(_arcSkip(raw, blankValid) ? null : lookup[_arcKey(raw!)]);
      }
      outs.add(col);
    }
    var changed = 0;
    final lines = <String>[
      'AUTORECODE ${sourceVars.join(" ")} -> ${names.join(" ")}'
          '${descending ? " DESCENDING" : ""}',
    ];
    for (var i = 0; i < srcs.length; i++) {
      final si = srcs[i];
      var ti = ds.indexOf(names[i]);
      if (ti < 0) {
        ds.addVariable(Variable(name: names[i]));
        ti = ds.nVars - 1;
      }
      final src = ds.variables[si];
      final dst = ds.variables[ti];
      dst
        ..type = VarType.numeric
        ..decimals = 0
        ..measure = MeasureLevel.nominal
        ..label = src.label
        ..valueLabels = <num, String>{
          for (final it in tables[i])
            if (it.label.isNotEmpty) it.code: it.label,
        }
        ..missingValues = <num>[]
        ..missingRangeLow = null
        ..missingRangeHigh = null;
      // 用户缺失值对应最大的若干码：> 3 个时用缺失范围（PSPP 的做法）
      final missingCodes = [
        for (final it in tables[i])
          if (it.missing) it.code,
      ];
      if (missingCodes.length > 3) {
        dst.missingRangeLow = missingCodes.first;
        dst.missingRangeHigh = missingCodes.last;
      } else {
        dst.missingValues = missingCodes;
      }
      for (var r = 0; r < ds.nCases; r++) {
        final row = ds.cases[r];
        while (row.length <= ti) {
          row.add(null);
        }
        row[ti] = outs[i][r];
        if (outs[i][r] != null) changed++;
      }
      lines.add(
          '  ${sourceVars[i]} -> ${names[i]} (${tables[i].length} codes)');
      for (final it in tables[i]) {
        final text = _arcText(it.value);
        lines.add('    $text -> ${it.code.toInt()}'
            '${it.missing ? " [user-missing]" : ""}'
            '${it.label.isNotEmpty && it.label != text ? " ($it.label)" : ""}');
      }
    }
    return TransformResult(
      message: lines.join('\n'),
      dataset: ds,
      changed: changed,
    );
  }

  /// 建立 AUTORECODE 的编码表：收录非缺失取值，按 [descending] 排序后编号，
  /// 用户缺失值恒排最后。[mvIdx] 决定缺失规则取自哪个源变量。
  static List<_ArcItem> _arcTable(
    Dataset ds,
    List<int> srcs,
    bool descending,
    bool blankValid,
    int mvIdx,
  ) {
    final mvVar = ds.variables[mvIdx];
    final seen = <String, _ArcItem>{};
    for (final si in srcs) {
      final v = ds.variables[si];
      for (final row in ds.cases) {
        final raw = si < row.length ? row[si] : null;
        if (_arcSkip(raw, blankValid)) continue;
        final key = _arcKey(raw!);
        if (seen.containsKey(key)) continue;
        seen[key] = _ArcItem(
          value: raw,
          missing: v.isMissing(raw) || mvVar.isMissing(raw),
          label: v.displayValue(raw),
        );
      }
    }
    final items = seen.values.toList()
      ..sort((a, b) {
        if (a.missing != b.missing) return a.missing ? 1 : -1;
        final cmp = _compareVal(a.value, b.value);
        return descending ? -cmp : cmp;
      });
    for (var i = 0; i < items.length; i++) {
      items[i].code = i + 1.0;
    }
    return items;
  }

  /// 不进入编码表的值：系统缺失（空值 / NaN）与（默认的）空字符串。
  static bool _arcSkip(Object? raw, bool blankValid) {
    if (raw == null) return true;
    if (raw is num) return raw.isNaN;
    if (raw is String) return raw.trim().isEmpty && !blankValid;
    return false;
  }

  /// 编码表的键：数值与字符串分别成键，数值按 double 规范化（1 与 1.0 同键）。
  static String _arcKey(Object v) => v is num ? 'n:${v.toDouble()}' : 's:$v';

  /// 编码表里旧取值的显示文本。
  static String _arcText(Object v) => v is num
      ? (v == v.roundToDouble() ? v.toInt().toString() : '$v')
      : '$v';

  /// RANK：秩、N、百分位、正态得分或 n 分位组。
  ///
  /// 语义对齐 PSPP 2.1.2（`src/language/commands/rank.c`，未加权时 w = 有效个案数）：
  /// - 秩：`TIES=MEAN` → `cc_1 + (c + 1) / 2`（`c` 为结内个案数，`cc_1` 为结前累计）
  /// - 百分位：`r * 100 / w`
  /// - 比例 / 正态得分：Blom `(r - 3/8) / (w + 1/4)`，正态再取 Φ⁻¹；分数 ≤ 0 记为缺失
  /// - n 分位组：`floor(r * k / (w + 1)) + 1`
  ///
  /// 目标变量默认按函数取名（R_ / N_ / RF_ / PR_ / P_ / Z_ / NT_ 前缀），
  /// 传入 [targetVar] 可覆盖；缺失个案（含用户缺失值）结果为空。
  static TransformResult rank(
    Dataset ds, {
    required String sourceVar,
    String? targetVar,
    bool descending = false,
    RankFunction function = RankFunction.rank,
    RankTies ties = RankTies.mean,
    int ntiles = 4,
  }) {
    final si = ds.indexOf(sourceVar);
    if (si < 0) throw ArgumentError('variable not found');
    if (function == RankFunction.ntiles && ntiles < 1) {
      throw ArgumentError('ntiles must be >= 1');
    }
    final src = ds.variables[si];
    final name = targetVar ?? _rankName(function, sourceVar);
    var ti = ds.indexOf(name);
    if (ti < 0) {
      ds.addVariable(Variable(
        name: name,
        measure: MeasureLevel.ordinal,
        decimals: _rankDecimals(function),
      ));
      ti = ds.nVars - 1;
    }
    // 有效个案：按该变量自身的缺失规则排除
    final pairs = <(int, double)>[];
    for (var i = 0; i < ds.nCases; i++) {
      final row = ds.cases[i];
      final raw = si < row.length ? row[si] : null;
      if (raw is! num || src.isMissing(raw)) continue;
      pairs.add((i, raw.toDouble()));
    }
    pairs.sort((a, b) =>
        descending ? b.$2.compareTo(a.$2) : a.$2.compareTo(b.$2));
    final w = pairs.length.toDouble();
    final values = List<double?>.filled(ds.nCases, null);
    var k = 0;
    while (k < pairs.length) {
      var j = k;
      while (j + 1 < pairs.length && pairs[j + 1].$2 == pairs[k].$2) {
        j++;
      }
      final r = _rankOf(
        ties,
        c: (j - k + 1).toDouble(),
        cc: (j + 1).toDouble(),
        cc1: k.toDouble(),
        index: k + 1.0,
      );
      final v = _rankFunctionValue(function, r, w, ntiles);
      for (var t = k; t <= j; t++) {
        values[pairs[t].$1] = v;
      }
      k = j + 1;
    }
    var changed = 0;
    for (var i = 0; i < ds.nCases; i++) {
      final row = ds.cases[i];
      while (row.length <= ti) {
        row.add(null);
      }
      row[ti] = values[i];
      if (values[i] != null) changed++;
    }
    return TransformResult(
      message: 'RANK $sourceVar -> $name (${_rankLabel(function, ntiles)}, '
          '$changed cases)',
      dataset: ds,
      changed: changed,
    );
  }

  /// 秩（PSPP `rank_rank`）：未加权时分结内权重 `c >= 1` 恒成立。
  static double _rankOf(
    RankTies ties, {
    required double c,
    required double cc,
    required double cc1,
    required double index,
  }) {
    switch (ties) {
      case RankTies.low:
        return cc1 + 1;
      case RankTies.high:
        return cc;
      case RankTies.mean:
        return cc1 + (c + 1) / 2;
      case RankTies.condense:
        return index;
    }
  }

  /// 各输出函数取值；分数 ≤ 0（PSPP 的 SYSMIS 情形）返回 null。
  static double? _rankFunctionValue(
      RankFunction f, double r, double w, int ntiles) {
    switch (f) {
      case RankFunction.rank:
        return r;
      case RankFunction.n:
        return w;
      case RankFunction.rFraction:
        return r / w;
      case RankFunction.percent:
        return r * 100.0 / w;
      case RankFunction.proportion:
      case RankFunction.normal:
        final p = (r - 3.0 / 8.0) / (w + 0.25);
        if (p <= 0) return null;
        return f == RankFunction.proportion ? p : normalQuantile(p);
      case RankFunction.ntiles:
        return (r * ntiles / (w + 1)).floorToDouble() + 1;
    }
  }

  static String _rankName(RankFunction f, String src) => switch (f) {
        RankFunction.rank => 'R_$src',
        RankFunction.n => 'N_$src',
        RankFunction.rFraction => 'RF_$src',
        RankFunction.proportion => 'PR_$src',
        RankFunction.percent => 'P_$src',
        RankFunction.normal => 'Z_$src',
        RankFunction.ntiles => 'NT_$src',
      };

  static int _rankDecimals(RankFunction f) => switch (f) {
        RankFunction.n || RankFunction.ntiles => 0,
        _ => 3,
      };

  static String _rankLabel(RankFunction f, int ntiles) => switch (f) {
        RankFunction.rank => 'rank',
        RankFunction.n => 'n',
        RankFunction.rFraction => 'rfraction',
        RankFunction.proportion => 'proportion',
        RankFunction.percent => 'percent',
        RankFunction.normal => 'normal',
        RankFunction.ntiles => 'ntiles($ntiles)',
      };

  /// SORT CASES
  static TransformResult sortCases(
    Dataset ds, {
    required List<String> keys,
    bool descending = false,
  }) {
    final idxs = keys.map(ds.indexOf).where((i) => i >= 0).toList();
    if (idxs.isEmpty) throw ArgumentError('invalid sort keys');
    ds.cases.sort((a, b) {
      for (final i in idxs) {
        final av = i < a.length ? a[i] : null;
        final bv = i < b.length ? b[i] : null;
        final cmp = _compareVal(av, bv);
        if (cmp != 0) return descending ? -cmp : cmp;
      }
      return 0;
    });
    return TransformResult(
      message: 'SORT CASES by ${keys.join(", ")}'
          '${descending ? " DESC" : ""} - ${ds.nCases} cases',
      dataset: ds,
      changed: ds.nCases,
    );
  }

  /// SELECT IF
  static TransformResult selectIf(
    Dataset ds, {
    required String condition,
  }) {
    final before = ds.nCases;
    ds.cases.removeWhere((row) {
      final vars = <String, double>{};
      for (var i = 0; i < ds.nVars && i < row.length; i++) {
        final raw = row[i];
        if (raw is num) vars[ds.variables[i].name] = raw.toDouble();
      }
      return !_evalCondition(condition, vars);
    });
    final removed = before - ds.nCases;
    return TransformResult(
      message:
          'SELECT IF $condition - keep ${ds.nCases}, remove $removed',
      dataset: ds,
      changed: removed,
    );
  }

  /// SAMPLE：按比例或按 n FROM N 抽样，带种子便于复现。
  ///
  /// 语义对齐 PSPP 2.1.2（`src/language/commands/sample.c`）：
  /// - [fraction]（0–1 开区间）：逐个案以该概率保留（Bernoulli，不保证正好 p·N 个）；
  /// - [n] / [from]：在当前至多前 from 个个案里等概率地恰好留下 n 个，
  ///   逐个案的保留概率为 `(n - m) / (from - t)`（`m` / `t` 为已留 / 已过个案数），
  ///   当已留满 n 个之后的个案一律丢弃；序列算法保证第 from 个时正好留满 n 个。
  ///
  /// 两者互斥；随机数取自 `math.Random(seed)`（同一种子同一次数结果一致）。
  static TransformResult sample(
    Dataset ds, {
    double? fraction,
    int? n,
    int? from,
    int seed = 20261016,
  }) {
    final useFraction = fraction != null;
    if (useFraction) {
      if (fraction <= 0 || fraction >= 1) {
        throw ArgumentError('fraction must be in (0, 1)');
      }
    } else if (n == null || from == null || n < 1 || from < n + 1) {
      throw ArgumentError('requires n FROM N with 1 <= n < N');
    }
    final rng = math.Random(seed);
    final before = ds.nCases;
    var message = '';
    if (useFraction) {
      ds.cases.removeWhere((_) => rng.nextDouble() > fraction);
      message = 'SAMPLE ${_num(fraction)} (seed $seed) - '
          'keep ${ds.nCases}, remove ${before - ds.nCases}';
    } else {
      var m = 0, t = 0;
      ds.cases.retainWhere((_) {
        final keep = m < n! && (from! - t) * rng.nextDouble() < n - m;
        t++;
        if (keep) {
          m++;
        }
        return keep;
      });
      message = 'SAMPLE $n FROM $from (seed $seed) - '
          'keep ${ds.nCases}, remove ${before - ds.nCases}';
    }
    return TransformResult(
      message: message,
      dataset: ds,
      changed: before - ds.nCases,
    );
  }

  /// 紧凑数字文本（去尾零），用于提示信息。
  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : '$v';

  static bool _evalCondition(String cond, Map<String, double> vars) {
    final orParts = cond.split('||');
    for (final part in orParts) {
      final andParts = part.split('&&');
      var ok = true;
      for (final a in andParts) {
        if (!_evalSimple(a.trim(), vars)) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  static bool _evalSimple(String c, Map<String, double> vars) {
    const ops = ['>=', '<=', '!=', '==', '>', '<'];
    for (final op in ops) {
      final i = c.indexOf(op);
      if (i > 0) {
        final left = c.substring(0, i).trim();
        final right = c.substring(i + op.length).trim();
        final lv = double.tryParse(left) ?? vars[left] ?? double.nan;
        final rv = double.tryParse(right) ?? vars[right] ?? double.nan;
        return switch (op) {
          '>=' => lv >= rv,
          '<=' => lv <= rv,
          '!=' => lv != rv,
          '==' => lv == rv,
          '>' => lv > rv,
          '<' => lv < rv,
          _ => true,
        };
      }
    }
    final v = double.tryParse(c) ?? vars[c] ?? 0;
    return v != 0;
  }

  /// COUNT
  static TransformResult count(
    Dataset ds, {
    required String targetVar,
    required List<String> sourceVars,
    required String matchValue,
  }) {
    var ti = ds.indexOf(targetVar);
    if (ti < 0) {
      ds.addVariable(Variable(name: targetVar, decimals: 0));
      ti = ds.nVars - 1;
    }
    final match = double.tryParse(matchValue);
    for (final row in ds.cases) {
      var n = 0;
      for (final name in sourceVars) {
        final si = ds.indexOf(name);
        if (si < 0) continue;
        final raw = si < row.length ? row[si] : null;
        if (match != null && raw is num && raw == match) n++;
        if (match == null && raw?.toString() == matchValue) n++;
      }
      while (row.length <= ti) {
        row.add(null);
      }
      row[ti] = n.toDouble();
    }
    return TransformResult(
      message:
          'COUNT $targetVar (${sourceVars.length} vars, match=$matchValue)',
      dataset: ds,
      changed: ds.nCases,
    );
  }

  /// AGGREGATE mean
  static TransformResult aggregateMean(
    Dataset ds, {
    required String groupVar,
    required List<String> valueVars,
  }) {
    final gi = ds.indexOf(groupVar);
    if (gi < 0) throw ArgumentError('group variable not found');
    final groups = <Object?, List<List<Object?>>>{};
    for (final row in ds.cases) {
      final key = gi < row.length ? row[gi] : null;
      groups.putIfAbsent(key, () => []).add(row);
    }
    final out = Dataset(name: '${ds.name}_agg');
    out.addVariable(Variable(name: groupVar, measure: MeasureLevel.nominal));
    for (final v in valueVars) {
      out.addVariable(Variable(name: 'mean_$v'));
    }
    final valueIdxs = valueVars.map(ds.indexOf).toList();
    groups.forEach((key, rows) {
      final newRow = <Object?>[key];
      for (final vi in valueIdxs) {
        double sum = 0;
        var n = 0;
        for (final r in rows) {
          final raw = vi >= 0 && vi < r.length ? r[vi] : null;
          if (raw is num) {
            sum += raw.toDouble();
            n++;
          }
        }
        newRow.add(n == 0 ? null : sum / n);
      }
      out.addCase(newRow);
    });
    return TransformResult(
      message: 'AGGREGATE by $groupVar - ${out.nCases} groups',
      dataset: out,
      changed: out.nCases,
    );
  }

  /// FLIP
  static TransformResult flip(Dataset ds) {
    final out = Dataset(name: '${ds.name}_flip');
    out.addVariable(Variable(name: 'var', measure: MeasureLevel.nominal));
    for (var r = 0; r < ds.nCases; r++) {
      out.addVariable(Variable(name: 'c${r + 1}', decimals: 2));
    }
    for (var c = 0; c < ds.nVars; c++) {
      final row = <Object?>[ds.variables[c].name];
      for (var r = 0; r < ds.nCases; r++) {
        row.add(r < ds.cases[r].length ? ds.cases[r][c] : null);
      }
      out.addCase(row);
    }
    return TransformResult(
      message: 'FLIP - ${out.nCases} x ${out.nVars}',
      dataset: out,
      changed: out.nCases,
    );
  }

  static int _compareVal(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is num && b is num) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }
}

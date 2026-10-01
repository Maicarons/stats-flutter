/// 数据变换：COMPUTE / RECODE / RANK / SORT / SELECT / WEIGHT / AGGREGATE
library;

import 'dart:math' as math;

import '../models/dataset.dart';

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

  /// RANK
  static TransformResult rank(
    Dataset ds, {
    required String sourceVar,
    String? targetVar,
    bool descending = false,
  }) {
    final si = ds.indexOf(sourceVar);
    if (si < 0) throw ArgumentError('variable not found');
    final name = targetVar ?? 'R_$sourceVar';
    var ti = ds.indexOf(name);
    if (ti < 0) {
      ds.addVariable(Variable(name: name, measure: MeasureLevel.ordinal));
      ti = ds.nVars - 1;
    }
    final pairs = <(int, double)>[];
    for (var i = 0; i < ds.nCases; i++) {
      final raw = i < ds.cases[i].length ? ds.cases[i][si] : null;
      if (raw is num) pairs.add((i, raw.toDouble()));
    }
    pairs.sort((a, b) =>
        descending ? b.$2.compareTo(a.$2) : a.$2.compareTo(b.$2));
    final ranks = List.filled(ds.nCases, 0.0);
    var k = 0;
    while (k < pairs.length) {
      var j = k;
      while (j + 1 < pairs.length && pairs[j + 1].$2 == pairs[k].$2) {
        j++;
      }
      final avg = (k + j) / 2.0 + 1.0;
      for (var t = k; t <= j; t++) {
        ranks[pairs[t].$1] = avg;
      }
      k = j + 1;
    }
    for (var i = 0; i < ds.nCases; i++) {
      final row = ds.cases[i];
      while (row.length <= ti) {
        row.add(null);
      }
      row[ti] = ranks[i] == 0 ? null : ranks[i];
    }
    return TransformResult(
      message: 'RANK $sourceVar -> $name (${pairs.length} cases)',
      dataset: ds,
      changed: pairs.length,
    );
  }

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

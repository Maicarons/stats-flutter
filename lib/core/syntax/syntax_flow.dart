/// 语法程序流（v1.7.0 M2）：`DO IF / ELSE IF / ELSE / END IF`、
/// `LOOP / END LOOP / BREAK`、`VECTOR`。
///
/// 语义与 PSPP 对齐的部分：条件**逐案**求值（每个个案取第一个成立的
/// 分支）；`LOOP var = a TO b [BY step]` 与 `LOOP IF cond` 两种循环头；
/// `END LOOP [IF cond]`；循环计数变量（约定 `#i` 风格）在循环体内可引用。
/// 简化与限制：块内只支持 COMPUTE / RECODE（其余命令报错）；`BREAK` 对
/// 当前行集立即生效（不做「跳出后剩余体仍执行」的 PSPP 边缘语义）；
/// 迭代上限 10000（防死循环）；块内不支持 INCLUDE。
library;

import '../models/dataset.dart';
import '../transforms/transforms.dart';
import 'syntax_engine.dart';

/// 识别流程动词；返回 null 表示普通命令。
/// `DO` / `END` / `ELSE` 是两词动词，这里按前缀正则归一化。
String? flowVerbOf(SyntaxCommand cmd) {
  final raw = cmd.raw;
  bool head(String pat) =>
      RegExp('^\\s*$pat', caseSensitive: false).hasMatch(raw);
  if (head('DO\\s+IF\\b')) return 'DO IF';
  if (head('ELSE\\s+IF\\b')) return 'ELSE IF';
  if (head('ELSE\\b')) return 'ELSE';
  if (head('END\\s+IF\\b')) return 'END IF';
  if (head('END\\s+LOOP\\b')) return 'END LOOP';
  switch (cmd.verb.toUpperCase()) {
    case 'LOOP':
    case 'BREAK':
    case 'VECTOR':
      return cmd.verb.toUpperCase();
    default:
      return null;
  }
}

sealed class FlowNode {}

/// 普通命令（块内：仅 COMPUTE / RECODE 可执行）
class FlowSimple extends FlowNode {
  final SyntaxCommand cmd;
  FlowSimple(this.cmd);
}

/// BREAK 标记（只在 LOOP 体内合法）
class FlowBreak extends FlowNode {
  final SyntaxCommand cmd;

  /// `BREAK IF cond` 的条件（null = 无条件）
  final String? condition;
  FlowBreak(this.cmd, this.condition);
}

class FlowBranch {
  /// 分支头命令（DO IF / ELSE IF / ELSE）
  final SyntaxCommand head;

  /// 条件表达式（ELSE 分支为 null）
  final String? condition;
  final List<FlowNode> body;
  FlowBranch(this.head, this.condition, this.body);
}

/// DO IF 块：按顺序取第一个成立的分支
class FlowDoIf extends FlowNode {
  final List<FlowBranch> branches;
  FlowDoIf(this.branches);
}

class FlowLoop extends FlowNode {
  final SyntaxCommand head;

  /// 循环头形态：`index`（带计数变量）或 `if`（LOOP IF cond）或 `bare`
  final String kind;

  /// index 循环：变量名 / 起点 / 终点 / 步长
  final String? indexVar;
  final double? from, to, by;

  /// `LOOP IF cond` 的条件
  final String? condition;

  /// `END LOOP [IF cond]`
  final SyntaxCommand? endCmd;
  final String? endCondition;
  final List<FlowNode> body;
  FlowLoop({
    required this.head,
    required this.kind,
    required this.body,
    this.indexVar,
    this.from,
    this.to,
    this.by,
    this.condition,
    this.endCmd,
    this.endCondition,
  });
}

class FlowParseException implements Exception {
  final String verb; // 出错的流程动词
  FlowParseException(this.verb);
}

/// 从 [cmds]（下标 [start] 起）收集一个完整的块；返回（节点, 下一个未消费下标）。
/// [verbs] 提前算好每个命令的流程动词（null = 普通命令）。
(List<FlowNode>, int) collectFlow(
  List<SyntaxCommand> cmds,
  List<String?> verbs,
  int start,
) {
  return _collect(cmds, verbs, start, expectEnd: {});
}

/// 收集一个「体」直到遇到 [expectEnd] 之一（DO IF 体：ELSE IF / ELSE / END IF；
/// LOOP 体：END LOOP；顶层：空 = 到结尾）。返回（体, 停在哪个命令的下标）。
(List<FlowNode>, int) _collect(
  List<SyntaxCommand> cmds,
  List<String?> verbs,
  int i, {
  required Set<String> expectEnd,
}) {
  final body = <FlowNode>[];
  while (i < cmds.length) {
    final v = verbs[i];
    if (v != null && expectEnd.contains(v)) {
      return (body, i);
    }
    if (v == 'DO IF') {
      final branches = <FlowBranch>[];
      var branchHead = cmds[i];
      String? cond = _condOf(cmds[i], 'DO IF');
      i++;
      while (true) {
        final (b, j) = _collect(
          cmds,
          verbs,
          i,
          expectEnd: {'ELSE IF', 'ELSE', 'END IF'},
        );
        branches.add(FlowBranch(branchHead, cond, b));
        if (j >= cmds.length) throw FlowParseException('DO IF');
        final stop = verbs[j];
        branchHead = cmds[j];
        if (stop == null || stop == 'END IF' || stop == 'ELSE') {
          cond = null; // ELSE 无条件
        } else {
          cond = _condOf(cmds[j], stop);
        }
        i = j + 1;
        if (stop == 'END IF') break;
      }
      body.add(FlowDoIf(branches));
    } else if (v == 'LOOP') {
      final (b, j) = _collect(cmds, verbs, i + 1, expectEnd: {'END LOOP'});
      if (j >= cmds.length) throw FlowParseException('LOOP');
      final endCmd = cmds[j];
      final endCond =
          _hasWord(endCmd, 'IF') ? _afterWord(endCmd, 'IF') : null;
      body.add(_makeLoop(cmds[i], b, endCmd, endCond));
      i = j + 1;
    } else if (v == 'BREAK') {
      final c = cmds[i];
      body.add(FlowBreak(c, _hasWord(c, 'IF') ? _afterWord(c, 'IF') : null));
      i++;
    } else if (v == 'ELSE IF' || v == 'ELSE' || v == 'END IF') {
      // 只可能在匹配 expectEnd 时返回；这里意味着嵌套错位
      throw FlowParseException(v!);
    } else {
      body.add(FlowSimple(cmds[i]));
      i++;
    }
  }
  if (expectEnd.isNotEmpty) {
    // 块没有闭合
    throw FlowParseException(expectEnd.first);
  }
  return (body, i);
}

FlowLoop _makeLoop(
    SyntaxCommand head, List<FlowNode> body, SyntaxCommand endCmd,
    String? endCond) {
  // LOOP var = a TO b [BY step]  |  LOOP IF cond  |  LOOP.
  final raw = head.raw
      .replaceFirst(RegExp(r'^\s*LOOP\b', caseSensitive: false), '')
      .trim();
  final toM = RegExp(r'^(\S+)\s*=\s*(.+?)\s+TO\s+(.+)$', caseSensitive: false)
      .firstMatch(raw);
  if (toM != null) {
    final from = double.tryParse(toM.group(2)!);
    final tail = toM.group(3)!;
    final byM =
        RegExp(r'^(.+?)\s+BY\s+(.+)$', caseSensitive: false).firstMatch(tail);
    final to = double.tryParse((byM?.group(1) ?? tail).trim());
    final by = byM == null ? 1.0 : double.tryParse(byM.group(2)!.trim());
    if (from != null && to != null && by != null && by != 0) {
      return FlowLoop(
        head: head,
        kind: 'index',
        body: body,
        indexVar: toM.group(1)!,
        from: from,
        to: to,
        by: by,
        endCmd: endCmd,
        endCondition: endCond,
      );
    }
  }
  final ifM = RegExp(r'^IF\b(.+)$', caseSensitive: false).firstMatch(raw);
  if (ifM != null) {
    return FlowLoop(
      head: head,
      kind: 'if',
      body: body,
      condition: ifM.group(1)!.trim(),
      endCmd: endCmd,
      endCondition: endCond,
    );
  }
  return FlowLoop(
    head: head,
    kind: 'bare',
    body: body,
    endCmd: endCmd,
    endCondition: endCond,
  );
}

String _condOf(SyntaxCommand cmd, String verb) {
  return cmd.raw
      .replaceFirst(
          RegExp('^\\s*${RegExp.escape(verb)}\\b', caseSensitive: false), '')
      .trim();
}

bool _hasWord(SyntaxCommand cmd, String word) =>
    RegExp('\\b$word\\b', caseSensitive: false).hasMatch(cmd.raw);

String _afterWord(SyntaxCommand cmd, String word) => cmd.raw
    .replaceFirst(RegExp('^.*\\b$word\\b', caseSensitive: false), '')
    .trim();

/// 单条命令的执行回调（引擎提供：COMPUTE / RECODE 带行掩码；其余报错）。
typedef FlowExec = SyntaxResult Function(
  SyntaxCommand cmd,
  Set<int> rows,
  Map<String, double> loopVars,
);

/// 逐案条件求值：对 [rows] 里的每行构建变量表（行值 + [loopVars]），
/// 返回条件为真的行号集合。无法求值按假处理。
Set<int> rowsWhere(
  Dataset ds,
  Set<int> rows,
  String condition,
  Map<String, double> loopVars,
  Map<String, List<String>> vectors,
) {
  final out = <int>{};
  for (final ri in rows) {
    final row = ds.cases[ri];
    final vars = <String, double>{};
    for (var i = 0; i < ds.nVars && i < row.length; i++) {
      final raw = row[i];
      if (raw is num) vars[ds.variables[i].name] = raw.toDouble();
    }
    vars.addAll(loopVars);
    final v = ComputeEngine.evaluate(condition, vars, vectors: vectors);
    if (v != null && v.isFinite && v != 0) out.add(ri);
  }
  return out;
}

/// 执行流程节点；[rows] 是当前生效的行集（DO IF 嵌套求交集），
/// [onBreak] 由 LOOP 执行器提供：BREAK 命中的行加入其中。
List<SyntaxResult> execFlow(
  List<FlowNode> nodes,
  Dataset ds,
  Map<String, List<String>> vectors,
  Set<int> rows,
  Map<String, double> loopVars,
  FlowExec exec,
  Set<int> onBreak,
) {
  final out = <SyntaxResult>[];
  for (final node in nodes) {
    switch (node) {
      case FlowSimple(:final cmd):
        out.add(exec(cmd, rows, loopVars));
      case FlowBreak(:final cmd, :final condition):
        final hit = condition == null
            ? Set<int>.of(rows)
            : rowsWhere(ds, rows, condition, loopVars, vectors);
        onBreak.addAll(hit);
        out.add(SyntaxResult(
          command: cmd.raw,
          ok: true,
          output: 'BREAK (${hit.length} cases)',
        ));
      case FlowDoIf(:final branches):
        var remaining = Set<int>.of(rows);
        for (final br in branches) {
          if (remaining.isEmpty) break;
          final Set<int> active;
          if (br.condition == null) {
            active = Set<int>.of(remaining); // ELSE：吃掉剩余全部行
          } else {
            active =
                rowsWhere(ds, remaining, br.condition!, loopVars, vectors);
          }
          if (active.isNotEmpty) {
            out.addAll(execFlow(
                br.body, ds, vectors, active, loopVars, exec, onBreak));
            remaining.removeAll(active);
          }
        }
      case FlowLoop():
        out.addAll(
            _execLoop(node, ds, vectors, rows, loopVars, exec, onBreak));
    }
  }
  return out;
}

List<SyntaxResult> _execLoop(
  FlowLoop loop,
  Dataset ds,
  Map<String, List<String>> vectors,
  Set<int> rows,
  Map<String, double> loopVars,
  FlowExec exec,
  Set<int> onBreak,
) {
  const maxIters = 10000;
  final out = <SyntaxResult>[];
  var active = Set<int>.of(rows);
  switch (loop.kind) {
    case 'index':
      final by = loop.by ?? 1.0;
      final positive = by > 0;
      var it = 0;
      for (var v = loop.from!;
          positive ? v <= loop.to! : v >= loop.to!;
          v += by) {
        if (active.isEmpty || ++it > maxIters) break;
        final vars = <String, double>{...loopVars, loop.indexVar!: v};
        final broke = <int>{};
        out.addAll(
            execFlow(loop.body, ds, vectors, active, vars, exec, broke));
        active.removeAll(broke);
        if (loop.endCondition != null) {
          final stop = rowsWhere(ds, active, loop.endCondition!, vars, vectors);
          active.removeAll(stop);
        }
      }
    case 'if':
      var it = 0;
      while (active.isNotEmpty && ++it <= maxIters) {
        final cand = rowsWhere(ds, active, loop.condition!, loopVars, vectors);
        if (cand.isEmpty) break;
        final broke = <int>{};
        out.addAll(
            execFlow(loop.body, ds, vectors, cand, loopVars, exec, broke));
        active.removeAll(broke);
        if (loop.endCondition != null) {
          final stop =
              rowsWhere(ds, active, loop.endCondition!, loopVars, vectors);
          active.removeAll(stop);
        }
      }
    default: // bare
      var it = 0;
      while (active.isNotEmpty && ++it <= maxIters) {
        final broke = <int>{};
        out.addAll(
            execFlow(loop.body, ds, vectors, active, loopVars, exec, broke));
        active.removeAll(broke);
        if (onBreak.isNotEmpty) break;
        if (loop.endCondition != null) {
          final stop =
              rowsWhere(ds, active, loop.endCondition!, loopVars, vectors);
          active.removeAll(stop);
        }
      }
  }
  return out;
}

/// 解析 VECTOR 定义，返回登记表项（原始名 + 大写名都可查）。
/// 三种形式：`VECTOR v = v1 TO v10.` / `VECTOR v(k).` / `VECTOR v = a b c.`
Map<String, List<String>>? parseVector(SyntaxCommand cmd, Dataset ds) {
  final raw = cmd.raw
      .replaceFirst(RegExp(r'^\s*VECTOR\b', caseSensitive: false), '')
      .trim();
  final assignM = RegExp(r'^(\S+)\s*=\s*(.+)$').firstMatch(raw);
  if (assignM != null) {
    final name = assignM.group(1)!;
    final rhs = assignM.group(2)!.trim();
    final toM =
        RegExp(r'^(\w+)\s+TO\s+(\w+)$', caseSensitive: false).firstMatch(rhs);
    List<String> vars;
    if (toM != null) {
      final a = toM.group(1)!;
      final b = toM.group(2)!;
      final ma = RegExp(r'^(.*?)(\d+)$').firstMatch(a);
      final mb = RegExp(r'^(.*?)(\d+)$').firstMatch(b);
      if (ma == null || mb == null || ma.group(1) != mb.group(1)) return null;
      final prefix = ma.group(1)!;
      final from = int.parse(ma.group(2)!);
      final to = int.parse(mb.group(2)!);
      if (to < from || to - from > 1000) return null;
      vars = [
        for (var i = from; i <= to; i++) '$prefix$i',
      ];
    } else {
      vars = rhs.split(RegExp(r'\s+')).toList();
    }
    for (final v in vars) {
      if (ds.indexOf(v) < 0) return null; // 变量不存在
    }
    return {name.toUpperCase(): vars, name: vars};
  }
  final expandM = RegExp(r'^(\S+)\((\d+)\)$').firstMatch(raw);
  if (expandM != null) {
    final name = expandM.group(1)!;
    final k = int.parse(expandM.group(2)!);
    if (k < 1 || k > 1000) return null;
    final vars = [for (var i = 1; i <= k; i++) '$name$i'];
    // PSPP 语义：名(k) 形式会创建缺失的新数值变量
    for (final v in vars) {
      if (ds.indexOf(v) < 0) ds.addVariable(Variable(name: v));
    }
    return {name.toUpperCase(): vars, name: vars};
  }
  return null;
}

/// PSPP 语法子集执行器：解析并运行常用命令
library;


import '../models/dataset.dart';
import '../transforms/transforms.dart';
import 'package:statkit/statkit.dart';

class SyntaxCommand {
  final String verb;
  final List<String> args;
  final String raw;
  SyntaxCommand(this.verb, this.args, this.raw);
}

class SyntaxResult {
  final String command;
  final String output;
  final bool ok;
  final Dataset? newDataset;
  const SyntaxResult({
    required this.command,
    required this.output,
    required this.ok,
    this.newDataset,
  });
}

class SyntaxParser {
  static List<String> splitCommands(String source) {
    // 以句点结尾分割（PSPP 风格），忽略字符串内句点
    final out = <String>[];
    final buf = StringBuffer();
    var inStr = false;
    for (var i = 0; i < source.length; i++) {
      final ch = source[i];
      if (ch == '"' || ch == "'") inStr = !inStr;
      if (ch == '.' && !inStr) {
        final s = buf.toString().trim();
        if (s.isNotEmpty) out.add(s);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    final last = buf.toString().trim();
    if (last.isNotEmpty) out.add(last);
    return out;
  }

  static SyntaxCommand? parse(String cmd) {
    final lines = cmd
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('*'))
        .toList();
    if (lines.isEmpty) return null;
    final first = lines.first.toUpperCase();
    final verb = first.split(RegExp(r'\s+')).first;
    final rest = cmd.substring(cmd.indexOf(RegExp(r'\s+'))).trim();
    final args = _splitArgs(rest);
    return SyntaxCommand(verb, args, cmd);
  }

  static List<String> _splitArgs(String s) {
    // 按 / 与 逗号粗分，保留整体 token
    final out = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == ',') {
        final t = buf.toString().trim();
        if (t.isNotEmpty) out.add(t);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    final last = buf.toString().trim();
    if (last.isNotEmpty) out.add(last);
    return out;
  }
}

class SyntaxExecutor {
  static List<SyntaxResult> run(String source, Dataset ds) {
    final results = <SyntaxResult>[];
    for (final raw in SyntaxParser.splitCommands(source)) {
      final cmd = SyntaxParser.parse(raw);
      if (cmd == null) continue;
      results.add(_execute(cmd, ds));
    }
    return results;
  }

  static SyntaxResult _execute(SyntaxCommand cmd, Dataset ds) {
    try {
      switch (cmd.verb) {
        case 'COMPUTE':
          return _compute(cmd, ds);
        case 'RECODE':
          return _recode(cmd, ds);
        case 'RANK':
          return _rank(cmd, ds);
        case 'SORT':
        case 'SORT CASES':
          return _sort(cmd, ds);
        case 'SELECT':
        case 'SELECT IF':
          return _select(cmd, ds);
        case 'DESCRIPTIVES':
        case 'DESCRIPTIVE':
          return _descriptives(cmd, ds);
        case 'FREQUENCIES':
          return _frequencies(cmd, ds);
        case 'T-TEST':
        case 'TTEST':
          return _ttest(cmd, ds);
        case 'CORRELATIONS':
        case 'CORR':
          return _corr(cmd, ds);
        case 'LIST':
          return _list(ds);
        case 'DISPLAY':
        case 'SHOW':
          return SyntaxResult(
            command: cmd.raw,
            ok: true,
            output: 'Dataset ${ds.name}\n'
                'Cases: ${ds.nCases}  Variables: ${ds.nVars}\n'
                'Vars: ${ds.variables.map((v) => v.name).join(", ")}',
          );
        case 'HELP':
          return const SyntaxResult(
            command: 'HELP',
            ok: true,
            output: _helpText,
          );
        default:
          return SyntaxResult(
            command: cmd.raw,
            ok: false,
            output: '尚未支持的命令: ${cmd.verb}\n输入 HELP 查看支持列表',
          );
      }
    } catch (e) {
      return SyntaxResult(
        command: cmd.raw,
        ok: false,
        output: '错误: $e',
      );
    }
  }

  static const _helpText = '''
支持的命令（子集）:
  COMPUTE newvar = expression.
  RECODE var (old=new) ...
  RANK var.
  SORT CASES BY var1 var2.
  SELECT IF condition.
  DESCRIPTIVES var1 var2.
  FREQUENCIES var.
  T-TEST /TESTVAL=0 /VARIABLES=var.
  CORRELATIONS /VARIABLES=v1 v2.
  LIST.
  DISPLAY.
  HELP.
表达式支持 + - * / ( ) 与 abs sqrt ln exp log10 sin cos tan round trunc''';

  static SyntaxResult _compute(SyntaxCommand cmd, Dataset ds) {
    final raw = cmd.args.join(' ');
    final m = RegExp(r'^(\w+)\s*=\s*(.+)$', caseSensitive: false).firstMatch(raw);
    if (m == null) {
      return SyntaxResult(
          command: cmd.raw,
          ok: false,
          output: 'COMPUTE 语法: COMPUTE target = expression.');
    }
    final r = Transforms.compute(
      ds,
      targetVar: m.group(1)!,
      expression: m.group(2)!,
    );
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _recode(SyntaxCommand cmd, Dataset ds) {
    // RECODE a (1=10) (2=20) INTO b.  简化
    final raw = cmd.args.join(' ');
    final intoM = RegExp(r'INTO\s+(\w+)', caseSensitive: false).firstMatch(raw);
    final target = intoM?.group(1) ?? 'recoded';
    final varM = RegExp(r'^(\w+)').firstMatch(raw.trim());
    if (varM == null) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: 'RECODE 语法: RECODE v (old=new) INTO t.');
    }
    final rules = <String, String>{};
    for (final m in RegExp(r'\(([^)]+)\)').allMatches(raw)) {
      final kv = m.group(1)!.split('=');
      if (kv.length == 2) rules[kv[0].trim()] = kv[1].trim();
    }
    final r = Transforms.recode(
      ds,
      sourceVar: varM.group(1)!,
      targetVar: target,
      rules: rules,
    );
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _rank(SyntaxCommand cmd, Dataset ds) {
    final name = cmd.args.isNotEmpty ? cmd.args.first : 'post';
    final r = Transforms.rank(ds, sourceVar: name);
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _sort(SyntaxCommand cmd, Dataset ds) {
    final keys = cmd.args
        .expand((e) => e.split(RegExp(r'\s+')))
        .where((e) => e.isNotEmpty && e.toUpperCase() != 'BY' && e.toUpperCase() != 'DESCENDING')
        .toList();
    final desc = cmd.raw.toUpperCase().contains('DESCENDING') ||
        cmd.raw.toUpperCase().contains('/DESCENDING');
    final r = Transforms.sortCases(ds, keys: keys, descending: desc);
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _select(SyntaxCommand cmd, Dataset ds) {
    final cond = cmd.args.join(' ').replaceFirst(RegExp(r'^IF\s+', caseSensitive: false), '');
    final r = Transforms.selectIf(ds, condition: cond);
    return SyntaxResult(command: cmd.raw, ok: true, output: r.message);
  }

  static SyntaxResult _descriptives(SyntaxCommand cmd, Dataset ds) {
    final names = _varList(cmd.args.join(' '));
    final buf = StringBuffer('Descriptives\n');
    for (final n in names) {
      final d = Descriptives.compute(ds.numericColumn(n));
      buf.writeln(
          '$n  N=${d.n}  Mean=${formatNum(d.mean)}  SD=${formatNum(d.sd)}  '
          'Min=${formatNum(d.min)}  Max=${formatNum(d.max)}');
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _frequencies(SyntaxCommand cmd, Dataset ds) {
    final names = _varList(cmd.args.join(' '));
    final buf = StringBuffer('Frequencies\n');
    for (final n in names) {
      final f = Frequencies.compute(ds.rawColumn(n), variableName: n);
      buf.writeln('$n  Valid=${f.nValid}  Missing=${f.nMissing}');
      for (final r in f.rows.take(15)) {
        buf.writeln('  ${r.label}: ${r.frequency}  ${formatNum(r.validPercent, digits: 1)}%');
      }
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _ttest(SyntaxCommand cmd, Dataset ds) {
    final joined = cmd.args.join(' ');
    final testvalM =
        RegExp(r'TESTVAL\s*=\s*([\d.\-]+)', caseSensitive: false).firstMatch(joined);
    final mu = double.tryParse(testvalM?.group(1) ?? '') ?? 0;
    final names = _varList(joined);
    final buf = StringBuffer('T-Test  mu=$mu\n');
    for (final n in names) {
      final r = TTest.oneSample(ds.numericColumn(n), mu0: mu);
      buf.writeln(
          '$n  t=${formatNum(r.t)}  df=${formatNum(r.df, digits: 0)}  p=${formatP(r.pTwoTail)}  '
          'Mean=${formatNum(r.mean1)}  95%CI=[${formatNum(r.ciLower95)}, ${formatNum(r.ciUpper95)}]');
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _corr(SyntaxCommand cmd, Dataset ds) {
    final names = _varList(cmd.args.join(' '));
    if (names.length < 2) {
      return SyntaxResult(
          command: cmd.raw, ok: false, output: 'CORRELATIONS 需要至少 2 个变量');
    }
    final cols = [for (final n in names) ds.numericColumn(n)];
    final m = Correlation.matrix(cols);
    final buf = StringBuffer('Correlation Matrix\n');
    buf.writeln(names.map((n) => n.padLeft(10)).join(''));
    for (var i = 0; i < names.length; i++) {
      final row = [for (final r in m[i]) formatNum(r).padLeft(10)];
      buf.writeln('${names[i].padRight(10)}${row.join()}');
    }
    return SyntaxResult(command: cmd.raw, ok: true, output: buf.toString());
  }

  static SyntaxResult _list(Dataset ds) {
    final buf = StringBuffer('LIST  (${ds.nCases} cases)\n');
    buf.writeln(ds.variables.map((v) => v.name.padLeft(10)).join());
    for (var i = 0; i < ds.nCases && i < 50; i++) {
      buf.writeln(ds.cases[i]
          .map((e) => (e?.toString() ?? '').padLeft(10))
          .join());
    }
    if (ds.nCases > 50) buf.writeln('... ${ds.nCases - 50} more');
    return SyntaxResult(command: 'LIST.', ok: true, output: buf.toString());
  }

  static List<String> _varList(String s) {
    final tokens = s
        .replaceAll(RegExp(r'VARIABLES\s*=', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\/\w+', caseSensitive: false), ' ')
        .split(RegExp(r'[\s,=]+'))
        .where((e) => RegExp(r'^\w+$').hasMatch(e))
        .where((e) {
          final u = e.toUpperCase();
          return !const {
            'TO', 'BY', 'WITH', 'ALL', 'TESTVAL', 'VARIABLES', 'DESCRIPTIVES',
            'FREQUENCIES', 'CORRELATIONS', 'T-TEST', 'INTO',
          }.contains(u);
        })
        .toList();
    return tokens;
  }
}

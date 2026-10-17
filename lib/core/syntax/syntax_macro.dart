/// 宏（`DEFINE` / `!ENDDEFINE`）解析与展开：PSPP 常用子集。
///
/// 语义对照 `_ref/pspp-2.1.2/doc/flow-control.texi`：
/// - 参数：`!name=` / `!POSITIONAL`、`!TOKENS(n)`、`!CHAREND('c')`、`!CMDEND`、
///   `!DEFAULT(...)`
/// - 宏函数：`!CONCAT !QUOTE !UNQUOTE !UPCASE !LENGTH !SUBSTR !HEAD !TAIL
///   !INDEX !EVAL !NULL !BLANKS`
/// - 构造：`!LET`、`!IF/!THEN/!ELSE/!ENDIF`、`!DO !v = a !TO b [!BY s] … !DOEND`
///
/// 本版**不做**（遇到即报「未支持」，见 [MacroIssueKind.unsupported]）：
/// `!DO !v !IN (...)`、`!ENCLOSE`、`!NOEXPAND` / `!OFFEXPAND` / `!ONEXPAND`。
///
/// 展开时保留每个字符的原始偏移，因此宏体里的语法错误仍能定位到 `DEFINE`
/// 块，实参引入的文本定位到调用处。
library;

import 'dart:typed_data';

/// 文本 + 每个字符在原始源文件里的偏移。
class MacroText {
  MacroText(this.text, this.offsets);

  final String text;
  final List<int> offsets;

  static MacroText empty() => MacroText('', <int>[]);
}

/// 预处理期问题：由应用层（[SyntaxMessages]）转成界面文案。
enum MacroIssueKind {
  /// 调用了未定义的宏
  undefined,

  /// `!LET` / `!IF` / `!DO` / 宏函数出现在宏体之外
  constructOutsideBody,

  /// 明确未支持的构造（`!ENCLOSE`、`!DO … !IN`、`!OFFEXPAND` 等）
  unsupported,

  /// 递归超过深度上限
  recursion,

  /// `DEFINE` 本身写错（缺宏名、括号不配对、缺 `!ENDDEFINE`）
  badDefinition,

  /// `*` / `COMMENT` 注释没有以句点结束（读到文件末尾）
  unterminatedComment,

  /// `*` / `COMMENT` 注释按 PSPP 规则吞掉了后续看起来是命令的行
  swallowedCommand,
}

class MacroIssue {
  const MacroIssue(this.kind, this.name, this.offset);

  final MacroIssueKind kind;
  final String name;
  final int offset;

  /// 偏移平移（整份文件分几次预处理时用）。
  MacroIssue shifted(int delta) => MacroIssue(kind, name, offset + delta);
}

/// 参数取值方式（PSPP 的 `!TOKENS` / `!CHAREND` / `!CMDEND`）。
class MacroArg {
  MacroArg({
    required this.name,
    required this.positional,
    required this.index,
    this.tokens = 1,
    this.charEnd,
    this.cmdEnd = false,
    this.fallback,
  });

  /// 大写参数名；`!POSITIONAL` 声明的参数名为空串。
  final String name;
  final bool positional;

  /// 1-based 参数序号（`!1`、`!2` … 引用）。
  final int index;

  /// 取实参的前 n 个记号（默认 1）。
  final int tokens;

  /// 取到该字符为止。
  final String? charEnd;

  /// 取到命令末尾。
  final bool cmdEnd;

  /// `!DEFAULT(...)`：实参缺省时的取值。
  final String? fallback;
}

class MacroDef {
  MacroDef(this.name, this.args, this.body, this.bodyOffsets);

  /// 大写、不含 `!`。
  final String name;
  final List<MacroArg> args;
  final String body;
  final List<int> bodyOffsets;
}

/// 宏表。重复 `DEFINE` 同名宏按 PSPP 覆盖旧定义。
class MacroTable {
  final Map<String, MacroDef> _defs = {};

  MacroDef? lookup(String name) => _defs[name.toUpperCase()];

  void define(MacroDef def) => _defs[def.name] = def;

  Iterable<String> get names => _defs.keys;

  bool get isEmpty => _defs.isEmpty;

  int get length => _defs.length;
}

/// 文本扫描辅助：字符串字面量掩码 + 整词记号查找。
class TextScan {
  TextScan(this.text) : mask = _buildMask(text);

  final String text;

  /// `mask[i] == 1` 表示 `text[i]` 在单/双引号字符串字面量内（含引号本身）。
  final Uint8List mask;

  static Uint8List _buildMask(String s) {
    final m = Uint8List(s.length);
    var inStr = false;
    var quote = '';
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (inStr) {
        m[i] = 1;
        if (c == quote) inStr = false;
      } else if (c == "'" || c == '"') {
        inStr = true;
        quote = c;
        m[i] = 1;
      }
    }
    return m;
  }

  bool inString(int i) => i >= 0 && i < mask.length && mask[i] == 1;

  /// 从 [from] 起找整词记号（大小写不敏感、跳过字符串内命中）。
  int findToken(String token, int from, {int? end}) {
    final stop = end ?? text.length;
    final hay = text.toUpperCase();
    final tok = token.toUpperCase();
    var i = from;
    while (i <= stop - tok.length) {
      final k = hay.indexOf(tok, i);
      if (k < 0 || k + tok.length > stop) return -1;
      if (mask[k] == 1) {
        i = k + 1;
        continue;
      }
      final before = k == 0 ? '' : text[k - 1];
      final after = k + tok.length >= text.length ? '' : text[k + tok.length];
      if ((before.isEmpty || !isWordChar(before)) &&
          (after.isEmpty || !isWordChar(after))) {
        return k;
      }
      i = k + 1;
    }
    return -1;
  }

  /// 匹配从 [open]（`(` 或 `'`/`"`）开始的配对括号，返回配对的 `)` 下标。
  int matchParen(int open) {
    var depth = 0;
    for (var i = open; i < text.length; i++) {
      if (mask[i] == 1) continue;
      final c = text[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  int skipWs(int i) {
    var k = i;
    while (k < text.length && isSpace(text[k])) {
      k++;
    }
    return k;
  }

  int lineEnd(int i) {
    var k = i;
    while (k < text.length && text[k] != '\n' && text[k] != '\r') {
      k++;
    }
    return k;
  }

  static bool isSpace(String c) =>
      c == ' ' || c == '\t' || c == '\n' || c == '\r';

  /// 宏名 / 变量名允许的字符（`!` 也算，便于整词匹配 `!ENDDEFINE`）。
  static bool isWordChar(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 48 && u <= 57) ||
        (u >= 65 && u <= 90) ||
        (u >= 97 && u <= 122) ||
        c == '_' ||
        c == '!';
  }
}

/// 宏函数名单（在宏体内求值，出现在体外即报错）。
const macroFunctionNames = {
  'CONCAT', 'QUOTE', 'UNQUOTE', 'UPCASE', 'LENGTH', 'SUBSTR', 'HEAD', 'TAIL',
  'INDEX', 'EVAL', 'NULL', 'BLANKS',
};

/// 宏构造名单（在宏体内是控制流，出现在体外即报错）。
const macroConstructNames = {
  'LET', 'IF', 'THEN', 'ELSE', 'ENDIF', 'DO', 'DOEND', 'TO', 'BY', 'IN',
};

/// 明确未支持的构造：本版不做，遇到给出清晰报错而不是静默忽略。
const macroUnsupportedNames = {
  'ENCLOSE', 'NOEXPAND', 'OFFEXPAND', 'ONEXPAND', 'DEFINE', 'ENDDEFINE',
};

/// 从一个（已去注释的）脚本里摘出 `DEFINE` 定义。
class MacroDefs {
  /// 返回移除定义后的文本与偏移；定义写入 [table]；问题写入 [issues]。
  static MacroText extract(
    String text,
    List<int> offsets,
    MacroTable table,
    List<MacroIssue> issues,
  ) {
    final scan = TextScan(text);
    final keep = StringBuffer();
    final keepOffsets = <int>[];
    var copied = 0;
    var search = 0;

    while (true) {
      final d = scan.findToken('DEFINE', search);
      if (d < 0) break;
      search = d + 6;

      var j = scan.skipWs(d + 6);
      if (j < text.length && text[j] == '!') j++;
      final nameStart = j;
      var k = j;
      while (k < text.length &&
          text[k] != '!' &&
          TextScan.isWordChar(text[k])) {
        k++;
      }
      final name = text.substring(nameStart, k);
      if (name.isEmpty) {
        issues.add(MacroIssue(MacroIssueKind.badDefinition, '', offsets[d]));
        continue;
      }

      var cursor = scan.skipWs(k);
      var args = <MacroArg>[];
      if (cursor < text.length && text[cursor] == '(') {
        final close = scan.matchParen(cursor);
        if (close < 0) {
          issues.add(MacroIssue(MacroIssueKind.badDefinition, name, offsets[d]));
          continue;
        }
        args = _parseArgs(text.substring(cursor + 1, close), issues, offsets[d]);
        cursor = close + 1;
      }

      final endTok = scan.findToken('!ENDDEFINE', cursor);
      if (endTok < 0) {
        issues.add(MacroIssue(MacroIssueKind.badDefinition, name, offsets[d]));
        continue;
      }

      var bodyStart = cursor;
      var bodyEnd = endTok;
      while (bodyStart < bodyEnd && TextScan.isSpace(text[bodyStart])) {
        bodyStart++;
      }
      while (bodyEnd > bodyStart && TextScan.isSpace(text[bodyEnd - 1])) {
        bodyEnd--;
      }
      if (bodyEnd > bodyStart) {
        table.define(MacroDef(
          name.toUpperCase(),
          args,
          text.substring(bodyStart, bodyEnd),
          offsets.sublist(bodyStart, bodyEnd),
        ));
      } else {
        table.define(MacroDef(name.toUpperCase(), args, '', <int>[]));
      }

      // 定义整体（含结尾句点）从脚本里移除
      keep.write(text.substring(copied, d));
      keepOffsets.addAll(offsets.sublist(copied, d));
      var after = endTok + '!ENDDEFINE'.length;
      final dot = scan.skipWs(after);
      if (dot < text.length && text[dot] == '.') after = dot + 1;
      copied = after;
      search = after;
    }

    keep.write(text.substring(copied));
    keepOffsets.addAll(offsets.sublist(copied));
    return MacroText(keep.toString(), keepOffsets);
  }

  /// 按顶层 `/` 或 `,` 切分参数规格（`!CHAREND('/')` 这类括号 / 引号内的分隔符不算）。
  static List<String> _splitArgSpec(String spec) {
    final out = <String>[];
    var start = 0;
    var depth = 0;
    var quote = '';
    for (var i = 0; i < spec.length; i++) {
      final c = spec[i];
      if (quote.isNotEmpty) {
        if (c == quote) quote = '';
        continue;
      }
      if (c == "'" || c == '"') {
        quote = c;
        continue;
      }
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
      } else if ((c == '/' || c == ',') && depth == 0) {
        out.add(spec.substring(start, i));
        start = i + 1;
      }
    }
    out.add(spec.substring(start));
    return out;
  }

  static List<MacroArg> _parseArgs(
      String spec, List<MacroIssue> issues, int offset) {
    final out = <MacroArg>[];
    // 参数之间用 `/` 或 `,` 分隔（PSPP 用 `/`）；括号 / 引号内的分隔符不算
    for (final raw in _splitArgSpec(spec)) {
      final text = raw.trim();
      if (text.isEmpty) continue;
      final index = out.length + 1;
      final positional = RegExp(r'!POSITIONAL\b', caseSensitive: false)
          .hasMatch(text);
      String name = '';
      if (!positional) {
        final m = RegExp(r'!?([A-Za-z_]\w*)').firstMatch(text);
        name = (m?.group(1) ?? '').toUpperCase();
      }
      final tokensM =
          RegExp(r'!TOKENS\s*\(\s*(\d+)\s*\)', caseSensitive: false)
              .firstMatch(text);
      final charM = RegExp("!CHAREND\\s*\\(\\s*'(.)'\\s*\\)", caseSensitive: false)
          .firstMatch(text);
      var cmdEnd = RegExp(r'!CMDEND\b', caseSensitive: false).hasMatch(text);
      final defM = RegExp(r'!DEFAULT\s*\(([^)]*)\)', caseSensitive: false)
          .firstMatch(text);
      // 本版不做的取值方式：明确报错，同时尽量按“取到命令末尾”兜底
      if (RegExp(r'!ENCLOSE\b', caseSensitive: false).hasMatch(text)) {
        issues.add(MacroIssue(MacroIssueKind.unsupported, 'ENCLOSE', offset));
        cmdEnd = true;
      }
      if (RegExp(r'!NOEXPAND\b', caseSensitive: false).hasMatch(text)) {
        issues.add(MacroIssue(MacroIssueKind.unsupported, 'NOEXPAND', offset));
      }
      out.add(MacroArg(
        name: name,
        positional: positional,
        index: index,
        tokens: tokensM == null ? 1 : int.parse(tokensM.group(1)!),
        charEnd: charM?.group(1),
        cmdEnd: cmdEnd,
        fallback: defM?.group(1)?.trim(),
      ));
    }
    return out;
  }
}

/// 展开上下文：实参 + `!LET` 局部变量。
class _Env {
  final Map<String, MacroText> args = {};
  final Map<String, MacroText> byIndex = {};
  final Map<String, MacroText> locals = {};

  MacroText? resolve(String name) =>
      locals[name] ?? args[name] ?? byIndex[name];
}

/// 宏展开器。顶层只展开宏调用；`!LET` / `!IF` / `!DO` 与宏函数只在宏体内有效。
class MacroExpander {
  MacroExpander(this.table, {this.maxDepth = 32, List<MacroIssue>? issues})
      : issues = issues ?? <MacroIssue>[];

  final MacroTable table;
  final int maxDepth;
  final List<MacroIssue> issues;

  /// 展开顶层文本里的宏调用。
  MacroText expandTopLevel(String text, List<int> offsets) {
    final out = StringBuffer();
    final outOffsets = <int>[];
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (ch != '!') {
        out.write(ch);
        outOffsets.add(offsets[i]);
        i++;
        continue;
      }
      final (name, afterName) = _readName(text, i);
      if (name.isEmpty) {
        out.write(ch);
        outOffsets.add(offsets[i]);
        i++;
        continue;
      }
      final upper = name.toUpperCase();
      if (macroUnsupportedNames.contains(upper)) {
        issues.add(MacroIssue(MacroIssueKind.unsupported, upper, offsets[i]));
        i = _skipInvocationArgs(text, afterName);
        continue;
      }
      if (macroFunctionNames.contains(upper) ||
          macroConstructNames.contains(upper)) {
        issues.add(MacroIssue(
            MacroIssueKind.constructOutsideBody, upper, offsets[i]));
        i = _skipInvocationArgs(text, afterName);
        continue;
      }
      final def = table.lookup(upper);
      if (def == null) {
        issues.add(MacroIssue(MacroIssueKind.undefined, upper, offsets[i]));
        i = _skipInvocationArgs(text, afterName);
        continue;
      }
      final (bound, end) =
          _bindInvocation(def, text, offsets, afterName, offsets[i], null, 1);
      final expanded = _expandBody(def, bound, 1);
      out.write(expanded.text);
      outOffsets.addAll(expanded.offsets);
      i = end;
    }
    return MacroText(out.toString(), outOffsets);
  }

  int _skipInvocationArgs(String text, int from) {
    if (from < text.length && text[from] == '(') {
      final close = TextScan(text).matchParen(from);
      if (close > 0) return close + 1;
    }
    return from;
  }

  (String, int) _readName(String text, int bang) {
    var i = bang + 1;
    while (i < text.length && TextScan.isWordChar(text[i]) && text[i] != '!') {
      i++;
    }
    return (text.substring(bang + 1, i), i);
  }

  /// 解析一次宏调用的实参，并把「宏名 + 实参」整体消费掉。
  ///
  /// PSPP 的调用形如 `!analyze v1 v2 v3.`（实参按声明规格取值）；为便于
  /// SPSS 习惯，`!analyze(v1, v2)` 这种括号形式也接受。
  (_Env, int) _bindInvocation(MacroDef def, String text, List<int> offsets,
      int afterName, int callOffset, _Env? callerEnv, int depth) {
    final scan = TextScan(text);
    final argEnd = _commandEnd(text, afterName);
    final pos = scan.skipWs(afterName);
    MacroText expandArg(MacroText v) =>
        _expand(v.text, v.offsets, callerEnv ?? _Env(), depth);

    // 括号形式：`!name(a, b)`
    if (pos < argEnd && text[pos] == '(') {
      final close = scan.matchParen(pos);
      if (close > 0 && close <= argEnd) {
        final inner = text.substring(pos + 1, close);
        final innerOffsets = offsets.sublist(pos + 1, close);
        final groups = [
          for (final g in _splitTop(inner, innerOffsets)) expandArg(g),
        ];
        final env = groups.length == def.args.length
            ? _bindGroups(def, groups, callOffset)
            : _bindSpec(def, inner, innerOffsets, callOffset, expandArg).$1;
        return (env, close + 1);
      }
    }

    // PSPP 风格：实参直接跟在宏名之后
    final region = text.substring(pos, argEnd);
    final regionOffsets = offsets.sublist(pos, argEnd);
    final (env, consumed) =
        _bindSpec(def, region, regionOffsets, callOffset, expandArg);
    return (env, consumed > 0 ? pos + consumed : afterName);
  }

  /// 按声明规格绑定实参：`!TOKENS(n)` / `!CHAREND('c')` / `!CMDEND` / `!DEFAULT`；
  /// 关键字参数写成 `name=value`（顺序任意）。
  (_Env, int) _bindSpec(MacroDef def, String region, List<int> regionOffsets,
      int callOffset, MacroText Function(MacroText) expandArg) {
    final scan = TextScan(region);
    final env = _Env();
    var pos = 0;
    for (final arg in def.args) {
      MacroText? value;
      if (!arg.positional && arg.name.isNotEmpty) {
        final at = _findKeyword(region, arg.name, pos);
        if (at >= 0) {
          pos = scan.skipWs(at + arg.name.length + 1);
          final r = _readSpecValue(arg, region, regionOffsets, pos);
          value = r.value;
          pos = r.next;
        }
      } else {
        final r = _readSpecValue(arg, region, regionOffsets, pos);
        value = r.value;
        pos = r.next;
      }
      value = _resolveArgValue(arg, value, callOffset, expandArg);
      if (arg.name.isNotEmpty) env.args[arg.name] = value;
      env.byIndex['${arg.index}'] = value;
    }
    return (env, pos);
  }

  /// 括号形式：每个顶层逗号分组对应一个实参。
  _Env _bindGroups(MacroDef def, List<MacroText> groups, int callOffset) {
    final env = _Env();
    for (var k = 0; k < def.args.length; k++) {
      final arg = def.args[k];
      var value = k < groups.length ? groups[k] : null;
      if (value != null && arg.name.isNotEmpty) {
        final m = RegExp(r'^\s*!?' + RegExp.escape(arg.name) + r'\s*=',
                caseSensitive: false)
            .firstMatch(value.text);
        if (m != null) {
          value =
              _trim(value.text.substring(m.end), value.offsets.sublist(m.end));
        }
      }
      if (value == null || value.text.isEmpty) {
        value = arg.fallback != null
            ? MacroText(
                arg.fallback!, List.filled(arg.fallback!.length, callOffset))
            : MacroText('', <int>[]);
      }
      if (arg.name.isNotEmpty) env.args[arg.name] = value;
      env.byIndex['${arg.index}'] = value;
    }
    return env;
  }

  /// 实参缺省用 `!DEFAULT(...)`，否则空值；有取值时展开其中的宏调用。
  static MacroText _resolveArgValue(MacroArg arg, MacroText? value,
      int callOffset, MacroText Function(MacroText) expandArg) {
    if (value == null || value.text.isEmpty) {
      if (arg.fallback != null) {
        return MacroText(
            arg.fallback!, List.filled(arg.fallback!.length, callOffset));
      }
      return MacroText('', <int>[]);
    }
    return expandArg(value);
  }

  /// 按规格从 [from] 起取一个实参值。
  _SpecValue _readSpecValue(
      MacroArg arg, String region, List<int> regionOffsets, int from) {
    final scan = TextScan(region);
    final pos = scan.skipWs(from);
    if (arg.cmdEnd) {
      return _SpecValue(
          _trim(region.substring(pos), regionOffsets.sublist(pos)),
          region.length);
    }
    if (arg.charEnd != null) {
      final at = region.indexOf(arg.charEnd!, pos);
      final end = at < 0 ? region.length : at;
      return _SpecValue(
        _trim(region.substring(pos, end), regionOffsets.sublist(pos, end)),
        at < 0 ? region.length : at + 1,
      );
    }
    // !TOKENS(n)
    var taken = 0;
    var cursor = pos;
    var end = pos;
    while (taken < arg.tokens && cursor < region.length) {
      cursor = scan.skipWs(cursor);
      if (cursor >= region.length) break;
      cursor = _skipToken(region, cursor);
      taken++;
      end = cursor;
    }
    return _SpecValue(
        _trim(region.substring(pos, end), regionOffsets.sublist(pos, end)), end);
  }

  /// 跳过一个记号（标识符 / 数字 / 引号串 / 括号组 / 单字符运算符）。
  int _skipToken(String s, int i) {
    final c = s[i];
    if (c == "'" || c == '"') {
      var k = i + 1;
      while (k < s.length && s[k] != c) {
        k++;
      }
      return k < s.length ? k + 1 : s.length;
    }
    if (c == '(') {
      var depth = 0;
      for (var k = i; k < s.length; k++) {
        if (s[k] == '(') {
          depth++;
        } else if (s[k] == ')') {
          depth--;
          if (depth == 0) return k + 1;
        }
      }
      return s.length;
    }
    if (_isPunct(c)) return i + 1;
    var k = i;
    while (k < s.length && !TextScan.isSpace(s[k]) && !_isPunct(s[k])) {
      k++;
    }
    return k == i ? i + 1 : k;
  }

  static bool _isPunct(String c) => ',()/='.contains(c);

  /// 找关键字实参的 `name=`（大小写不敏感，整词）。
  int _findKeyword(String region, String name, int from) {
    final re = RegExp(r'(?<![\w!])' + RegExp.escape(name) + r'\s*=',
        caseSensitive: false);
    final m = re.firstMatch(region.substring(from));
    return m == null ? -1 : from + m.start;
  }

  /// 当前命令的终止符位置（划定宏实参的范围）。
  int _commandEnd(String text, int from) {
    final scan = TextScan(text);
    for (var i = from; i < text.length; i++) {
      if (scan.inString(i)) continue;
      if (text[i] != '.') continue;
      final prev = i > 0 ? text[i - 1] : '';
      final next = i + 1 < text.length ? text[i + 1] : '';
      if (!(_isDigit(prev) && _isDigit(next))) return i;
    }
    return text.length;
  }

  static bool _isDigit(String c) {
    if (c.isEmpty) return false;
    final u = c.codeUnitAt(0) - 48;
    return u >= 0 && u <= 9;
  }

  /// 顶层逗号切分（字符串 / 括号内的逗号不切）。
  List<MacroText> _splitTop(String inner, List<int> innerOffsets) {
    final out = <MacroText>[];
    final scan = TextScan(inner);
    var start = 0;
    var depth = 0;
    for (var i = 0; i < inner.length; i++) {
      if (scan.inString(i)) continue;
      final c = inner[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
      } else if (c == ',' && depth == 0) {
        out.add(
            _trim(inner.substring(start, i), innerOffsets.sublist(start, i)));
        start = i + 1;
      }
    }
    if (inner.trim().isNotEmpty || out.isNotEmpty) {
      out.add(_trim(inner.substring(start), innerOffsets.sublist(start)));
    }
    return out;
  }

  /// 顶层空白切分（仅在实参里没有引号时使用）。
  static List<MacroText> _splitWs(MacroText g) {
    final out = <MacroText>[];
    var i = 0;
    while (i < g.text.length) {
      while (i < g.text.length && TextScan.isSpace(g.text[i])) {
        i++;
      }
      if (i >= g.text.length) break;
      var j = i;
      while (j < g.text.length && !TextScan.isSpace(g.text[j])) {
        j++;
      }
      out.add(MacroText(g.text.substring(i, j), g.offsets.sublist(i, j)));
      i = j;
    }
    return out;
  }

  /// 宏函数实参：形如 `!CONCAT(a, b)`；只有一个分组且含空格时按空格再切
  /// （兼容 `!CONCAT(a b)` 这种写法）。返回（实参, 括号之后的偏移）。
  (List<MacroText>, int)? _functionArgs(
      String text, List<int> offsets, int from) {
    if (from >= text.length || text[from] != '(') return null;
    final close = TextScan(text).matchParen(from);
    if (close < 0) return null;
    final inner = text.substring(from + 1, close);
    final innerOffsets = offsets.sublist(from + 1, close);
    var groups = _splitTop(inner, innerOffsets);
    if (groups.length == 1 &&
        !groups.first.text.contains("'") &&
        !groups.first.text.contains('"') &&
        RegExp(r'\s').hasMatch(groups.first.text.trim())) {
      groups = _splitWs(groups.first);
    }
    return (groups, close + 1);
  }

  static MacroText _trim(String text, List<int> offsets) {
    var a = 0;
    var b = text.length;
    while (a < b && TextScan.isSpace(text[a])) {
      a++;
    }
    while (b > a && TextScan.isSpace(text[b - 1])) {
      b--;
    }
    return MacroText(text.substring(a, b), offsets.sublist(a, b));
  }

  MacroText _expandBody(MacroDef def, _Env env, int depth) =>
      _expand(def.body, def.bodyOffsets, env, depth);

  /// 宏体内的展开：实参替换、宏函数、`!LET` / `!IF` / `!DO`、嵌套调用。
  MacroText _expand(String text, List<int> offsets, _Env env, int depth) {
    final out = StringBuffer();
    final outOffsets = <int>[];
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (ch != '!') {
        out.write(ch);
        outOffsets.add(offsets[i]);
        i++;
        continue;
      }
      final (name, afterName) = _readName(text, i);
      if (name.isEmpty) {
        out.write(ch);
        outOffsets.add(offsets[i]);
        i++;
        continue;
      }
      final upper = name.toUpperCase();

      // 实参 / 局部变量替换
      final bound = env.resolve(upper);
      if (bound != null) {
        out.write(bound.text);
        outOffsets.addAll(bound.offsets);
        i = afterName;
        continue;
      }

      switch (upper) {
        case 'LET':
          final scan = TextScan(text);
          final (varName, nameEnd) = _readName(text, scan.skipWs(afterName));
          var valueStart = scan.skipWs(nameEnd);
          if (valueStart < text.length && text[valueStart] == '=') {
            valueStart = scan.skipWs(valueStart + 1);
          }
          final lineEnd = scan.lineEnd(valueStart);
          final expr = _expand(
              text.substring(valueStart, lineEnd),
              offsets.sublist(valueStart, lineEnd),
              env,
              depth);
          if (varName.isNotEmpty) {
            env.locals[varName.toUpperCase()] =
                _trim(expr.text, expr.offsets);
          }
          i = lineEnd;
          continue;
        case 'IF':
          final handled = _expandConditional(text, offsets, i, afterName, env, depth);
          if (handled == null) {
            issues.add(MacroIssue(MacroIssueKind.badDefinition, 'IF', offsets[i]));
            i = afterName;
            continue;
          }
          out.write(handled.text);
          outOffsets.addAll(handled.offsets);
          i = handled.end;
          continue;
        case 'DO':
          final handled = _expandLoop(text, offsets, i, afterName, env, depth);
          if (handled == null) {
            issues.add(MacroIssue(MacroIssueKind.badDefinition, 'DO', offsets[i]));
            i = afterName;
            continue;
          }
          out.write(handled.text);
          outOffsets.addAll(handled.offsets);
          i = handled.end;
          continue;
        case 'THEN':
        case 'ELSE':
        case 'ENDIF':
        case 'DOEND':
        case 'TO':
        case 'BY':
        case 'IN':
          // 没有对应 !IF / !DO 的孤立记号
          issues.add(MacroIssue(MacroIssueKind.badDefinition, upper, offsets[i]));
          i = afterName;
          continue;
      }

      if (macroUnsupportedNames.contains(upper)) {
        issues.add(MacroIssue(MacroIssueKind.unsupported, upper, offsets[i]));
        i = _skipInvocationArgs(text, afterName);
        continue;
      }

      // 宏函数（形如 !CONCAT(a,b)；!NULL 可以不带括号）
      if (macroFunctionNames.contains(upper)) {
        if (upper == 'NULL' && (afterName >= text.length || text[afterName] != '(')) {
          i = afterName;
          continue;
        }
        final parts = _functionArgs(text, offsets, afterName);
        if (parts == null) {
          issues.add(MacroIssue(MacroIssueKind.badDefinition, upper, offsets[i]));
          i = afterName;
          continue;
        }
        // 函数实参本身也可能含宏调用，先展开再求值
        final values = [
          for (final g in parts.$1)
            _expand(g.text, g.offsets, env, depth),
        ];
        final result = _evalFunction(upper, values, offsets[i], env, depth);
        out.write(result.text);
        outOffsets.addAll(result.offsets);
        i = parts.$2;
        continue;
      }

      // 嵌套宏调用
      final def = table.lookup(upper);
      if (def == null) {
        issues.add(MacroIssue(MacroIssueKind.undefined, upper, offsets[i]));
        i = _skipInvocationArgs(text, afterName);
        continue;
      }
      if (depth + 1 > maxDepth) {
        issues.add(MacroIssue(MacroIssueKind.recursion, upper, offsets[i]));
        i = _skipInvocationArgs(text, afterName);
        continue;
      }
      final (boundEnv, end) = _bindInvocation(
          def, text, offsets, afterName, offsets[i], env, depth + 1);
      final expanded = _expandBody(def, boundEnv, depth + 1);
      out.write(expanded.text);
      outOffsets.addAll(expanded.offsets);
      i = end;
    }
    return MacroText(out.toString(), outOffsets);
  }

  _Region? _expandConditional(String text, List<int> offsets, int bang,
      int afterName, _Env env, int depth) {
    final scan = TextScan(text);
    final thenAt = scan.findToken('!THEN', afterName);
    if (thenAt < 0) return null;
    final condText = text.substring(afterName, thenAt);
    final condOffsets = offsets.sublist(afterName, thenAt);
    final parenOpen = condText.indexOf('(');
    final cond = parenOpen >= 0 && scan.matchParen(afterName + parenOpen) > 0
        ? text.substring(afterName + parenOpen + 1,
            scan.matchParen(afterName + parenOpen))
        : condText;
    final condOffsets2 = parenOpen >= 0
        ? offsets.sublist(afterName + parenOpen + 1,
            scan.matchParen(afterName + parenOpen))
        : condOffsets;

    // 找同层 !ELSE / !ENDIF（跳过嵌套 !IF）
    var nest = 0;
    var cursor = thenAt + '!THEN'.length;
    var elseAt = -1;
    var endifAt = -1;
    while (cursor < text.length) {
      final nextIf = scan.findToken('!IF', cursor);
      final nextEndif = scan.findToken('!ENDIF', cursor);
      if (nextEndif < 0) break;
      if (nextIf >= 0 && nextIf < nextEndif) {
        nest++;
        cursor = nextIf + 3;
        continue;
      }
      if (nest == 0) {
        // !ELSE 需在同层、且在 !ENDIF 之前
        final e = scan.findToken('!ELSE', cursor, end: nextEndif);
        if (e >= 0) elseAt = e;
        endifAt = nextEndif;
        break;
      }
      nest--;
      cursor = nextEndif + '!ENDIF'.length;
    }
    if (endifAt < 0) return null;

    final condValue = _evalCondition(
        _expand(cond, condOffsets2, env, depth).text);
    final trueEnd = elseAt >= 0 ? elseAt : endifAt;
    final branch = condValue
        ? (thenAt + '!THEN'.length, trueEnd)
        : elseAt >= 0
            ? (elseAt + '!ELSE'.length, endifAt)
            : null;
    final inner = branch == null
        ? MacroText('', <int>[])
        : _expand(text.substring(branch.$1, branch.$2),
            offsets.sublist(branch.$1, branch.$2), env, depth);
    return _Region(inner.text, inner.offsets, endifAt + '!ENDIF'.length);
  }

  _Region? _expandLoop(String text, List<int> offsets, int bang, int afterName,
      _Env env, int depth) {
    final scan = TextScan(text);
    final headerEnd = scan.lineEnd(afterName);
    final header = text.substring(afterName, headerEnd);
    final base = offsets[bang];

    // 先找同层 !DOEND（跳过嵌套 !DO）；找不到就不是合法的 !DO
    var nest = 0;
    var cursor = headerEnd;
    var doEndAt = -1;
    while (cursor < text.length) {
      final nextDo = scan.findToken('!DO', cursor);
      final nextEnd = scan.findToken('!DOEND', cursor);
      if (nextEnd < 0) break;
      if (nextDo >= 0 && nextDo < nextEnd) {
        nest++;
        cursor = nextDo + 3;
        continue;
      }
      if (nest == 0) {
        doEndAt = nextEnd;
        break;
      }
      nest--;
      cursor = nextEnd + '!DOEND'.length;
    }
    if (doEndAt < 0) return null;
    final consumeTo = doEndAt + '!DOEND'.length;

    // `!DO !v !IN (…)` 明确未支持（本版不做）
    if (RegExp(r'!IN\b', caseSensitive: false).hasMatch(header)) {
      issues.add(
          MacroIssue(MacroIssueKind.unsupported, 'DO !IN', base));
      return _Region('', <int>[], consumeTo);
    }

    final m = RegExp(
            r'^\s*(!?\w+)\s*=\s*(.*?)\s*!TO\s+(.*?)(?:\s*!BY\s+(\S+))?\s*$',
            caseSensitive: false)
        .firstMatch(header);
    if (m == null) {
      issues.add(MacroIssue(MacroIssueKind.badDefinition, 'DO', base));
      return _Region('', <int>[], consumeTo);
    }
    final varName = m.group(1)!.toUpperCase().replaceFirst('!', '');
    final fromText = m.group(2)!.trim();
    final toText = m.group(3)!.trim();
    final byText = (m.group(4) ?? '1').trim();

    double? numValue(String expr) => _num(_expand(expr, List.filled(expr.length, base), env, depth).text);
    final from = numValue(fromText);
    final to = numValue(toText);
    final by = numValue(byText) ?? 1;
    if (from == null || to == null || by == 0) {
      issues.add(MacroIssue(MacroIssueKind.badDefinition, 'DO', base));
      return _Region('', <int>[], consumeTo);
    }

    final bodyStart = headerEnd;
    final bodyEnd = doEndAt;
    final out = StringBuffer();
    final outOffsets = <int>[];
    final step = by.abs();
    void iteration(double v) {
      env.locals[varName] = MacroText(_fmtNum(v), <int>[]);
      final part = _expand(text.substring(bodyStart, bodyEnd),
          offsets.sublist(bodyStart, bodyEnd), env, depth);
      out.write(part.text);
      outOffsets.addAll(part.offsets);
    }

    if (from <= to) {
      for (var v = from; v <= to; v += step) {
        iteration(v);
      }
    } else {
      for (var v = from; v >= to; v -= step) {
        iteration(v);
      }
    }
    return _Region(out.toString(), outOffsets, consumeTo);
  }

  double? _num(String s) => double.tryParse(s.trim());

  MacroText _evalFunction(String name, List<MacroText> values, int callOffset,
      _Env env, int depth) {
    final texts = [for (final v in values) v.text];
    String result;
    switch (name) {
      case 'CONCAT':
        result = texts.join();
      case 'QUOTE':
        result = texts.isEmpty ? "''" : "'${texts.join(' ')}'";
      case 'UNQUOTE':
        result = _unquote(texts.isEmpty ? '' : texts.join(' '));
      case 'UPCASE':
        result = (texts.isEmpty ? '' : texts.join(' ')).toUpperCase();
      case 'LENGTH':
        result = '${texts.isEmpty ? 0 : texts.join(' ').length}';
      case 'SUBSTR':
        final s = texts.isEmpty ? '' : texts[0];
        final start = texts.length > 1 ? (int.tryParse(texts[1]) ?? 1) : 1;
        final count = texts.length > 2 ? int.tryParse(texts[2]) : null;
        final a = (start - 1).clamp(0, s.length);
        final b = count == null ? s.length : (a + count).clamp(a, s.length);
        result = s.substring(a, b);
      case 'HEAD':
        final t = texts.isEmpty ? '' : texts.join(' ').trim();
        result = t.isEmpty ? '' : t.split(RegExp(r'\s+')).first;
      case 'TAIL':
        final t = texts.isEmpty ? '' : texts.join(' ').trim();
        final parts = t.isEmpty ? <String>[] : t.split(RegExp(r'\s+'));
        result = parts.length <= 1 ? '' : parts.sublist(1).join(' ');
      case 'INDEX':
        final hay = texts.isEmpty ? '' : texts[0];
        final needle = texts.length > 1 ? texts[1] : '';
        result = '${needle.isEmpty ? 0 : hay.indexOf(needle) + 1}';
      case 'EVAL':
        result = _evalArithmetic(texts.isEmpty ? '' : texts.join(' '));
      case 'NULL':
        result = '';
      case 'BLANKS':
        final n = texts.isEmpty ? 1 : (int.tryParse(texts[0]) ?? 1);
        result = ' ' * (n < 0 ? 0 : n);
      default:
        result = '';
    }
    return MacroText(result, List.filled(result.length, callOffset));
  }

  static String _unquote(String s) {
    final t = s.trim();
    if (t.length >= 2 &&
        ((t.startsWith("'") && t.endsWith("'")) ||
            (t.startsWith('"') && t.endsWith('"')))) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  /// `!EVAL` 的极简算术：`+ - * / ( )` 与数字。
  String _evalArithmetic(String expr) {
    final v = _arith(expr, [0]);
    return v == null ? expr.trim() : _fmtNum(v);
  }

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';

  double? _arith(String s, List<int> pos) {
    final parser = _ArithParser(s);
    final v = parser.parse();
    return parser.error ? null : v;
  }

  /// `!IF` 条件求值：比较 + `AND` / `OR` / `NOT`。
  bool _evalCondition(String cond) {
    final text = cond.trim();
    if (text.isEmpty) return false;
    final orParts = _splitLogic(text, r'\bOR\b|\|');
    if (orParts.length > 1) {
      return orParts.any(_evalCondition);
    }
    final andParts = _splitLogic(text, r'\bAND\b|&');
    if (andParts.length > 1) {
      return andParts.every(_evalCondition);
    }
    final notMatch =
        RegExp(r'^(NOT|~)\s*(.+)$', caseSensitive: false).firstMatch(text);
    if (notMatch != null) return !_evalCondition(notMatch.group(2)!);

    for (final op in ['<=', '>=', '<>', '~=', '=', '<', '>']) {
      final at = _topLevelIndexOf(text, op);
      if (at < 0) continue;
      final lhs = text.substring(0, at).trim();
      final rhs = text.substring(at + op.length).trim();
      final l = _unquote(lhs);
      final r = _unquote(rhs);
      final ln = double.tryParse(l);
      final rn = double.tryParse(r);
      final cmp = ln != null && rn != null ? ln.compareTo(rn) : l.compareTo(r);
      switch (op) {
        case '<=':
          return cmp <= 0;
        case '>=':
          return cmp >= 0;
        case '<>':
          return cmp != 0;
        case '~=':
          return cmp != 0;
        case '=':
          return cmp == 0;
        case '<':
          return cmp < 0;
        case '>':
          return cmp > 0;
      }
    }
    final single = _unquote(text);
    return single.isNotEmpty &&
        single != '0' &&
        single.toUpperCase() != 'FALSE';
  }

  static List<String> _splitLogic(String text, String pattern) {
    final re = RegExp('($pattern)', caseSensitive: false);
    final out = <String>[];
    var start = 0;
    var depth = 0;
    var inStr = false;
    var quote = '';
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inStr) {
        if (c == quote) inStr = false;
        continue;
      }
      if (c == "'" || c == '"') {
        inStr = true;
        quote = c;
        continue;
      }
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (depth != 0) continue;
      final m = re.matchAsPrefix(text, i);
      if (m != null) {
        out.add(text.substring(start, i));
        i += m.end - 1;
        start = i + 1;
      }
    }
    out.add(text.substring(start));
    return out;
  }

  static int _topLevelIndexOf(String text, String needle) {
    var depth = 0;
    var inStr = false;
    var quote = '';
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inStr) {
        if (c == quote) inStr = false;
        continue;
      }
      if (c == "'" || c == '"') {
        inStr = true;
        quote = c;
        continue;
      }
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (depth == 0 && text.startsWith(needle, i)) {
        if (needle == '<' && text.startsWith('<=', i)) continue;
        if (needle == '>' && text.startsWith('>=', i)) continue;
        return i;
      }
    }
    return -1;
  }
}

class _SpecValue {
  _SpecValue(this.value, this.next);

  final MacroText value;
  final int next;
}

class _Region {
  _Region(this.text, this.offsets, this.end);

  final String text;
  final List<int> offsets;
  final int end;
}

/// `!EVAL` 用的极小算术解析器（数字、`+ - * / ( )`）。
class _ArithParser {
  _ArithParser(this.src);

  final String src;
  int pos = 0;
  bool error = false;

  double parse() {
    final v = _expr();
    _ws();
    if (pos < src.length) error = true;
    return v;
  }

  double _expr() {
    var v = _term();
    while (true) {
      _ws();
      if (_eat('+')) {
        v += _term();
      } else if (_eat('-')) {
        v -= _term();
      } else {
        return v;
      }
    }
  }

  double _term() {
    var v = _factor();
    while (true) {
      _ws();
      if (_eat('*')) {
        v *= _factor();
      } else if (_eat('/')) {
        final d = _factor();
        v = d == 0 ? double.nan : v / d;
      } else {
        return v;
      }
    }
  }

  double _factor() {
    _ws();
    if (_eat('-')) return -_factor();
    if (_eat('+')) return _factor();
    if (_eat('(')) {
      final v = _expr();
      _ws();
      if (!_eat(')')) error = true;
      return v;
    }
    final start = pos;
    while (pos < src.length &&
        (RegExp(r'[0-9.]').hasMatch(src[pos]) ||
            src[pos] == 'e' ||
            src[pos] == 'E' ||
            ((src[pos] == '-' || src[pos] == '+') &&
                pos > start &&
                (src[pos - 1] == 'e' || src[pos - 1] == 'E')))) {
      pos++;
    }
    if (pos == start) {
      error = true;
      return 0;
    }
    return double.tryParse(src.substring(start, pos)) ?? 0;
  }

  void _ws() {
    while (pos < src.length && TextScan.isSpace(src[pos])) {
      pos++;
    }
  }

  bool _eat(String c) {
    if (pos < src.length && src[pos] == c) {
      pos++;
      return true;
    }
    return false;
  }
}

/// 语法预处理：注释剥离 + 宏展开 + 偏移映射 + 行列定位。
///
/// 注释语义对照 `_ref/pspp-2.1.2/doc/utilities.texi`（COMMENT 一节）：
/// - `*` / `COMMENT` 开头的整命令注释，到「行尾句点」或「空行」结束；
/// - 行内 `/* … */` 注释，到 `*/` 或行尾（先到者为准）；
///   整行只有这种注释时，该行视为空行并**结束当前命令**。
///
/// 预处理后每个字符都保留它在**原始源文本**里的偏移，因此命令定位、
/// 报错行列、编辑器跳转都用原始坐标，注释与宏展开不会让位置漂移。
library;

import 'syntax_macro.dart';

/// 预处理结果：`text[i]` 对应原始源文本偏移 `offsets[i]`。
class SyntaxSource {
  SyntaxSource({
    required this.source,
    required this.text,
    required this.offsets,
    this.issues = const <MacroIssue>[],
  }) {
    _computeLineStarts();
  }

  /// 原始用户输入。
  final String source;

  /// 去掉注释、展开宏之后的文本。
  final String text;

  /// `offsets.length == text.length`，值为原始源文本里的偏移。
  final List<int> offsets;

  /// 预处理期问题（宏未定义等），按发现顺序排列。
  final List<MacroIssue> issues;

  late final List<int> _lineStarts;

  bool get isEmpty => text.trim().isEmpty;

  /// 干净文本偏移 → 原始源文本偏移。
  int toSource(int cleanOffset) {
    if (offsets.isEmpty) return 0;
    if (cleanOffset <= 0) return offsets.first;
    if (cleanOffset >= offsets.length) return offsets.last + 1;
    return offsets[cleanOffset];
  }

  /// 干净文本区间 `[start, end)` → 原始源文本区间 `[start, end)`。
  (int, int) toSourceRange(int start, int end) {
    if (offsets.isEmpty) return (0, 0);
    final a = toSource(start);
    final b = end <= 0 ? a : toSource(end - 1) + 1;
    return (a, b < a ? a : b);
  }

  void _computeLineStarts() {
    final starts = <int>[0];
    for (var i = 0; i < source.length; i++) {
      final c = source[i];
      if (c == '\n') {
        starts.add(i + 1);
      } else if (c == '\r') {
        if (i + 1 < source.length && source[i + 1] == '\n') {
          // \r\n 视为一次换行，行首在 \n 之后
          continue;
        }
        starts.add(i + 1);
      }
    }
    _lineStarts = starts;
  }

  /// 原始偏移 → 1-based（行, 列）。列按字符计数，TAB 计 1 列。
  (int, int) lineColumn(int sourceOffset) {
    var lo = 0;
    var hi = _lineStarts.length - 1;
    final at = sourceOffset.clamp(0, source.length);
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_lineStarts[mid] <= at) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return (lo + 1, at - _lineStarts[lo] + 1);
  }

  /// 1-based 行号的整行文本（不含行尾换行符）。
  String lineText(int line) {
    if (line < 1 || line > _lineStarts.length) return '';
    final start = _lineStarts[line - 1];
    var end = line < _lineStarts.length ? _lineStarts[line] : source.length;
    while (end > start &&
        (source[end - 1] == '\n' || source[end - 1] == '\r')) {
      end--;
    }
    return source.substring(start, end);
  }

  /// 1-based 行号的行首偏移。
  int lineStartOffset(int line) {
    if (line < 1) return 0;
    if (line > _lineStarts.length) return source.length;
    return _lineStarts[line - 1];
  }

  int get lineCount => _lineStarts.length;
}

class _Stripped {
  _Stripped(this.text, this.offsets);
  final String text;
  final List<int> offsets;
}

/// 预处理入口。
class SyntaxPreprocessor {
  /// 剥离注释并展开宏。[macros] 可跨多次调用共享（`INCLUDE` 时宏表要延续）；
  /// [commandVerbs] 用于识别「注释吞掉了后续命令」并给出提示（可空）。
  ///
  /// [offsetShift] / [fullSource] 用于「整份文件分几次预处理」：
  /// 传入的是文件的某一段（`source`），结果里的偏移平移 [offsetShift] 后
  /// 仍然指向整份文件，行列也按 [fullSource] 计算。
  static SyntaxSource process(
    String source, {
    MacroTable? macros,
    List<MacroIssue>? issues,
    Set<String> commandVerbs = const <String>{},
    int offsetShift = 0,
    String? fullSource,
  }) {
    final table = macros ?? MacroTable();
    final found = issues ?? <MacroIssue>[];
    final firstIssue = found.length;
    final stripped = _stripComments(source, found, commandVerbs);
    var offsets = stripped.offsets;
    if (offsetShift != 0) {
      for (var k = firstIssue; k < found.length; k++) {
        found[k] = found[k].shifted(offsetShift);
      }
      offsets = [for (final o in offsets) o + offsetShift];
    }
    final defsRemoved = MacroDefs.extract(stripped.text, offsets, table, found);
    final expanded = MacroExpander(table, issues: found)
        .expandTopLevel(defsRemoved.text, defsRemoved.offsets);
    return SyntaxSource(
      source: fullSource ?? source,
      text: expanded.text,
      offsets: expanded.offsets,
      issues: found,
    );
  }
}

bool _isSpace(String c) =>
    c == ' ' || c == '\t' || c == '\n' || c == '\r';

int _lineStartOf(String s, int at) {
  var i = at;
  while (i > 0 && s[i - 1] != '\n' && s[i - 1] != '\r') {
    i--;
  }
  return i;
}

int _lineEndOf(String s, int at) {
  var i = at;
  while (i < s.length && s[i] != '\n' && s[i] != '\r') {
    i++;
  }
  return i;
}

/// `/*` 注释的结束位置：`*/` 之后，或行尾（先到者为准）。
int _blockCommentEnd(String s, int at) {
  final lineEnd = _lineEndOf(s, at);
  final close = s.indexOf('*/', at + 2);
  if (close >= 0 && close + 2 <= lineEnd) return close + 2;
  return lineEnd;
}

/// `*` / `COMMENT` 整命令注释的结束位置：返回（结束偏移, 是否正常结束）。
///
/// 正常结束 = 命中「行尾句点」或「空行」；返回 `ended == false` 表示
/// 一路读到文件末尾（注释没写完）。
(int, bool) _commentCommandEnd(String s, int at) {
  var lineStart = _lineStartOf(s, at);
  while (true) {
    final lineEnd = _lineEndOf(s, lineStart);
    var last = lineEnd;
    while (last > lineStart && (s[last - 1] == ' ' || s[last - 1] == '\t')) {
      last--;
    }
    if (last > lineStart && s[last - 1] == '.') return (last, true);
    var blank = true;
    for (var k = lineStart; k < lineEnd; k++) {
      if (!_isSpace(s[k])) {
        blank = false;
        break;
      }
    }
    if (blank) return (lineStart, true);
    if (lineEnd >= s.length) return (s.length, false);
    var next = lineEnd + 1;
    if (s[lineEnd] == '\r' && next < s.length && s[next] == '\n') next++;
    lineStart = next;
  }
}

/// 注释 `[from, to)` 里是否吞掉了看起来像命令的行；返回该行文本（截断）。
String? _swallowedCommand(String s, int from, int to, Set<String> verbs) {
  var lineStart = _lineEndOf(s, from);
  if (lineStart < s.length) lineStart++;
  while (lineStart < to) {
    final lineEnd = _lineEndOf(s, lineStart);
    final text = s.substring(lineStart, lineEnd).trim();
    if (text.isNotEmpty) {
      final token = RegExp(r'^\S+').firstMatch(text)!.group(0)!;
      // 去掉命令末尾的句点等标点：`LIST.` → `LIST`
      final verb = token.split(RegExp(r'[^\w\-]')).first.toUpperCase();
      if (verb.isNotEmpty && verbs.contains(verb)) {
        return text.length > 40 ? '${text.substring(0, 40)}…' : text;
      }
    }
    if (lineEnd >= s.length) break;
    lineStart = lineEnd + 1;
  }
  return null;
}

bool _matchesCommentKeyword(String s, int at) {
  const keyword = 'COMMENT';
  if (at + keyword.length > s.length) return false;
  if (s.substring(at, at + keyword.length).toUpperCase() != keyword) {
    return false;
  }
  final after = at + keyword.length;
  if (after >= s.length) return true;
  final c = s[after];
  return c != '_' && !_isWordLike(c);
}

bool _isWordLike(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 48 && u <= 57) ||
      (u >= 65 && u <= 90) ||
      (u >= 97 && u <= 122);
}

/// 单趟扫描：去注释、保持偏移、必要时补命令终止符。
_Stripped _stripComments(
    String source, List<MacroIssue> issues, Set<String> commandVerbs) {
  final out = StringBuffer();
  final offsets = <int>[];
  var i = 0;
  var inStr = false;
  var quote = '';
  // 当前命令缓冲区是否只有空白（决定 `*` / `COMMENT` 是否算注释命令）
  var cmdBlank = true;

  void put(int index) {
    final c = source[index];
    out.write(c);
    offsets.add(index);
    if (c == '.') {
      cmdBlank = true;
    } else if (!_isSpace(c)) {
      cmdBlank = false;
    }
  }

  while (i < source.length) {
    final c = source[i];

    if (inStr) {
      put(i);
      cmdBlank = false;
      if (c == quote) inStr = false;
      i++;
      continue;
    }

    if (c == "'" || c == '"') {
      inStr = true;
      quote = c;
      put(i);
      cmdBlank = false;
      i++;
      continue;
    }

    // 行内 /* … */ 注释
    if (c == '/' && i + 1 < source.length && source[i + 1] == '*') {
      final lineStart = _lineStartOf(source, i);
      final lineEnd = _lineEndOf(source, i);
      var onlyComment = true;
      var k = lineStart;
      while (k < lineEnd) {
        if (source.startsWith('/*', k)) {
          k = _blockCommentEnd(source, k);
          continue;
        }
        if (!_isSpace(source[k])) {
          onlyComment = false;
          break;
        }
        k++;
      }
      if (onlyComment) {
        // 整行只有注释 → 视为空行，并结束当前命令（PSPP semantic）
        if (!cmdBlank) {
          out.write('.');
          offsets.add(lineStart);
          cmdBlank = true;
        }
        i = lineEnd;
        continue;
      }
      i = _blockCommentEnd(source, i);
      continue;
    }

    // `*` / `COMMENT` 整命令注释
    if (cmdBlank && (c == '*' || _matchesCommentKeyword(source, i))) {
      final (end, ended) = _commentCommandEnd(source, i);
      if (!ended) {
        issues.add(MacroIssue(MacroIssueKind.unterminatedComment, '', i));
      } else if (commandVerbs.isNotEmpty && end > _lineEndOf(source, i)) {
        final detail = _swallowedCommand(source, i, end, commandVerbs);
        if (detail != null) {
          issues.add(MacroIssue(MacroIssueKind.swallowedCommand, detail, i));
        }
      }
      i = end;
      cmdBlank = true;
      continue;
    }

    put(i);
    i++;
  }

  return _Stripped(out.toString(), offsets);
}

/// SPSS 风格语法高亮控制器（零依赖，基于 TextEditingController.buildTextSpan）
library;

import 'package:flutter/material.dart';

import '../../core/syntax/syntax_engine.dart';

/// 行首命令字：动词表直接取执行器**已实现**的动词，避免高亮与引擎漂移；
/// 再补上两个「行首构造」（宏定义与 COMMENT 注释）。
final _commands = <String>{
  ...implementedVerbs,
  'DEFINE',
  'COMMENT',
};

/// 行内子命令 / 逻辑关键字
const _keywords = {
  'BY', 'WITH', 'INTO', 'FROM', 'TO', 'ALL', 'AND', 'OR', 'NOT', 'ELSE',
  'TESTVAL', 'VARIABLES', 'PAIRED', 'MISSING', 'OPTIONS', 'STATISTICS',
  'FILES', 'TABLE', 'GROUP', 'BY=', 'VARIABLES=',
};

/// 宏名 / 宏函数（`!NAME`）的颜色（两种主题下都可读）
const macroHighlightColor = Color(0xFF8E44AD);

class SyntaxHighlightController extends TextEditingController {
  SyntaxHighlightController({super.text});

  /// 行首命令字：单个记号（`T-TEST` 这类连字符算同一个记号），
  /// 后面可以跟空白、`.`、`/` 或行尾。
  static final _cmdRe =
      RegExp(r'^\s*([A-Za-z][A-Za-z0-9\-_]*)(?=\s|\.|/|$)');

  /// `COMMENT` 开头的注释行
  static final _commentRe = RegExp(r'^COMMENT(\s|\.|$)', caseSensitive: false);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final base = style ?? const TextStyle();
    final children = <TextSpan>[];

    final cmdStyle = base.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w700,
    );
    final kwStyle = base.copyWith(color: scheme.tertiary);
    final numStyle = base.copyWith(color: scheme.secondary);
    final strStyle = base.copyWith(color: const Color(0xFF2E9E5B));
    final macroStyle = base.copyWith(color: macroHighlightColor);
    final commentStyle = base.copyWith(
      color: scheme.outline,
      fontStyle: FontStyle.italic,
    );

    for (final line in text.split('\n')) {
      final trimmed = line.trimLeft();
      // 注释行：`* …`（`*.` 除外，那是乘法）或 `/* … */`
      if ((trimmed.startsWith('*') && !trimmed.startsWith('*.')) ||
          trimmed.startsWith('/*') ||
          _commentRe.hasMatch(trimmed)) {
        children.add(TextSpan(text: '$line\n', style: commentStyle));
        continue;
      }
      var rest = line;
      // 行首命令字
      final cmdMatch = _cmdRe.firstMatch(line);
      if (cmdMatch != null) {
        final cand = cmdMatch.group(1)!.toUpperCase();
        if (_commands.contains(cand)) {
          final idx = line.indexOf(cmdMatch.group(1)!, cmdMatch.start);
          if (idx > 0) {
            children.add(TextSpan(text: line.substring(0, idx), style: base));
          }
          children.add(TextSpan(text: line.substring(idx, idx + cand.length),
              style: cmdStyle));
          rest = line.substring(idx + cand.length);
        }
      }
      _highlightRest(rest, base, kwStyle, numStyle, strStyle, macroStyle,
          commentStyle, children);
      children.add(const TextSpan(text: '\n'));
    }
    // split('\n') 会让最后一行多出一个换行；若原文不以 \n 结尾则去掉
    if (children.isNotEmpty && !text.endsWith('\n')) {
      final last = children.last;
      if (last.text == '\n') {
        children.removeLast();
      } else if (last.text != null && last.text!.endsWith('\n')) {
        children[children.length - 1] =
            TextSpan(text: last.text!.substring(0, last.text!.length - 1),
                style: last.style);
      }
    }
    return TextSpan(style: base, children: children);
  }

  void _highlightRest(
    String s,
    TextStyle base,
    TextStyle kwStyle,
    TextStyle numStyle,
    TextStyle strStyle,
    TextStyle macroStyle,
    TextStyle commentStyle,
    List<TextSpan> out,
  ) {
    final buf = StringBuffer();
    var i = 0;
    void flush() {
      if (buf.isEmpty) return;
      final word = buf.toString();
      TextStyle st = base;
      if (word.startsWith('!')) {
        st = macroStyle;
      } else if (_keywords.contains(word.toUpperCase())) {
        st = kwStyle;
      } else if (double.tryParse(word) != null) {
        st = numStyle;
      }
      out.add(TextSpan(text: word, style: st));
      buf.clear();
    }

    while (i < s.length) {
      final ch = s[i];
      if (ch == "'" || ch == '"') {
        flush();
        final quote = ch;
        final start = i;
        i++;
        while (i < s.length && s[i] != quote) {
          i++;
        }
        if (i < s.length) i++;
        out.add(TextSpan(text: s.substring(start, i), style: strStyle));
        continue;
      }
      // 行内块注释：/* … */（到行尾结束也算）
      if (ch == '/' && i + 1 < s.length && s[i + 1] == '*') {
        flush();
        final close = s.indexOf('*/', i + 2);
        final end = close < 0 ? s.length : close + 2;
        out.add(TextSpan(text: s.substring(i, end), style: commentStyle));
        i = end;
        continue;
      }
      if (RegExp(r'[A-Za-z0-9_.!]').hasMatch(ch)) {
        buf.write(ch);
      } else {
        flush();
        out.add(TextSpan(text: ch, style: base));
      }
      i++;
    }
    flush();
  }
}

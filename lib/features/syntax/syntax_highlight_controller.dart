/// SPSS 风格语法高亮控制器（零依赖，基于 TextEditingController.buildTextSpan）
library;

import 'package:flutter/material.dart';

/// 语句起始命令关键字
const _commands = {
  'DESCRIPTIVES', 'FREQUENCIES', 'T-TEST', 'CORRELATIONS', 'COMPUTE',
  'RECODE', 'RANK', 'SORT', 'SORT CASES', 'SELECT IF', 'LIST', 'HELP',
  'WEIGHT', 'WEIGHT BY', 'SPLIT FILE', 'VALUE LABELS', 'VARIABLE LABELS',
  'MEANS', 'ONEWAY', 'EXAMINE', 'REGRESSION', 'LOGISTIC REGRESSION',
  'CROSSTABS', 'NPAR TESTS', 'AGGREGATE', 'COUNT', 'AUTORECODE',
  'MATCH FILES', 'ADD FILES', 'GET', 'SAVE', 'TEMPORARY', 'DO IF',
  'END IF', 'LOOP', 'END LOOP', 'VECTOR', 'IF', 'BREAK',
};

/// 行内子命令 / 逻辑关键字
const _keywords = {
  'BY', 'WITH', 'INTO', 'FROM', 'TO', 'ALL', 'AND', 'OR', 'NOT', 'ELSE',
  'TESTVAL', 'VARIABLES', 'PAIRED', 'MISSING', 'OPTIONS', 'STATISTICS',
  'ES', 'CRITERIA', 'MISSING=',
};

class SyntaxHighlightController extends TextEditingController {
  SyntaxHighlightController({super.text});

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
    final commentStyle = base.copyWith(
      color: scheme.outline,
      fontStyle: FontStyle.italic,
    );

    for (final line in text.split('\n')) {
      final trimmed = line.trimLeft();
      // 注释行：* 开头
      if (trimmed.startsWith('*') && !trimmed.startsWith('*.')) {
        children.add(TextSpan(text: '$line\n', style: commentStyle));
        continue;
      }
      var rest = line;
      // 行首命令字
      final cmdMatch =
          RegExp(r'^\s*([A-Z][A-Z0-9\- ]*[A-Z0-9])(?=\s|$)').firstMatch(line);
      if (cmdMatch != null) {
        final cand = cmdMatch.group(1)!.trim();
        if (_commands.contains(cand)) {
          final idx = line.indexOf(cand);
          if (idx > 0) {
            children.add(TextSpan(text: line.substring(0, idx), style: base));
          }
          children.add(TextSpan(text: cand, style: cmdStyle));
          rest = line.substring(idx + cand.length);
        }
      }
      _highlightRest(rest, base, kwStyle, numStyle, strStyle, children);
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
    List<TextSpan> out,
  ) {
    final buf = StringBuffer();
    var i = 0;
    void flush() {
      if (buf.isEmpty) return;
      final word = buf.toString();
      TextStyle st = base;
      if (_keywords.contains(word)) {
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
      if (RegExp(r'[A-Za-z0-9_.]').hasMatch(ch)) {
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

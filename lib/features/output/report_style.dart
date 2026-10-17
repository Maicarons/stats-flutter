/// 报告表样式逻辑（v1.5.0 M4.3）：数值列判定、p 值解析、显著性星号。
///
/// 四个输出端共用同一份：屏幕报告（`analysis_runner.dart`）、HTML / Markdown
/// （`report_export.dart`）、PDF（`report_pdf.dart`）。星号口径直接取 statkit 的
/// [significanceStars]，不再各写一遍。
library;

import 'package:statkit/statkit.dart';

import 'report_builder.dart';

/// p 值列表头（`p` / `p值` / `Sig.` / `显著性`）。
final RegExp pHeaderRe = RegExp(r'^(p\b|p值|sig\.?\b|显著性)', caseSensitive: false);

/// 单元格形如 `0.62 **`（相关系数表自带星号）时拆出尾随星号。
final RegExp trailingStarsRe = RegExp(r'^(.*?)\s*(\*{1,3})$');

/// 单元格是否是一个数：接受 `1,204` / `12.5%` / `<.001` / `.023`（SPSS 风格，
/// 见 statkit 的 `formatP`）/ `1.2e-05`；相关系数那种自带的尾随星号不参与判定。
bool isNumericCell(String raw) {
  var t = raw.trim();
  if (t.isEmpty) return false;
  final m = trailingStarsRe.firstMatch(t);
  if (m != null) t = m.group(1)!.trim();
  t = t.replaceAll(RegExp(r'^[<≤>≥]'), '').trim();
  if (t.endsWith('%')) t = t.substring(0, t.length - 1).trim();
  if (t.isEmpty) return false;
  t = t.replaceAll(',', '');
  if (t.startsWith('.')) t = '0$t';
  if (t.startsWith('-.')) t = '-0${t.substring(1)}';
  final v = double.tryParse(t);
  return v != null && v.isFinite;
}

/// 由星号反推 p 值（仅用于配色；星号本身才是权威信息）。
double pForStars(String stars) => switch (stars.length) {
      >= 3 => 0.0005,
      2 => 0.005,
      _ => 0.03,
    };

/// 解析 p 值文本：`.023` / `<.001` / `0.023`；`<x` 取 x 的一半（保守估计）。
double? parseP(String s) {
  final t = s.trim();
  if (t.isEmpty || t == '—' || t == '-') return null;
  if (t.startsWith('<') || t.startsWith('≤')) {
    final v = _toDouble(t.substring(1).trim());
    return v == null ? null : v / 2;
  }
  return _toDouble(t);
}

double? _toDouble(String t) {
  final v = t.startsWith('.') ? '0$t' : t;
  return double.tryParse(v.replaceAll(',', ''));
}

/// 一张表的列属性：哪些列是数值列、哪些列是 p 值列（构建一次，逐格复用）。
class ReportTableStyle {
  ReportTableStyle._(this.numeric, this.isP);

  factory ReportTableStyle.of(ReportTable t) {
    final cols = t.headers.length;
    final numeric = <bool>[
      for (var c = 0; c < cols; c++)
        c > 0 &&
            t.rows.any((r) => c < r.length && r[c].trim().isNotEmpty) &&
            t.rows
                .where((r) => c < r.length && r[c].trim().isNotEmpty)
                .every((r) => isNumericCell(r[c])),
    ];
    final isP = <bool>[
      for (final h in t.headers) pHeaderRe.hasMatch(h.trim()),
    ];
    return ReportTableStyle._(numeric, isP);
  }

  final List<bool> numeric;
  final List<bool> isP;

  int get columns => numeric.length;

  bool numericAt(int c) => c > 0 && c < numeric.length && numeric[c];

  bool isPAt(int c) => c < isP.length && isP[c];
}

/// 一个单元格渲染需要的信息。
class ReportCellStyle {
  const ReportCellStyle({
    required this.label,
    this.stars = '',
    this.p,
    this.numeric = false,
  });

  /// 去掉尾随星号后的显示文本。
  final String label;

  /// `''` / `'*'` / `'**'` / `'***'`。
  final String stars;

  /// 用于配色的 p 值（可能由星号反推）。
  final double? p;

  final bool numeric;

  bool get significant => stars.isNotEmpty;
}

/// 表头单元格。
ReportCellStyle styleHeaderCell(ReportTableStyle s, String text, int col) =>
    ReportCellStyle(label: text, numeric: s.numericAt(col));

/// 数据单元格：p 值列按 p 值加星；其它列接受单元格自带的尾随星号。
ReportCellStyle styleBodyCell(ReportTableStyle s, String raw, int col) {
  final text = raw.trim();
  if (text.isEmpty) return ReportCellStyle(label: raw, numeric: s.numericAt(col));
  if (s.isPAt(col)) {
    final p = parseP(text);
    if (p != null) {
      return ReportCellStyle(
        label: raw,
        stars: significanceStars(p),
        p: p,
        numeric: s.numericAt(col),
      );
    }
    return ReportCellStyle(label: raw, numeric: s.numericAt(col));
  }
  final m = trailingStarsRe.firstMatch(text);
  if (m != null && m.group(1)!.trim().isNotEmpty) {
    final stars = m.group(2)!;
    return ReportCellStyle(
      label: m.group(1)!.trim(),
      stars: stars,
      p: pForStars(stars),
      numeric: s.numericAt(col),
    );
  }
  return ReportCellStyle(label: raw, numeric: s.numericAt(col));
}

/// 报告 PDF 导出（v1.5.0 M4.2）：纯 Dart 渲染（`pdf` 包），中文字体随包。
///
/// 与屏幕报告、HTML 导出共用同一套表格样式判定（`report_style.dart`）：
/// 数值列右对齐、p 值列按显著性着色并带星号、脚注灰底卡片。
///
/// 中文字形来自 `assets/fonts/StatsSansSC-Regular.ttf`（Noto Sans SC 子集，
/// 见 `tools/subset_cjk_font.py` 与同目录 OFL 声明）；拉丁/数字继续用 Inter。
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_builder.dart';
import 'report_style.dart';

// ---------------------------------------------------------------- 配色

/// 语义色，对应 `design_tokens.dart` 浅色主题（PDF 一律印在白底上）。
const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1A);
const PdfColor _inkSoft = PdfColor.fromInt(0xFF5F6368);
const PdfColor _accent = PdfColor.fromInt(0xFF1565C0); // 正向 / 强调
const PdfColor _significance = PdfColor.fromInt(0xFFB4530A); // p < .05
const PdfColor _line = PdfColor.fromInt(0xFFDADCE0);
const PdfColor _headerFill = PdfColor.fromInt(0xFFF1F3F4);
const PdfColor _zebra = PdfColor.fromInt(0xFFFAFBFC);

// ---------------------------------------------------------------- 字体

/// PDF 用字体集合：拉丁/数字 Inter，中文 StatsSansSC 子集。
class ReportFonts {
  ReportFonts({
    required this.regular,
    required this.bold,
    required this.cjk,
  });

  final Uint8List regular;
  final Uint8List bold;
  final Uint8List cjk;

  static ReportFonts? _cache;

  /// 从 asset bundle 载入；首次读盘后缓存（字体约 2.4 MB，只读一次）。
  static Future<ReportFonts> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    Future<Uint8List> read(String key) async =>
        (await rootBundle.load(key)).buffer.asUint8List();
    final fonts = ReportFonts(
      regular: await read('assets/fonts/Inter-Regular.ttf'),
      bold: await read('assets/fonts/Inter-Bold.ttf'),
      cjk: await read('assets/fonts/StatsSansSC-Regular.ttf'),
    );
    _cache = fonts;
    return fonts;
  }

  /// 供测试注入字节。
  pw.ThemeData get theme {
    final base = pw.Font.ttf(regular.buffer.asByteData());
    final cjkFont = pw.Font.ttf(cjk.buffer.asByteData());
    return pw.ThemeData.withFont(
      base: base,
      bold: pw.Font.ttf(bold.buffer.asByteData()),
      // 中文不在 Inter 里，缺字时回退到子集字体（粗体同样回退）
      fontFallback: [cjkFont],
    );
  }
}

// ---------------------------------------------------------------- 入口

/// 把报告渲染为 PDF 字节。
///
/// [title] 覆盖报告标题；[pageLabel] 自定义页脚页码（默认 `Page 1 / 3`）；
/// [footerNote] 是页脚左侧的一行补充说明。
Future<Uint8List> reportToPdf(
  AnalysisReport report, {
  required ReportFonts fonts,
  String? title,
  String Function(int page, int total)? pageLabel,
  String? footerNote,
}) async {
  final theme = fonts.theme;
  final heading = title ?? report.title;
  final pageText = pageLabel ?? (p, t) => 'Page $p / $t';
  final stamp = _stamp(report.createdAt);

  final doc = pw.Document(
    title: heading,
    author: 'Stats-flutter',
    creator: 'Stats-flutter',
    producer: 'pdf (Dart)',
  );

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(46, 40, 46, 42),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(bottom: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _line, width: .6),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    heading,
                    style: const pw.TextStyle(fontSize: 8, color: _inkSoft),
                  ),
                  if (report.subtitle.isNotEmpty)
                    pw.Text(
                      report.subtitle,
                      style: const pw.TextStyle(fontSize: 8, color: _inkSoft),
                    ),
                ],
              ),
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line, width: .6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              footerNote ?? stamp,
              style: const pw.TextStyle(fontSize: 7.6, color: _inkSoft),
            ),
            pw.Text(
              pageText(ctx.pageNumber, ctx.pagesCount),
              style: const pw.TextStyle(fontSize: 7.6, color: _inkSoft),
            ),
          ],
        ),
      ),
      build: (ctx) => [
        _masthead(report, heading, stamp),
        for (final section in report.sections) ...[
          _heading(section.heading),
          if (section.body != null && section.body!.trim().isNotEmpty)
            pw.Text(
              section.body!.trim(),
              style: const pw.TextStyle(
                fontSize: 9.6,
                color: _ink,
                lineSpacing: 2,
              ),
            ),
          for (final table in section.tables) ...[
            if (_hasCaption(table)) ...[
              pw.SizedBox(height: 6),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  table.caption!.trim(),
                  style: pw.TextStyle(
                    fontSize: 9.4,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
            ] else
              pw.SizedBox(height: 8),
            // 表格直接挂在 MultiPage 下：`Table` 支持跨页拆分并重复表头
            // （包进 Column 会失去该能力，行多时直接 TooManyPagesException）。
            _table(table),
          ],
          if (section.notes != null && section.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _note(section.notes!.trim()),
          ],
        ],
        pw.SizedBox(height: 12),
      ],
    ),
  );

  return doc.save();
}

// ---------------------------------------------------------------- 版块

String _stamp(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

pw.Widget _masthead(AnalysisReport report, String heading, String stamp) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (report.subtitle.isNotEmpty)
          pw.Text(
            report.subtitle,
            style: const pw.TextStyle(
              fontSize: 9,
              color: _inkSoft,
              letterSpacing: .4,
            ),
          ),
        pw.SizedBox(height: 2),
        pw.Text(
          heading,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.Container(
          height: 2.4,
          width: 48,
          margin: const pw.EdgeInsets.only(top: 6),
          color: _accent,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          stamp,
          style: const pw.TextStyle(fontSize: 8.5, color: _inkSoft),
        ),
      ],
    );

pw.Widget _heading(String text) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Container(
            height: 1.2,
            width: 28,
            margin: const pw.EdgeInsets.only(top: 3),
            color: _accent,
          ),
        ],
      ),
    );

pw.Widget _note(String text) => pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: _zebra,
        border: pw.Border.all(color: _line, width: .6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 8.4,
          color: _inkSoft,
          lineSpacing: 1.6,
        ),
      ),
    );

// ---------------------------------------------------------------- 表格

/// 表题存在且表格不止一列时才算标题（单列表格的头往往就是表题）。
bool _hasCaption(ReportTable table) =>
    table.caption != null &&
    table.caption!.trim().isNotEmpty &&
    table.headers.length > 1;

/// 表格本体。**必须**作为 MultiPage 的直接子项返回，才能跨页拆分。
pw.Widget _table(ReportTable table) {
  final style = ReportTableStyle.of(table);
  final cols = table.headers.length;
  final data = <List<String>>[
    for (final row in table.rows)
      [for (var c = 0; c < cols; c++) c < row.length ? row[c] : ''],
  ];

  return pw.TableHelper.fromTextArray(
    headers: table.headers,
    data: data,
    headerAlignment: pw.Alignment.centerLeft,
    headerStyle: pw.TextStyle(
      fontSize: 8.6,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    ),
    headerDecoration: const pw.BoxDecoration(color: _headerFill),
    headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.4),
    border: pw.TableBorder.all(color: _line, width: .5),
    oddRowDecoration: const pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      for (var c = 0; c < cols; c++)
        if (style.numericAt(c)) c: pw.Alignment.centerRight,
    },
    columnWidths: {
      0: const pw.FlexColumnWidth(2.4),
      for (var c = 1; c < cols; c++)
        if (style.numericAt(c)) c: const pw.FlexColumnWidth(1.1),
    },
    cellBuilder: (col, value, rowNum) {
      final cell = styleBodyCell(style, value.toString(), col);
      if (cell.stars.isEmpty && cell.label.trim().isEmpty) {
        return pw.SizedBox();
      }
      return pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            cell.label.trim(),
            style: pw.TextStyle(
              fontSize: 8.6,
              color: cell.significant ? _significance : _ink,
            ),
          ),
          if (cell.stars.isNotEmpty)
            pw.Text(
              ' ${cell.stars}',
              style: pw.TextStyle(
                fontSize: 8.6,
                fontWeight: pw.FontWeight.bold,
                color: _significance,
              ),
            ),
        ],
      );
    },
  );
}

/// 报告导出菜单与落地（v1.5.0 M4.1）：复制 / 分享 / HTML / Markdown / PDF。
///
/// 三份导出共用 `report_export.dart`（HTML/MD）与 `report_pdf.dart`（PDF），
/// 走同一套「写文档目录 → 系统分享」路径（与 v1.3 的 `_exportHtml` 一致）。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import 'report_builder.dart';
import 'report_export.dart';
import 'report_pdf.dart';

enum ReportFileKind {
  html('html'),
  markdown('md'),
  pdf('pdf');

  const ReportFileKind(this.extension);

  final String extension;
}

/// 导出文件名基名：`stats-报告标题-20261017`；标题是纯中文时回退 `stats-report-…`。
String reportFileBase(String title, {DateTime? at}) {
  final d = at ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final slug = fileSafeSlug(title);
  return [
    'stats',
    slug.isEmpty ? 'report' : slug,
    '${d.year}${two(d.month)}${two(d.day)}',
  ].join('-');
}

/// 写文件 + 调起系统分享。[nameBase] 缺省用 [reportFileBase]（纯中文标题时
/// 调用方传分析 id，避免文件名退化成 `stats-report-…` 都一样）。
///
/// PDF 要解析 2.3 MB 中文字体资产再排版（数百毫秒起），期间给一条进度提示，
/// 否则点了菜单像是没反应。
Future<void> exportReportFile(
  BuildContext context, {
  required AnalysisReport report,
  required ReportFileKind kind,
  String? nameBase,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final base = nameBase ?? reportFileBase(report.title);
  final showProgress = kind == ReportFileKind.pdf;
  if (showProgress) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.exporting),
        duration: const Duration(minutes: 1),
      ),
    );
  }
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$base.${kind.extension}');
    switch (kind) {
      case ReportFileKind.html:
        await file.writeAsString(reportToHtml(report, title: report.title));
      case ReportFileKind.markdown:
        await file.writeAsString(reportToMarkdown(report));
      case ReportFileKind.pdf:
        final fonts = await ReportFonts.load();
        final bytes = await reportToPdf(
          report,
          fonts: fonts,
          pageLabel: l10n.pdfPageOf,
          footerNote: l10n.pdfFooterNote,
        );
        await file.writeAsBytes(bytes, flush: true);
    }
    if (showProgress) messenger.hideCurrentSnackBar();
    await Share.shareXFiles([XFile(file.path)], subject: report.title);
  } catch (e) {
    if (showProgress) messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.exportFailed(e.toString()))),
    );
  }
}

/// 复制纯文本报告。
Future<void> copyReportText(BuildContext context, AnalysisReport report) async {
  final l10n = AppLocalizations.of(context);
  await Clipboard.setData(ClipboardData(text: report.toPlainText()));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.copiedToClipboard),
      duration: const Duration(milliseconds: 1200),
    ),
  );
}

/// 分享纯文本报告。
Future<void> shareReportText(BuildContext context, AnalysisReport report) =>
    Share.share(report.toPlainText(), subject: report.title);

/// 单份报告的导出菜单（输出树每张卡片右上角）。
class ReportExportMenu extends StatelessWidget {
  final AnalysisReport report;

  /// 导出文件名基名（见 [exportReportFile]）。
  final String? nameBase;

  const ReportExportMenu({
    super.key,
    required this.report,
    this.nameBase,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: l10n.exportReport,
      iconSize: 18,
      color: scheme.surface,
      icon: Icon(Icons.ios_share, color: scheme.onSurfaceVariant),
      onSelected: (v) {
        switch (v) {
          case 'copy':
            copyReportText(context, report);
          case 'share':
            shareReportText(context, report);
          case 'html':
            exportReportFile(
              context,
              report: report,
              kind: ReportFileKind.html,
              nameBase: nameBase,
            );
          case 'md':
            exportReportFile(
              context,
              report: report,
              kind: ReportFileKind.markdown,
              nameBase: nameBase,
            );
          case 'pdf':
            exportReportFile(
              context,
              report: report,
              kind: ReportFileKind.pdf,
              nameBase: nameBase,
            );
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'copy', child: Text(l10n.copyReport)),
        PopupMenuItem(value: 'share', child: Text(l10n.shareReport)),
        PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
        PopupMenuItem(value: 'html', child: Text(l10n.exportHtml)),
        PopupMenuItem(value: 'md', child: Text(l10n.exportMarkdown)),
      ],
    );
  }
}

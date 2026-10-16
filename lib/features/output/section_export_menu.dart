/// 报告分区导出菜单：复制 Markdown / 导出 Markdown / 导出 HTML。
///
/// 与整份报告导出共用同一套 `sectionToMarkdown` / `sectionToHtml` 与
/// `share_plus` 路径，只是范围缩小到单个分区，文件名形如
/// `stats-报告名-分区标题-20261015.md`。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import 'report_builder.dart';
import 'report_export.dart';

class SectionExportMenu extends StatelessWidget {
  final ReportSection section;

  /// 所属报告标题（分区导出的 H1 与文件名的一部分）。
  final String reportTitle;

  /// 分区序号（纯中文标题回退为 `section-N`）。
  final int index;

  const SectionExportMenu({
    super.key,
    required this.section,
    required this.reportTitle,
    required this.index,
  });

  /// 复制本节 Markdown（与导出同一份内容）。
  Future<void> copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: sectionToMarkdown(section, reportTitle: reportTitle)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  /// 本节导出文件名（含扩展名）。
  String fileName({required bool html}) => '${sectionFileBase(
        reportTitle: reportTitle,
        section: section,
        index: index,
      )}.${html ? 'html' : 'md'}';

  /// 本节导出内容。
  String content({required bool html}) => html
      ? sectionToHtml(section, reportTitle: reportTitle)
      : sectionToMarkdown(section, reportTitle: reportTitle);

  /// 单独导出本节：写入文档目录后走系统分享。
  Future<void> export(BuildContext context, {required bool html}) async {
    final l10n = AppLocalizations.of(context);
    final name = fileName(html: html);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$name');
      await f.writeAsString(content(html: html));
      await Share.shareXFiles(
        [XFile(f.path)],
        subject: '$reportTitle — ${section.heading}',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sectionExported(name)),
          duration: const Duration(milliseconds: 1600),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: l10n.exportSection,
      iconSize: 18,
      color: scheme.surface,
      icon: Icon(Icons.copy_all_outlined, color: scheme.onSurfaceVariant),
      onSelected: (v) {
        switch (v) {
          case 'copy':
            copy(context);
          case 'md':
            export(context, html: false);
          case 'html':
            export(context, html: true);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'copy', child: Text(l10n.copySection)),
        PopupMenuItem(value: 'md', child: Text(l10n.exportSectionMarkdown)),
        PopupMenuItem(value: 'html', child: Text(l10n.exportSectionHtml)),
      ],
    );
  }
}

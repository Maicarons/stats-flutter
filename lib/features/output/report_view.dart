/// 报告展示组件（v1.5.0 M4.1 从 `analysis_runner.dart` 拆出）：
/// 分区块 [ReportSectionBlock] + 表格 [ReportTableWidget]。
///
/// 报告卡片（`report_card.dart`）与输出树都用这两个组件，导出（HTML/MD/PDF）
/// 走同一套模型与样式判定（`report_style.dart`）。
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../shared/ui/ui.dart';
import 'report_builder.dart';
import 'report_style.dart';
import 'section_export_menu.dart';

/// 报告分区：标题（+ 分区导出菜单）+ 可选正文 + 表格 + 注释。
class ReportSectionBlock extends StatelessWidget {
  final ReportSection section;

  /// 所属报告标题（分区导出时作为一级标题与文件名的一部分）。
  final String reportTitle;

  /// 分区序号（纯中文标题回退为 `section-N`）。
  final int index;

  const ReportSectionBlock({
    super.key,
    required this.section,
    required this.reportTitle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                section.heading,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SectionExportMenu(
              section: section,
              reportTitle: reportTitle,
              index: index,
            ),
          ],
        ),
        if (section.body != null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.x2,
              top: AppSpacing.x1,
            ),
            child: Text(
              section.body!,
              style: text.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        for (final t in section.tables) ...[
          const SizedBox(height: AppSpacing.x2),
          ReportTableWidget(table: t),
        ],
        if (section.notes != null) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(
            section.notes!,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x5),
      ],
    );
  }
}

/// 报告表格：细描边 + 表题 + 斑马行；数值列右对齐、p 值列加星着色。
class ReportTableWidget extends StatelessWidget {
  final ReportTable table;
  const ReportTableWidget({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cols = table.headers.length;

    // 数值列 / p 值列的判定与屏幕、HTML、PDF 导出共用一份（report_style.dart）
    final style = ReportTableStyle.of(table);

    Widget cell(String s, int c, {required bool header}) {
      final cs =
          header ? styleHeaderCell(style, s, c) : styleBodyCell(style, s, c);
      final numeric = !header && cs.numeric;
      final p = cs.p;
      final stars = cs.stars;
      final color = (header || p == null)
          ? null
          : (stars.isEmpty ? scheme.onSurfaceVariant : pValueColor(context, p));

      return Container(
        constraints: BoxConstraints(minWidth: c == 0 ? 112 : 76),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: header ? AppSpacing.x2 : AppSpacing.x1 + 3,
        ),
        alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cs.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: header
                    ? FontWeight.w700
                    : (stars.isEmpty ? FontWeight.w400 : FontWeight.w600),
                fontFeatures: const [FontFeature.tabularFigures()],
                color: header
                    ? scheme.onSurface
                    : (color ?? scheme.onSurfaceVariant),
              ),
            ),
            if (stars.isNotEmpty) ...[
              const SizedBox(width: 4),
              SignificanceBadge(text: stars, p: p, small: true),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.rMd,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.rMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (table.caption != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x3,
                    AppSpacing.x2,
                    AppSpacing.x3,
                    0,
                  ),
                  child: Text(
                    table.caption!,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                color: scheme.surfaceContainerHigh,
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++)
                      cell(c < table.headers.length ? table.headers[c] : '', c,
                          header: true),
                  ],
                ),
              ),
              for (var r = 0; r < table.rows.length; r++)
                Container(
                  decoration: BoxDecoration(
                    color: r.isOdd
                        ? scheme.surfaceContainerLow.withValues(alpha: 0.5)
                        : null,
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        cell(
                          c < table.rows[r].length ? table.rows[r][c] : '',
                          c,
                          header: false,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

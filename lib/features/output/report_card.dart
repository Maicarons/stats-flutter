/// 单张报告卡片（v1.5.0 M4.1）：标题 + 生成时间 + 折叠/展开 + 复制/导出/删除。
///
/// 展开与否由外层控制（`output_tree.dart` 的状态）：默认只展开最新一张，
/// 用户手动折叠/展开的结果记在输出树里，因此「再跑一次」不会把旧卡片顶开。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import 'report_builder.dart';
import 'report_export_menu.dart';
import 'report_view.dart';

class ReportCard extends StatelessWidget {
  final AnalysisReport report;

  /// 是否展开（受控）。
  final bool expanded;

  /// 折叠/展开回调；为 null 时不显示折叠按钮（导出预览等场景）。
  final VoidCallback? onToggle;

  /// 导出文件名的基名（见 `report_export_menu.dart`）。
  final String? nameBase;

  /// 为 null 时不显示删除按钮。
  final VoidCallback? onDelete;

  const ReportCard({
    super.key,
    required this.report,
    this.expanded = true,
    this.onToggle,
    this.nameBase,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x1,
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggle != null)
                  IconButton(
                    tooltip:
                        expanded ? l10n.collapseReport : l10n.expandReport,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
                Expanded(
                  // 点标题区也能折叠：手机上比点小图标好按
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (report.subtitle.isNotEmpty)
                          Text(
                            report.subtitle,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.generatedAt(
                            report.createdAt.toLocal().toIso8601String(),
                          ),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: AppFontSize.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.copyReport,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  onPressed: () => copyReportText(context, report),
                ),
                ReportExportMenu(report: report, nameBase: nameBase),
                if (onDelete != null)
                  IconButton(
                    tooltip: l10n.deleteReport,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                0,
              ),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, s) in report.sections.indexed)
                      ReportSectionBlock(
                        section: s,
                        reportTitle: report.title,
                        index: i,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

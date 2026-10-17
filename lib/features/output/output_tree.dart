/// 输出树（v1.5.0 M4.1）：同一分析多次运行的报告卡片，最新在最前。
///
/// 报告数据由调用方持有（`AnalysisRunner` 里的会话级 `OutputStore`），这里只
/// 负责：表头（条数 + 清空）、卡片列表，以及「默认只展开最新一张」的展开状态。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';
import 'report_builder.dart';
import 'report_card.dart';

class OutputTree extends StatefulWidget {
  /// 报告列表，最新在最前。
  final List<AnalysisReport> reports;

  /// 导出文件名基名（卡片按运行次序加序号，避免同名互相覆盖）。
  final String? nameBase;

  final void Function(AnalysisReport report) onDelete;

  final VoidCallback onClear;

  const OutputTree({
    super.key,
    required this.reports,
    required this.onDelete,
    required this.onClear,
    this.nameBase,
  });

  @override
  State<OutputTree> createState() => _OutputTreeState();
}

class _OutputTreeState extends State<OutputTree> {
  /// 用户手动折叠/展开过的卡片（按报告对象记，卡片被删掉后残留无副作用）。
  final Map<AnalysisReport, bool> _override = {};

  /// 默认只展开最新一张；用户点过就以用户的为准。
  bool _expanded(AnalysisReport r, int index) => _override[r] ?? (index == 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final reports = widget.reports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 标题吃剩余空间：窄屏（手机上报告区只有 ~380px）时省略，
            // 不把「清空输出」按钮挤出边界。
            Expanded(
              child: Text(
                l10n.outputTitle,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: AppRadius.rSm,
              ),
              child: Text(
                l10n.outputCount(reports.length),
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: widget.onClear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text(l10n.clearOutput),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        for (final (i, r) in reports.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.x3),
          ReportCard(
            // key 绑在报告上：新增卡片不会「继承」旧卡片的展开状态
            key: ValueKey(r),
            report: r,
            expanded: _expanded(r, i),
            onToggle: () => setState(() => _override[r] = !_expanded(r, i)),
            nameBase: widget.nameBase == null
                ? null
                : '${widget.nameBase}-${reports.length - i}',
            onDelete: () => widget.onDelete(r),
          ),
        ],
      ],
    );
  }
}

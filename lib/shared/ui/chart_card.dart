/// 图表容器 + 统一图表样式（配色 / 网格 / 轴标签）。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class ChartCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final double height;
  final Widget child;
  final List<ChartLegendItem> legend;
  final Widget? trailing;

  const ChartCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.height = 280,
    this.legend = const [],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          if (title != null) const SizedBox(height: AppSpacing.x3),
          SizedBox(height: height, child: child),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x4,
              runSpacing: AppSpacing.x2,
              children: legend,
            ),
          ],
        ],
      ),
    );
  }
}

class ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const ChartLegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 图表统一样式工厂。
abstract final class ChartStyle {
  static FlTitlesData titles(BuildContext context, {
    List<String>? bottomLabels,
    String? leftTitle,
    String? bottomTitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 11,
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        axisNameWidget: leftTitle == null
            ? null
            : Text(leftTitle, style: style),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (v, meta) => Text(
            _short(v),
            style: style,
            textAlign: TextAlign.right,
          ),
        ),
      ),
      bottomTitles: bottomLabels == null
          ? AxisTitles(
              axisNameWidget: bottomTitle == null
                  ? null
                  : Text(bottomTitle, style: style),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) =>
                    Text(_short(v), style: style),
              ),
            )
          : AxisTitles(
              axisNameWidget: bottomTitle == null
                  ? null
                  : Text(bottomTitle, style: style),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  // 分类轴只在整数刻度出标签：fl_chart 有时会把刻度铺在半格
                  // （0.5 步长）上，取整会让同一个标签重复出现（PC1 PC1 …）。
                  final r = v.roundToDouble();
                  if ((v - r).abs() > 1e-6) return const SizedBox.shrink();
                  final i = r.toInt();
                  if (i < 0 || i >= bottomLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      bottomLabels[i],
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
    );
  }

  static FlGridData grid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (v) => FlLine(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        strokeWidth: 1,
      ),
    );
  }

  static FlBorderData border(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(color: scheme.outlineVariant),
        bottom: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  static BarTouchData barTouch(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => scheme.inverseSurface,
        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
          rod.toY.toStringAsFixed(2),
          TextStyle(
            color: scheme.onInverseSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static LineTouchData lineTouch(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => scheme.inverseSurface,
      ),
    );
  }

  static String _short(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    if (v.abs() >= 1000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

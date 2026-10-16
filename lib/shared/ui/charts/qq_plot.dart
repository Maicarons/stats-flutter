/// 正态 Q-Q 图：散点 + 45° 参考线 + 轴标题 + 偏离最大的点高亮。
///
/// 数据来自 statkit 的 `normalQQPoints()` / `normalQQPointsStandardized()`
/// （[QQPoint]：理论分位 vs 样本分位，标准化版本两者同尺度，参考线为 y = x）。
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:statkit/statkit.dart';

import '../../../core/theme/design_tokens.dart';
import '../chart_card.dart';
import 'chart_frame.dart';

class QQPlot extends StatelessWidget {
  final List<QQPoint> points;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  /// 轴标题（理论分位 / 样本分位）。
  final String? xTitle;
  final String? yTitle;

  /// 高亮「偏离参考线最大」的点数（尾部形态最值得看的地方）。
  final int highlightTop;

  const QQPlot({
    super.key,
    required this.points,
    this.emptyLabel = '',
    this.xTitle,
    this.yTitle,
    this.highlightTop = 3,
  });

  /// 需要高亮的点索引（按 |样本 − 理论| 降序取前 [highlightTop] 个）。
  static Set<int> topDeviationIndices(List<QQPoint> points, int top) {
    if (points.isEmpty || top <= 0) return const {};
    final idx = List<int>.generate(points.length, (i) => i);
    idx.sort((a, b) {
      final da = (points[a].sample - points[a].theoretical).abs();
      final db = (points[b].sample - points[b].theoretical).abs();
      return db.compareTo(da);
    });
    return idx.take(math.min(top, points.length)).toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return ChartEmpty(message: emptyLabel);

    final scheme = Theme.of(context).colorScheme;
    final app = context.appColors;
    final highlighted = QQPlot.topDeviationIndices(points, highlightTop);

    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final p in points) {
      for (final v in [p.theoretical, p.sample]) {
        if (!v.isFinite) continue;
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
    }
    final scale = ChartScale.padded(lo, hi, pad: 0.08);

    return LineChart(
      LineChartData(
        minX: scale.min,
        maxX: scale.max,
        minY: scale.min,
        maxY: scale.max,
        lineBarsData: [
          // 参考线（y = x）：标准化后即「完全正态」
          LineChartBarData(
            spots: [
              FlSpot(scale.min, scale.min),
              FlSpot(scale.max, scale.max),
            ],
            color: scheme.outline.withValues(alpha: 0.9),
            barWidth: 1.3,
            dashArray: const [5, 4],
            isCurved: false,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [
              for (final p in points) FlSpot(p.theoretical, p.sample),
            ],
            isCurved: false,
            barWidth: 0,
            color: Colors.transparent,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final hot = highlighted.contains(index);
                return FlDotCirclePainter(
                  radius: hot ? 3.8 : 2.6,
                  color: hot
                      ? app.warning
                      : app.chartAt(0).withValues(alpha: 0.85),
                  strokeWidth: hot ? 1.2 : 0,
                  strokeColor: scheme.surface,
                );
              },
            ),
          ),
        ],
        titlesData: ChartStyle.titles(
          context,
          leftTitle: yTitle,
          bottomTitle: xTitle,
        ),
        gridData: ChartStyle.grid(context),
        borderData: ChartStyle.border(context),
        lineTouchData: ChartStyle.lineTouch(context),
      ),
    );
  }
}

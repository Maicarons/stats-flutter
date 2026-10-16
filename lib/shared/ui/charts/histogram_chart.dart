/// 直方图：按 statkit 分箱结果绘制频数柱。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:statkit/statkit.dart';

import '../../../core/theme/design_tokens.dart';
import '../chart_card.dart';
import 'chart_frame.dart';

class HistogramChart extends StatelessWidget {
  final List<HistogramBin> bins;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  /// 横轴标题（通常为变量名）。
  final String? xTitle;

  const HistogramChart({
    super.key,
    required this.bins,
    this.emptyLabel = '',
    this.xTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (bins.isEmpty) return ChartEmpty(message: emptyLabel);

    final app = context.appColors;
    return BarChart(
      BarChartData(
        barGroups: List.generate(
          bins.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: bins[i].count.toDouble(),
                width: 14,
                color: app.chartAt(0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
        titlesData: ChartStyle.titles(
          context,
          bottomLabels: [
            for (final b in bins) formatNum(b.midpoint, digits: 1),
          ],
          bottomTitle: xTitle,
        ),
        barTouchData: ChartStyle.barTouch(context),
        borderData: FlBorderData(show: false),
        gridData: ChartStyle.grid(context),
      ),
    );
  }
}

/// 频数条形图：每个类别一色，横轴为类别标签。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:statkit/statkit.dart';

import '../../../core/theme/design_tokens.dart';
import '../chart_card.dart';
import 'chart_frame.dart';

class FrequencyBarChart extends StatelessWidget {
  final List<FrequencyRow> rows;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  const FrequencyBarChart({
    super.key,
    required this.rows,
    this.emptyLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return ChartEmpty(message: emptyLabel);

    final app = context.appColors;
    return BarChart(
      BarChartData(
        barGroups: List.generate(
          rows.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: rows[i].frequency.toDouble(),
                width: 18,
                color: app.chartAt(i),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          ),
        ),
        titlesData: ChartStyle.titles(
          context,
          bottomLabels: [for (final e in rows) e.label],
        ),
        barTouchData: ChartStyle.barTouch(context),
        borderData: FlBorderData(show: false),
        gridData: ChartStyle.grid(context),
      ),
    );
  }
}

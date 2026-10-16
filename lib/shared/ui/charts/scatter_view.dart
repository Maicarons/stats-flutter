/// 散点图：普通散点与 k-means 聚类散点（含中心点标记）。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../chart_card.dart';
import 'chart_frame.dart';

/// 双变量散点图。
class ScatterChartView extends StatelessWidget {
  final List<Offset> points;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  final String? xTitle;
  final String? yTitle;

  const ScatterChartView({
    super.key,
    required this.points,
    this.emptyLabel = '',
    this.xTitle,
    this.yTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return ChartEmpty(message: emptyLabel);

    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final p in points) {
      minX = p.dx < minX ? p.dx : minX;
      maxX = p.dx > maxX ? p.dx : maxX;
      minY = p.dy < minY ? p.dy : minY;
      maxY = p.dy > maxY ? p.dy : maxY;
    }
    final xr = ChartScale.padded(minX, maxX, pad: 0.04);
    final yr = ChartScale.padded(minY, maxY, pad: 0.04);
    final color = context.appColors.chartAt(0);

    return ScatterChart(
      ScatterChartData(
        scatterSpots: [
          for (final p in points)
            ScatterSpot(
              p.dx,
              p.dy,
              dotPainter: FlDotCirclePainter(
                radius: 3,
                color: color.withValues(alpha: 0.75),
                strokeWidth: 0,
              ),
            ),
        ],
        minX: xr.min,
        maxX: xr.max,
        minY: yr.min,
        maxY: yr.max,
        titlesData: ChartStyle.titles(
          context,
          // 数值轴：轴标题承载变量名（缩放时不至于顶掉刻度）
          leftTitle: yTitle,
          bottomTitle: xTitle,
        ),
        gridData: ChartStyle.grid(context),
        borderData: ChartStyle.border(context),
      ),
    );
  }
}

/// k-means 聚类散点图：每簇一色，中心点用描边菱形区分。
class ClusterScatterChart extends StatelessWidget {
  final List<Offset> points;

  /// 与 [points] 等长的簇编号。
  final List<int> assignments;

  /// 簇中心。
  final List<Offset> centers;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  const ClusterScatterChart({
    super.key,
    required this.points,
    required this.assignments,
    required this.centers,
    this.emptyLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return ChartEmpty(message: emptyLabel);

    final app = context.appColors;
    final all = [...points, ...centers];
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final p in all) {
      minX = p.dx < minX ? p.dx : minX;
      maxX = p.dx > maxX ? p.dx : maxX;
      minY = p.dy < minY ? p.dy : minY;
      maxY = p.dy > maxY ? p.dy : maxY;
    }
    final xr = ChartScale.padded(minX, maxX, pad: 0.06);
    final yr = ChartScale.padded(minY, maxY, pad: 0.06);

    return ScatterChart(
      ScatterChartData(
        scatterSpots: [
          for (var i = 0; i < points.length; i++)
            ScatterSpot(
              points[i].dx,
              points[i].dy,
              dotPainter: FlDotCirclePainter(
                radius: 3.2,
                color: app.chartAt(i < assignments.length ? assignments[i] : 0),
                strokeWidth: 0,
              ),
            ),
          // 簇中心：加粗十字，与数据点区分
          for (var c = 0; c < centers.length; c++)
            ScatterSpot(
              centers[c].dx,
              centers[c].dy,
              dotPainter: FlDotCrossPainter(
                size: 12,
                color: app.chartAt(c),
                width: 2.6,
              ),
            ),
        ],
        minX: xr.min,
        maxX: xr.max,
        minY: yr.min,
        maxY: yr.max,
        titlesData: ChartStyle.titles(context),
        gridData: ChartStyle.grid(context),
        borderData: ChartStyle.border(context),
      ),
    );
  }
}

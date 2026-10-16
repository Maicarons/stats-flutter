/// 碎石图：特征值下降曲线 + 肘部标记。
///
/// 数据来自 statkit 的 `factorAnalyze(...).eigenvalues`（降序）。
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../chart_card.dart';
import 'chart_frame.dart';

class ScreePlot extends StatelessWidget {
  /// 降序特征值。
  final List<double> eigenvalues;

  /// x 轴标签（如 PC1..PCk），长度不足时自动补 `PC{i}`。
  final List<String>? labels;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  /// 组件名（用于肘部标记文字，如 `PC3`）。
  final String Function(int component)? componentLabel;

  const ScreePlot({
    super.key,
    required this.eigenvalues,
    this.labels,
    this.emptyLabel = '',
    this.componentLabel,
  });

  /// 肘部：下降曲率最大处（1-based 组件序号），不足 3 个分量时返回 null。
  static int? elbowComponent(List<double> eigenvalues) {
    if (eigenvalues.length < 3) return null;
    var best = -1;
    var bestCurve = double.negativeInfinity;
    for (var k = 0; k + 2 < eigenvalues.length; k++) {
      final curve =
          (eigenvalues[k] - eigenvalues[k + 1]) -
              (eigenvalues[k + 1] - eigenvalues[k + 2]);
      if (curve > bestCurve) {
        bestCurve = curve;
        best = k;
      }
    }
    if (best < 0 || bestCurve <= 0) return null;
    return best + 2; // 膝点落在 k+1（0-based）之后，即第 k+2 个分量
  }

  @override
  Widget build(BuildContext context) {
    if (eigenvalues.isEmpty) return ChartEmpty(message: emptyLabel);

    final scheme = Theme.of(context).colorScheme;
    final app = context.appColors;
    final n = eigenvalues.length;
    final names = labels ?? [for (var i = 0; i < n; i++) 'PC${i + 1}'];
    final maxY = eigenvalues.reduce((a, b) => a > b ? a : b);
    final elbow = ScreePlot.elbowComponent(eigenvalues);

    return LineChart(
      LineChartData(
        minX: -0.4,
        maxX: n - 0.6,
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.12,
        extraLinesData: ExtraLinesData(
          verticalLines: elbow == null
              ? const []
              : [
                  VerticalLine(
                    x: (elbow - 1).toDouble(),
                    color: scheme.outline,
                    strokeWidth: 1.2,
                    dashArray: const [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: scheme.onSurfaceVariant,
                      ),
                      labelResolver: (_) =>
                          componentLabel?.call(elbow) ?? 'PC$elbow',
                    ),
                  ),
                ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++)
                FlSpot(i.toDouble(), eigenvalues[i]),
            ],
            isCurved: false,
            color: app.chartAt(0),
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: app.chartAt(0),
                strokeWidth: 1.6,
                strokeColor: scheme.surface,
              ),
            ),
          ),
        ],
        titlesData: ChartStyle.titles(context, bottomLabels: names),
        gridData: ChartStyle.grid(context),
        borderData: ChartStyle.border(context),
        lineTouchData: ChartStyle.lineTouch(context),
      ),
    );
  }
}

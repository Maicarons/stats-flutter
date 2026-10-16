/// 箱线图：须 / 四分位箱 / 中位数 / 均值 / 离群点，支持多组并列。
///
/// 数据来自 statkit 的 `boxPlot()` / `boxPlotGroups()`（[BoxPlotData]），
/// 这里只负责绘制：fl_chart 没有箱线图，用 [CustomPaint] 自绘更可控。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:statkit/statkit.dart';

import '../../../core/theme/design_tokens.dart';
import 'chart_frame.dart';

class BoxPlotChart extends StatelessWidget {
  /// 每个分组一个箱体（单变量时长度为 1）。
  final List<BoxPlotData> boxes;

  /// 与 [boxes] 等长的分组名。
  final List<String> labels;

  /// 悬停 / 长按提示（与 [boxes] 等长，可省略）。
  final List<String>? tooltips;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  /// 是否绘制均值标记（菱形）。
  final bool showMean;

  const BoxPlotChart({
    super.key,
    required this.boxes,
    required this.labels,
    this.tooltips,
    this.emptyLabel = '',
    this.showMean = true,
  });

  /// 全部分组的值域（含离群点与均值）。
  static (double, double) valueRange(List<BoxPlotData> boxes) {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final b in boxes) {
      for (final v in [
        b.lowerWhisker,
        b.upperWhisker,
        b.min,
        b.max,
        b.mean,
        ...b.outliers,
      ]) {
        if (!v.isFinite) continue;
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
    }
    if (!lo.isFinite || !hi.isFinite) return (0, 1);
    return (lo, hi);
  }

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return ChartEmpty(message: emptyLabel);

    final scheme = Theme.of(context).colorScheme;
    final (lo, hi) = BoxPlotChart.valueRange(boxes);
    final scale = ChartScale.padded(lo, hi);
    final ticks = niceTicks(scale.min, scale.max);
    final colors = <Color>[
      for (var i = 0; i < boxes.length; i++) context.appColors.chartAt(i),
    ];
    final scaler = chartTextScaler(context);
    final labelStyle = chartLabelStyle(context);

    return LayoutBuilder(
      builder: (context, c) {
        final plot = ChartInsets.plotRect(Size(c.maxWidth, c.maxHeight));
        final frame = ChartFrame(
          plot: plot,
          scale: scale,
          ticks: ticks,
          categories: labels,
          labelStyle: labelStyle,
          gridColor: scheme.outlineVariant.withValues(alpha: 0.6),
          textScaler: scaler,
        );
        final band = frame.bandWidth;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BoxPlotPainter(
                  boxes: boxes,
                  frame: frame,
                  colors: colors,
                  surface: scheme.surface,
                  showMean: showMean,
                ),
              ),
            ),
            if (tooltips != null)
              for (var i = 0; i < boxes.length; i++)
                Positioned(
                  left: plot.left + i * band,
                  top: plot.top,
                  width: band,
                  height: plot.height,
                  child: Tooltip(
                    message: i < tooltips!.length ? tooltips![i] : '',
                    child: Container(color: Colors.transparent),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _BoxPlotPainter extends CustomPainter {
  final List<BoxPlotData> boxes;
  final ChartFrame frame;
  final List<Color> colors;
  final Color surface;
  final bool showMean;

  const _BoxPlotPainter({
    required this.boxes,
    required this.frame,
    required this.colors,
    required this.surface,
    required this.showMean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    frame.paintGrid(canvas);

    final boxW = (frame.bandWidth * 0.46).clamp(5.0, 44.0);
    final capW = boxW * 0.52;

    for (var i = 0; i < boxes.length; i++) {
      final b = boxes[i];
      final c = colors[i % colors.length];
      final cx = frame.centerX(i);

      final whisker = Paint()
        ..color = c
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // 上下须 + 须帽
      canvas.drawLine(Offset(cx, frame.y(b.q3)),
          Offset(cx, frame.y(b.upperWhisker)), whisker);
      canvas.drawLine(Offset(cx, frame.y(b.q1)),
          Offset(cx, frame.y(b.lowerWhisker)), whisker);
      canvas.drawLine(
        Offset(cx - capW / 2, frame.y(b.upperWhisker)),
        Offset(cx + capW / 2, frame.y(b.upperWhisker)),
        whisker,
      );
      canvas.drawLine(
        Offset(cx - capW / 2, frame.y(b.lowerWhisker)),
        Offset(cx + capW / 2, frame.y(b.lowerWhisker)),
        whisker,
      );

      // 四分位箱（IQR = 0 时退化为 1px 细条）
      final top = frame.y(b.q3);
      final bottom = math.max(frame.y(b.q1), top + 1);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - boxW / 2, top, cx + boxW / 2, bottom),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = c.withValues(alpha: 0.22));
      canvas.drawRRect(
        rect,
        Paint()
          ..color = c
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      // 中位数
      canvas.drawLine(
        Offset(cx - boxW / 2, frame.y(b.median)),
        Offset(cx + boxW / 2, frame.y(b.median)),
        Paint()
          ..color = c
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );

      // 均值（空心菱形，与中位数区分）
      if (showMean && b.mean.isFinite) {
        final my = frame.y(b.mean);
        const r = 3.4;
        final path = Path()
          ..moveTo(cx, my - r)
          ..lineTo(cx + r, my)
          ..lineTo(cx, my + r)
          ..lineTo(cx - r, my)
          ..close();
        canvas.drawPath(path, Paint()..color = surface);
        canvas.drawPath(
          path,
          Paint()
            ..color = c
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
        );
      }

      // 离群点
      for (final o in b.outliers) {
        if (!o.isFinite) continue;
        final oy = frame.y(o);
        canvas.drawCircle(Offset(cx, oy), 2.6, Paint()..color = surface);
        canvas.drawCircle(
          Offset(cx, oy),
          2.6,
          Paint()
            ..color = c
            ..strokeWidth = 1.3
            ..style = PaintingStyle.stroke,
        );
      }
    }

    frame.paintCategoryLabels(canvas);
  }

  @override
  bool shouldRepaint(covariant _BoxPlotPainter old) =>
      old.boxes != boxes ||
      old.frame.plot != frame.plot ||
      old.colors != colors ||
      old.surface != surface ||
      old.showMean != showMean;
}

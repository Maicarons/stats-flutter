/// 误差条图：分组均值 + 上下置信区间须，可选总体均值参考线。
///
/// 数据来自 statkit 的 `errorBarsFromGroups()`（[ErrorBarData]）。
library;

import 'package:flutter/material.dart';
import 'package:statkit/statkit.dart';

import '../../../core/theme/design_tokens.dart';
import 'chart_frame.dart';

class ErrorBarChart extends StatelessWidget {
  final List<ErrorBarData> bars;

  /// 悬停 / 长按提示（与 [bars] 等长，可省略）。
  final List<String>? tooltips;

  /// 数据不足时的提示文案（空串则只显示图标）。
  final String emptyLabel;

  /// 参考线（通常为总体均值），null 表示不画。
  final double? referenceLine;

  /// 参考线图例文字（画参考线时用于 tooltip/语义）。
  final String? referenceLabel;

  const ErrorBarChart({
    super.key,
    required this.bars,
    this.tooltips,
    this.emptyLabel = '',
    this.referenceLine,
    this.referenceLabel,
  });

  /// 全部误差条的取值上下界（含参考线）。
  static (double, double) valueRange(List<ErrorBarData> bars) {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final b in bars) {
      for (final v in [b.low, b.high, b.mean]) {
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
    if (bars.isEmpty) return ChartEmpty(message: emptyLabel);

    final scheme = Theme.of(context).colorScheme;
    final app = context.appColors;
    var (lo, hi) = ErrorBarChart.valueRange(bars);
    final ref = referenceLine;
    if (ref != null && ref.isFinite) {
      if (ref < lo) lo = ref;
      if (ref > hi) hi = ref;
    }
    final scale = ChartScale.padded(lo, hi);
    final ticks = niceTicks(scale.min, scale.max);
    final scaler = chartTextScaler(context);
    final labelStyle = chartLabelStyle(context);

    return LayoutBuilder(
      builder: (context, c) {
        // 两行分类标签（组名 + n）需要更多底部留白
        final plot = ChartInsets.plotRect(
          Size(c.maxWidth, c.maxHeight),
          bottom: ChartInsets.bottom + 12,
        );
        final frame = ChartFrame(
          plot: plot,
          scale: scale,
          ticks: ticks,
          categories: [for (final b in bars) b.label],
          subLabels: [for (final b in bars) 'n=${b.n}'],
          labelStyle: labelStyle,
          subLabelStyle: labelStyle.copyWith(fontSize: 9.5),
          gridColor: scheme.outlineVariant.withValues(alpha: 0.6),
          textScaler: scaler,
        );
        final band = frame.bandWidth;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ErrorBarPainter(
                  bars: bars,
                  frame: frame,
                  color: app.chartAt(0),
                  ciColor: app.ci,
                  surface: scheme.surface,
                  referenceLine: ref,
                  referenceColor: app.ci,
                ),
              ),
            ),
            if (tooltips != null)
              for (var i = 0; i < bars.length; i++)
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

class _ErrorBarPainter extends CustomPainter {
  final List<ErrorBarData> bars;
  final ChartFrame frame;
  final Color color;

  /// 置信区间须颜色（与均值柱区分，便于图例对应）。
  final Color ciColor;
  final Color surface;
  final double? referenceLine;
  final Color referenceColor;

  const _ErrorBarPainter({
    required this.bars,
    required this.frame,
    required this.color,
    required this.ciColor,
    required this.surface,
    required this.referenceLine,
    required this.referenceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    frame.paintGrid(canvas);

    // 参考线（虚线）
    final ref = referenceLine;
    if (ref != null && ref.isFinite) {
      final y = frame.y(ref);
      final paint = Paint()
        ..color = referenceColor
        ..strokeWidth = 1.2;
      const dash = 5.0;
      for (var x = frame.plot.left; x < frame.plot.right; x += dash * 2) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dash).clamp(frame.plot.left, frame.plot.right), y),
          paint,
        );
      }
    }

    final capW = (frame.bandWidth * 0.28).clamp(6.0, 30.0);
    final barW = (frame.bandWidth * 0.34).clamp(8.0, 34.0);

    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = frame.centerX(i);
      if (!b.mean.isFinite) continue;

      // 置信区间须
      final stroke = Paint()
        ..color = ciColor
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, frame.y(b.high)), Offset(cx, frame.y(b.low)),
          stroke);
      canvas.drawLine(Offset(cx - capW / 2, frame.y(b.high)),
          Offset(cx + capW / 2, frame.y(b.high)), stroke);
      canvas.drawLine(Offset(cx - capW / 2, frame.y(b.low)),
          Offset(cx + capW / 2, frame.y(b.low)), stroke);

      // 均值柱（短而粗，避免被误读成条形图的统计量）
      final my = frame.y(b.mean);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - barW / 2, my - 3, cx + barW / 2, my + 3),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = surface
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    frame.paintCategoryLabels(canvas);
  }

  @override
  bool shouldRepaint(covariant _ErrorBarPainter old) =>
      old.bars != bars ||
      old.frame.plot != frame.plot ||
      old.referenceLine != referenceLine ||
      old.color != color ||
      old.ciColor != ciColor ||
      old.surface != surface ||
      old.referenceColor != referenceColor;
}

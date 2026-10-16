/// 图表基础设施：线性刻度、刻度值生成、坐标框架、空态。
///
/// 自绘图（箱线图 / 误差条图）与 fl_chart 图共用，避免每个图各写一套
/// 「留白 + 网格 + 轴标签」。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// 数值 → 像素的线性映射（y 轴向上）。
@immutable
class ChartScale {
  final double min;
  final double max;

  const ChartScale(this.min, this.max);

  /// 由数据范围构造，两端留 [pad] 比例余量；退化范围（min == max）自动撑开，
  /// 避免「所有值相同」时除零。
  factory ChartScale.padded(double lo, double hi, {double pad = 0.06}) {
    if (!lo.isFinite || !hi.isFinite) return const ChartScale(0, 1);
    if (lo > hi) {
      final t = lo;
      lo = hi;
      hi = t;
    }
    if (lo == hi) {
      final d = lo.abs() < 1e-9 ? 1.0 : lo.abs() * 0.1;
      return ChartScale(lo - d, hi + d);
    }
    final p = (hi - lo) * pad;
    return ChartScale(lo - p, hi + p);
  }

  double get span => max - min;

  /// 归一化到 0..1（超出范围会被裁到边界）。
  double norm(double v) {
    if (span <= 0) return 0.5;
    return ((v - min) / span).clamp(0.0, 1.0);
  }
}

/// 「好看」的刻度值：步长取 1 / 2 / 5 × 10^k。
List<double> niceTicks(double min, double max, {int target = 5}) {
  if (!min.isFinite || !max.isFinite || target < 1) return const [0];
  if (max <= min) return [min];
  final raw = (max - min) / target;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floorToDouble()).toDouble();
  final norm = raw / mag;
  final step = (norm <= 1
          ? 1.0
          : norm <= 2
              ? 2.0
              : norm <= 5
                  ? 5.0
                  : 10.0) *
      mag;
  final out = <double>[];
  for (var v = (min / step).ceil() * step;
      v <= max + step * 1e-6;
      v += step) {
    out.add(double.parse(v.toStringAsFixed(10)));
  }
  return out.isEmpty ? [min, max] : out;
}

/// 刻度 / 标签的统一留白（与 [ChartStyle] 的 reservedSize 对齐）。
abstract final class ChartInsets {
  static const double left = 46;
  static const double bottom = 30;
  static const double top = 8;
  static const double right = 10;

  /// 绘图区矩形（保证至少 10×10，避免极小尺寸下负值）。
  static Rect plotRect(Size size, {double bottom = ChartInsets.bottom}) {
    final right = math.max(left + 10, size.width - ChartInsets.right);
    final bottomEdge = math.max(top + 10, size.height - bottom);
    return Rect.fromLTRB(left, top, right, bottomEdge);
  }
}

/// 绘图区框架：[plot] 内的网格、纵轴刻度文字、横轴分类标签。
class ChartFrame {
  final Rect plot;
  final ChartScale scale;
  final List<double> ticks;
  final List<String> categories;

  /// 分类标签的第二行（小字，如 `(n=12)`）。
  final List<String>? subLabels;
  final TextStyle labelStyle;
  final TextStyle? subLabelStyle;
  final Color gridColor;
  final TextScaler textScaler;

  const ChartFrame({
    required this.plot,
    required this.scale,
    required this.ticks,
    required this.categories,
    required this.labelStyle,
    required this.gridColor,
    this.subLabels,
    this.subLabelStyle,
    this.textScaler = TextScaler.noScaling,
  });

  /// 数值 → 像素 y
  double y(double v) => plot.bottom - scale.norm(v) * plot.height;

  double get bandWidth =>
      categories.isEmpty ? plot.width : plot.width / categories.length;

  /// 第 i 个分类的中心 x
  double centerX(int i) => plot.left + (i + 0.5) * bandWidth;

  /// 横线网格 + 纵轴刻度文字
  void paintGrid(Canvas canvas) {
    final line = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final t in ticks) {
      final yy = y(t);
      if (yy < plot.top - 0.5 || yy > plot.bottom + 0.5) continue;
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), line);
      final tp = _painter(formatTick(t), labelStyle);
      tp.paint(
        canvas,
        Offset(plot.left - 6 - tp.width, yy - tp.height / 2),
      );
    }
  }

  /// 分类标签（超出宽度自动省略），有 [subLabels] 时在其下方补一行小字。
  void paintCategoryLabels(Canvas canvas) {
    for (var i = 0; i < categories.length; i++) {
      final tp = _painter(categories[i], labelStyle, maxWidth: bandWidth - 4);
      tp.paint(canvas, Offset(centerX(i) - tp.width / 2, plot.bottom + 5));
      final subs = subLabels;
      if (subs != null && i < subs.length && subs[i].isNotEmpty) {
        final sp = _painter(
          subs[i],
          subLabelStyle ?? labelStyle.copyWith(fontSize: 9.5),
          maxWidth: bandWidth - 4,
        );
        sp.paint(
          canvas,
          Offset(centerX(i) - sp.width / 2, plot.bottom + 6 + tp.height),
        );
      }
    }
  }

  TextPainter _painter(String text, TextStyle style, {double? maxWidth}) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
  }
}

/// 刻度文字：整数不显示小数，大数不带多余位数。
String formatTick(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  if (v.abs() >= 1000) return v.toStringAsFixed(0);
  if (v.abs() >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

/// 绘图区通用文字（居中 / 右对齐由调用方计算偏移）。
void paintChartText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at, {
  TextAlign align = TextAlign.left,
  double? maxWidth,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
    textScaler: textScaler,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  tp.paint(canvas, at);
}

/// 图表空态：数据不足时给一句话，而不是空白坐标系。
class ChartEmpty extends StatelessWidget {
  final String message;

  const ChartEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, size: 26, color: scheme.outline),
          const SizedBox(height: AppSpacing.x2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.label,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 图表内统一标签样式（11px、等宽数字、弱化色）。
///
/// 必须从主题的 [TextTheme] 派生：`CustomPaint` 里的 [TextPainter] 不会
/// 继承 `DefaultTextStyle`，若就地新建 `TextStyle` 会丢掉主题字体族
/// （golden 环境下退化成 Ahem，刻度文字会渲染成实心方块）。
TextStyle chartLabelStyle(BuildContext context) {
  final theme = Theme.of(context);
  final base = theme.textTheme.labelSmall ??
      theme.textTheme.bodySmall ??
      const TextStyle();
  return base.copyWith(
    fontSize: AppFontSize.caption,
    color: theme.colorScheme.onSurfaceVariant,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );
}

/// 图表标签的文字缩放（上限 1.4，避免大字号把坐标系挤爆）。
TextScaler chartTextScaler(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
  return TextScaler.linear(scale);
}

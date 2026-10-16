/// 设计令牌（Design Tokens）
///
/// 全应用唯一的尺度来源：间距、圆角、阴影、动效时长、语义色与图表调色板。
/// 页面与组件不再写魔法数字，一律引用这里，保证视觉一致 + 便于整体调参。
library;

import 'package:flutter/material.dart';

/// 4pt 基网格间距
abstract final class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 24;
  static const double x6 = 32;
  static const double x7 = 48;
}

/// 圆角阶梯
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
}

/// 字号阶梯（正文 15 / 行高 1.6，移动端可读）
abstract final class AppFontSize {
  static const double display = 32;
  static const double headline = 24;
  static const double titleLg = 20;
  static const double title = 17;
  static const double titleSm = 15;
  static const double body = 15;
  static const double bodySm = 13;
  static const double label = 12;
  static const double caption = 11;
}

/// 动效时长（配合 reduced-motion 使用，见 [AppMotion]）
abstract final class AppDur {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration enter = Duration(milliseconds: 300);

  /// 页面转场
  static const Duration page = Duration(milliseconds: 280);

  /// 列表逐项入场：相邻项延迟
  static const Duration staggerStep = Duration(milliseconds: 24);

  /// 列表逐项入场：整段动效总时长上限（含最后一项自己的时长）
  static const Duration staggerMax = Duration(milliseconds: 300);
}

/// 动效辅助：尊重系统「减弱动态效果」设置
abstract final class AppMotion {
  /// 系统开启 reduced-motion 时返回 [Duration.zero]，否则返回 [base]。
  static Duration of(BuildContext context, Duration base) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduce ? Duration.zero : base;
  }

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// 焦点可见性：统一焦点环（向外扩散的 2px 描边，不影响布局、不与 hover 冲突）。
abstract final class AppFocus {
  /// 焦点环线宽
  static const double ringWidth = 2;

  /// 焦点环：以 [BoxShadow] 形式绘制在组件外侧，不参与布局，
  /// 因此获得焦点时不会像加粗边框那样让内容抖动 1px。
  static List<BoxShadow> ring(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.55),
          blurRadius: 0,
          spreadRadius: ringWidth,
        ),
      ];
}

/// 语义色 + 图表调色板 + 阴影，随主题明暗切换。
///
/// 统计场景专用：显著性、系数正负、置信区间、缺失值都有独立色。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// 通用状态色
  final Color success;
  final Color warning;
  final Color info;

  /// 统计语义
  final Color positive; // 正向系数 / 上升
  final Color negative; // 负向系数 / 下降
  final Color significance; // p < .05 等显著性强调
  final Color ci; // 置信区间
  final Color missing; // 缺失值

  /// 图表分类色（6 色）
  final List<Color> chart;

  /// 三级阴影（明暗各自合适）
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;

  const AppColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.positive,
    required this.negative,
    required this.significance,
    required this.ci,
    required this.missing,
    required this.chart,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  static const AppColors light = AppColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB26A00),
    info: Color(0xFF1565C0),
    positive: Color(0xFF1565C0),
    negative: Color(0xFFC62828),
    significance: Color(0xFFB4530A),
    ci: Color(0xFF6B7280),
    missing: Color(0xFF9AA0A6),
    chart: [
      Color(0xFF2F6FED),
      Color(0xFF00A884),
      Color(0xFFE17055),
      Color(0xFF6C5CE7),
      Color(0xFFD6A419),
      Color(0xFF0E7490),
    ],
    shadowSm: [
      BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    shadowMd: [
      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    shadowLg: [
      BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 10)),
    ],
  );

  static const AppColors dark = AppColors(
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF90CAF9),
    positive: Color(0xFF90CAF9),
    negative: Color(0xFFEF9A9A),
    significance: Color(0xFFFFB74D),
    ci: Color(0xFF9CA3AF),
    missing: Color(0xFF7C8288),
    chart: [
      Color(0xFF7AA5FF),
      Color(0xFF34D399),
      Color(0xFFFF9E7A),
      Color(0xFFA99BFF),
      Color(0xFFF2C94C),
      Color(0xFF56C7E0),
    ],
    shadowSm: [
      BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    shadowMd: [
      BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    shadowLg: [
      BoxShadow(color: Color(0x59000000), blurRadius: 28, offset: Offset(0, 10)),
    ],
  );

  /// 图表取色（循环）
  Color chartAt(int i) => chart[i % chart.length];

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? positive,
    Color? negative,
    Color? significance,
    Color? ci,
    Color? missing,
    List<Color>? chart,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      significance: significance ?? this.significance,
      ci: ci ?? this.ci,
      missing: missing ?? this.missing,
      chart: chart ?? this.chart,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      significance: Color.lerp(significance, other.significance, t)!,
      ci: Color.lerp(ci, other.ci, t)!,
      missing: Color.lerp(missing, other.missing, t)!,
      chart: [
        for (var i = 0; i < chart.length; i++)
          Color.lerp(chart[i], other.chart[i % other.chart.length], t)!,
      ],
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
    );
  }
}

/// 便捷读取：`context.appColors`
extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

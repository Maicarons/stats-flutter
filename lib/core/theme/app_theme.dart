/// 应用主题：Material 3 + 设计令牌 + 语义色 + 图表调色板。
///
/// 与 v1.2 的差别：
/// - 字体本地打包（Inter 拉丁/数字 + 系统 CJK 回退），不再运行时下载；
/// - 所有组件主题显式定义（dialog / sheet / snackbar / tab / rail ...），避免默认值不一致；
/// - 数值默认启用等宽数字（tabular figures），表格可对齐；
/// - 注入 [AppColors] 语义色扩展。
library;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class AppTheme {
  /// 主字体（本地打包）
  static const String fontFamily = 'Inter';

  /// 中文优先回退栈：拉丁用 Inter，CJK 落到系统字体，避免打包 17MB 全量中文字体。
  static const List<String> fontFallback = [
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'Noto Sans SC',
    'sans-serif',
  ];

  /// 等宽数字：让统计表里的数字竖直对齐。
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// 给任意 [TextStyle] 追加等宽数字。
  static TextStyle tabularText(TextStyle style) =>
      style.copyWith(fontFeatures: tabular);

  /// 组件主题里的文本样式：必须显式带上字体族，
  /// 否则 [TextStyle] 会退回平台默认字体（按钮 / 标签 / 导航栏文字就不再用 Inter）。
  static TextStyle _font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static ThemeData light(Color seed) => _base(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        AppColors.light,
      );

  static ThemeData dark(Color seed) => _base(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        AppColors.dark,
      );

  static ThemeData _base(ColorScheme scheme, AppColors app) {
    final text = _textTheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      // 焦点可见性：Material 组件（图标按钮 / 列表项 / Tab）统一焦点色；
      // 卡片类组件另用 AppFocus.ring 画外扩焦点环。
      focusColor: scheme.primary.withValues(alpha: 0.16),
      extensions: <ThemeExtension<dynamic>>[app],

      // 卡片：细描边 + 无海拔（阴影交给 AppCard 按需加）
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: AppFontSize.title,
          fontWeight: FontWeight.w700,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3 + 2,
          vertical: AppSpacing.x3,
        ),
        hintStyle: _font(color: scheme.onSurfaceVariant, fontSize: 14),
        labelStyle: _font(color: scheme.onSurfaceVariant, fontSize: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x3 + 2,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: _font(
            fontWeight: FontWeight.w600,
            fontSize: AppFontSize.titleSm,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x3 + 2,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: _font(
            fontWeight: FontWeight.w600,
            fontSize: AppFontSize.titleSm,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: _font(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: _font(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        side: BorderSide(color: scheme.outlineVariant),
        // 标签样式必须自带颜色：仅给字号/字重会覆盖掉默认色，
        // 未选中标签会失去颜色而「看不见」。
        labelStyle: _font(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: _font(
          color: scheme.onSecondaryContainer,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x1,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: AppFontSize.title,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: _font(color: scheme.onInverseSurface, fontSize: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        insetPadding: const EdgeInsets.all(AppSpacing.x4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        textStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.rSm,
        ),
        textStyle: _font(color: scheme.onInverseSurface, fontSize: 12),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        iconColor: scheme.onSurfaceVariant,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: _font(
          fontWeight: FontWeight.w700,
          fontSize: AppFontSize.titleSm,
        ),
        unselectedLabelStyle: _font(
          fontWeight: FontWeight.w500,
          fontSize: AppFontSize.titleSm,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _font(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontSize: AppFontSize.label,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: _font(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: AppFontSize.label,
        ),
        unselectedLabelTextStyle: _font(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: AppFontSize.label,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 2,
        highlightElevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        extendedTextStyle: _font(fontWeight: FontWeight.w600, fontSize: 14),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 3,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),

      // 页面转场：Android 与桌面用 Material 3 的 FadeForwards；
      // iOS / macOS 不指定，交给框架默认（即 Cupertino 侧滑），
      // 避免依赖可能随 SDK 版本变动 / 移除的平台 Builder 类名。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = scheme.brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    TextStyle t(
      TextStyle? source, {
      required double size,
      required FontWeight weight,
      double height = 1.5,
      double? spacing,
    }) {
      return (source ?? const TextStyle()).copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        fontFeatures: tabular,
      );
    }

    return base.copyWith(
      displayLarge: t(base.displayLarge,
          size: AppFontSize.display, weight: FontWeight.w800, height: 1.2, spacing: -0.5),
      displayMedium: t(base.displayMedium,
          size: 28, weight: FontWeight.w800, height: 1.2, spacing: -0.5),
      displaySmall: t(base.displaySmall,
          size: AppFontSize.headline, weight: FontWeight.w700, height: 1.25),
      headlineLarge: t(base.headlineLarge,
          size: AppFontSize.headline, weight: FontWeight.w700, height: 1.25),
      headlineMedium: t(base.headlineMedium,
          size: AppFontSize.titleLg, weight: FontWeight.w700, height: 1.3),
      headlineSmall: t(base.headlineSmall,
          size: AppFontSize.title, weight: FontWeight.w700, height: 1.3),
      titleLarge: t(base.titleLarge,
          size: AppFontSize.title, weight: FontWeight.w700, height: 1.3),
      titleMedium: t(base.titleMedium,
          size: AppFontSize.titleSm, weight: FontWeight.w600, height: 1.35),
      titleSmall: t(base.titleSmall,
          size: 14, weight: FontWeight.w600, height: 1.35),
      bodyLarge: t(base.bodyLarge, size: AppFontSize.body, weight: FontWeight.w400),
      bodyMedium: t(base.bodyMedium, size: 14, weight: FontWeight.w400),
      bodySmall: t(base.bodySmall, size: AppFontSize.bodySm, weight: FontWeight.w400),
      labelLarge: t(base.labelLarge,
          size: 14, weight: FontWeight.w600, height: 1.3),
      labelMedium: t(base.labelMedium,
          size: AppFontSize.label, weight: FontWeight.w600, height: 1.3),
      labelSmall: t(base.labelSmall,
          size: AppFontSize.caption, weight: FontWeight.w600, height: 1.3),
    );
  }
}

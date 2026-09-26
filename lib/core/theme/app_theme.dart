import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// 中文优先字体栈（Noto Sans SC + 系统回退）
  static List<String> get fontFallback => const [
        'PingFang SC',
        'Microsoft YaHei',
        'Noto Sans CJK SC',
        'Source Han Sans SC',
        'sans-serif',
      ];

  static TextStyle _applyZh(TextStyle style) {
    return style.copyWith(fontFamilyFallback: fontFallback);
  }

  static ThemeData light(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    // google_fonts Noto Sans SC 覆盖中英
    final base = GoogleFonts.notoSansScTextTheme(
      scheme.brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );

    // 确保每个 style 都有中文回退
    TextTheme themed = base.copyWith(
      displayLarge: _applyZh(base.displayLarge ?? const TextStyle()),
      displayMedium: _applyZh(base.displayMedium ?? const TextStyle()),
      displaySmall: _applyZh(base.displaySmall ?? const TextStyle()),
      headlineLarge: _applyZh(base.headlineLarge ?? const TextStyle()),
      headlineMedium: _applyZh(base.headlineMedium ?? const TextStyle()),
      headlineSmall: _applyZh(base.headlineSmall ?? const TextStyle()),
      titleLarge: _applyZh(base.titleLarge ?? const TextStyle()),
      titleMedium: _applyZh(base.titleMedium ?? const TextStyle()),
      titleSmall: _applyZh(base.titleSmall ?? const TextStyle()),
      bodyLarge: _applyZh(base.bodyLarge ?? const TextStyle()),
      bodyMedium: _applyZh(base.bodyMedium ?? const TextStyle()),
      bodySmall: _applyZh(base.bodySmall ?? const TextStyle()),
      labelLarge: _applyZh(base.labelLarge ?? const TextStyle()),
      labelMedium: _applyZh(base.labelMedium ?? const TextStyle()),
      labelSmall: _applyZh(base.labelSmall ?? const TextStyle()),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: themed,
      fontFamily: GoogleFonts.notoSansSc().fontFamily,
      fontFamilyFallback: fontFallback,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

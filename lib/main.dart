import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';
import 'shared/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSettings.load();
  runApp(const StatsFlutterApp());
}

/// 允许鼠标 / 触控笔拖拽滚动（大数据表格在桌面与移动端都更好操作）
class DragScrollBehavior extends MaterialScrollBehavior {
  const DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...PointerDeviceKind.values,
      };
}

class StatsFlutterApp extends StatelessWidget {
  const StatsFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stats-flutter',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(appSettings.seedColor),
          darkTheme: AppTheme.dark(appSettings.seedColor),
          themeMode: appSettings.themeMode,
          locale: appSettings.locale,
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          scrollBehavior: const DragScrollBehavior(),
          home: const SplashPage(),
        );
      },
    );
  }
}

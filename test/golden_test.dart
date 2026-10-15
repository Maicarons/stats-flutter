import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/learn/learn_content.dart';
import 'package:stats_flutter/features/learn/learn_page.dart';
import 'package:stats_flutter/features/learn/lesson_detail_page.dart';
import 'package:stats_flutter/features/quiz/quiz_page.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/ui/ui.dart';

const _seed = Color(0xFF2F6FED);

/// 载入打包的 Inter 字体，让 golden 使用与真机一致的西文/数字字形。
///
/// 测试环境默认不加载 Material 图标字体，图标会渲染成占位方块；
/// 这里一并加载，让 golden 更接近真机外观。
Future<void> _loadAppFonts() async {
  final inter = FontLoader('Inter');
  for (final path in const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]) {
    inter.addFont(rootBundle.load(path));
  }
  await inter.load();

  try {
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  } catch (_) {
    // 某些 SDK 版本不通过 asset bundle 暴露图标字体，忽略即可。
  }
}

Widget _app(Widget home, {required bool dark}) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: dark ? AppTheme.dark(_seed) : AppTheme.light(_seed),
      home: home,
    );

void main() {
  setUpAll(_loadAppFonts);

  Future<void> snap(
    WidgetTester tester, {
    required Widget page,
    required Size size,
    required bool dark,
    required String name,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(page, dark: dark));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden/$name.png'),
    );
  }

  const phone = Size(390, 844);
  const wide = Size(1280, 900);

  testWidgets('学习页 · 手机 · 浅色', (t) async {
    await snap(t, page: const LearnPage(), size: phone, dark: false,
        name: 'learn_phone_light');
  });

  testWidgets('学习页 · 手机 · 深色', (t) async {
    await snap(t, page: const LearnPage(), size: phone, dark: true,
        name: 'learn_phone_dark');
  });

  testWidgets('学习页 · 宽屏 · 浅色', (t) async {
    await snap(t, page: const LearnPage(), size: wide, dark: false,
        name: 'learn_wide_light');
  });

  testWidgets('测试页设置 · 手机 · 浅色', (t) async {
    await snap(t, page: const QuizPage(), size: phone, dark: false,
        name: 'quiz_setup_phone_light');
  });

  testWidgets('课程详情 · 手机 · 浅色', (t) async {
    await snap(t, page: LessonDetailPage(lesson: learnLessons.first),
        size: phone, dark: false, name: 'lesson_phone_light');
  });

  testWidgets('课程详情 · 手机 · 深色', (t) async {
    await snap(t, page: LessonDetailPage(lesson: learnLessons.first),
        size: phone, dark: true, name: 'lesson_phone_dark');
  });

  testWidgets('测试页设置 · 手机 · 深色', (t) async {
    await snap(t, page: const QuizPage(), size: phone, dark: true,
        name: 'quiz_setup_phone_dark');
  });

  testWidgets('自适应导航 · 手机 · 浅色', (t) async {
    await snap(
      t,
      page: AdaptiveNavScaffold(
        index: 0,
        onIndexChanged: (_) {},
        items: const [
          NavItem(
            icon: Icons.school_outlined,
            selectedIcon: Icons.school,
            label: 'Learn',
          ),
          NavItem(
            icon: Icons.quiz_outlined,
            selectedIcon: Icons.quiz,
            label: 'Quiz',
          ),
          NavItem(
            icon: Icons.table_chart_outlined,
            selectedIcon: Icons.table_chart,
            label: 'Data',
          ),
        ],
        body: const Center(child: Text('content area')),
      ),
      size: phone,
      dark: false,
      name: 'nav_phone_light',
    );
  });
}

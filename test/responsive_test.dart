import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/data_editor/data_editor_page.dart';
import 'package:stats_flutter/features/learn/learn_content.dart';
import 'package:stats_flutter/features/learn/learn_page.dart';
import 'package:stats_flutter/features/learn/lesson_detail_page.dart';
import 'package:stats_flutter/features/quiz/quiz_page.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';
import 'package:stats_flutter/shared/ui/ui.dart';

const _seed = Color(0xFF2F6FED);

/// 断点基线：手机竖屏 / 平板竖屏 / 平板横屏 / 桌面。
const _widths = <double>[375, 768, 1024, 1440];

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
    );

void main() {
  setUp(() {
    datasetStore.replace(Dataset.demoScores(zh: false));
  });

  /// 在给定宽度下渲染页面，并断言没有布局溢出 / 渲染异常。
  Future<void> expectNoOverflow(
    WidgetTester tester,
    Widget page,
    double width, {
    Size? size,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size ?? Size(width, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(page));
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: '在 ${width}px 宽度下出现布局异常',
    );
  }

  group('响应式布局无溢出', () {
    for (final w in _widths) {
      testWidgets('学习首页 @ ${w}px', (tester) async {
        await expectNoOverflow(tester, const LearnPage(), w);
      });

      testWidgets('课程详情 @ ${w}px', (tester) async {
        await expectNoOverflow(
          tester,
          LessonDetailPage(lesson: learnLessons.first),
          w,
        );
      });

      testWidgets('测试页 @ ${w}px', (tester) async {
        await expectNoOverflow(tester, const QuizPage(), w);
      });
    }

    for (final w in <double>[375, 1440]) {
      testWidgets('数据编辑器 @ ${w}px', (tester) async {
        await expectNoOverflow(tester, const DataEditorPage(), w);
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });

  group('响应式断点', () {
    test('375 / 768 归为紧凑或中等，1024 / 1440 归为展开', () {
      expect(375 < AppBreakpoints.compact, isTrue);
      expect(768 >= AppBreakpoints.compact, isTrue);
      expect(768 < AppBreakpoints.expanded, isTrue);
      expect(1024 >= AppBreakpoints.compact, isTrue);
      expect(1440 >= AppBreakpoints.expanded, isTrue);
      expect(AppBreakpoints.contentMaxWidth, lessThanOrEqualTo(1024));
    });
  });
}

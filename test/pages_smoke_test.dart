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

const _seed = Color(0xFF2F6FED);

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
    );

void main() {
  /// 让测试窗口用 1:1 像素比，并给定逻辑尺寸。
  void useSize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  group('数据编辑器', () {
    setUp(() {
      datasetStore.replace(Dataset.demoScores(zh: false));
    });

    testWidgets('两个视图可切换，变量视图列出全部变量', (tester) async {
      useSize(tester, const Size(1000, 800));
      await tester.pumpWidget(_app(const DataEditorPage()));
      await tester.pumpAndSettle();

      expect(find.text('Data View'), findsOneWidget);
      expect(find.text('Variable View'), findsOneWidget);

      await tester.tap(find.text('Variable View'));
      await tester.pumpAndSettle();

      for (final name in ['id', 'gender', 'method', 'pre', 'post', 'hours']) {
        expect(find.text(name), findsOneWidget, reason: '缺少变量 $name');
      }

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('搜索框过滤变量，展开卡片可编辑属性', (tester) async {
      useSize(tester, const Size(1000, 800));
      await tester.pumpWidget(_app(const DataEditorPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Variable View'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'gen');
      await tester.pumpAndSettle();

      expect(find.text('gender'), findsOneWidget);
      expect(find.text('method'), findsNothing);
      expect(find.text('hours'), findsNothing);

      // 展开后暴露标签 / 尺度 / 类型 / 值标签 / 缺失值等编辑入口
      await tester.tap(find.text('gender'));
      await tester.pumpAndSettle();
      expect(find.text('Value labels'), findsOneWidget);
      expect(find.text('Missing values'), findsOneWidget);
      expect(find.text('Delete variable'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('学习模块', () {
    testWidgets('学习首页按类别分组列出课程', (tester) async {
      await tester.pumpWidget(_app(const LearnPage()));
      expect(find.text('From concepts to formulas'), findsOneWidget);
      expect(find.text('Getting started'), findsOneWidget);
      expect(find.text('Descriptive statistics'), findsOneWidget);
    });

    testWidgets('课程详情展示要点与核心公式', (tester) async {
      useSize(tester, const Size(800, 1600));
      await tester.pumpWidget(
        _app(LessonDetailPage(lesson: learnLessons.first)),
      );
      expect(find.text('Why descriptive statistics'), findsOneWidget);
      expect(find.text('Mean and median'), findsOneWidget);
      expect(find.text('Core formulas'), findsOneWidget);
    });

    testWidgets('切换到中文后内容为中文', (tester) async {
      await tester.pumpWidget(
        _app(const LearnPage(), locale: const Locale('zh')),
      );
      expect(find.text('从概念到公式'), findsOneWidget);
      expect(find.text('描述统计基础'), findsOneWidget);
    });
  });

  group('测试模块', () {
    testWidgets('抽题、作答、交卷并展示成绩与回顾', (tester) async {
      useSize(tester, const Size(900, 900));
      await tester.pumpWidget(_app(const QuizPage()));

      expect(find.text('Random questions · instant scoring'), findsOneWidget);
      expect(find.text('Number of questions'), findsOneWidget);

      await tester.tap(find.text('Start quiz'));
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 10'), findsOneWidget);

      // 逐题前进到最后一题
      for (var i = 0; i < 9; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Question 10 of 10'), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // 未作答时二次确认
      expect(find.textContaining('unanswered'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Submit'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your score'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.textContaining(' / 10'), findsOneWidget);
    });
  });
}

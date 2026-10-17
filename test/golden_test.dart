@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_runner.dart';
import 'package:stats_flutter/features/data_editor/data_editor_page.dart';
import 'package:stats_flutter/features/learn/learn_content.dart';
import 'package:stats_flutter/features/learn/learn_page.dart';
import 'package:stats_flutter/features/learn/lesson_detail_page.dart';
import 'package:stats_flutter/features/output/output_store.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/quiz/quiz_page.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';
import 'package:stats_flutter/shared/ui/charts/charts.dart';
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
  setUpAll(() async {
    await _loadAppFonts();
    // 报告末尾的「生成时间」来自真实时钟；golden 里固定它才能复现。
    AnalysisReport.clock = () => DateTime(2026, 1, 1, 9, 0);
  });

  setUp(() {
    // 输出树是会话级的静态状态：每条用例从空输出开始，否则同一分析的
    // 上一次报告会留在树里，让 `find.text('post')` 之类的查找变歧义。
    OutputStore.reset();
  });

  Future<void> snap(
    WidgetTester tester, {
    required Widget page,
    required Size size,
    required bool dark,
    required String name,
    Future<void> Function(WidgetTester tester)? before,
    Finder? target,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(page, dark: dark));
    await tester.pumpAndSettle();
    if (before != null) await before(tester);
    await expectLater(
      target ?? find.byType(MaterialApp),
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

  /// 数据表格冻结首列（宽屏）：行号 + 首个变量列不随横向滚动。
  testWidgets('数据表格 · 冻结首列 · 宽屏 · 浅色', (t) async {
    datasetStore.replace(_gridDataset());
    await snap(
      t,
      page: const DataEditorPage(),
      size: wide,
      dark: false,
      name: 'grid_frozen_wide_light',
      // 让数据集替换触发的自动保存防抖计时器走完，避免测试结束时报「仍有计时器」
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
      },
    );
  });

  /// 箱线图：真实绘制须 / 四分位箱 / 中位数 / 均值 / 离群点。
  testWidgets('箱线图 · 手机 · 浅色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'boxplot', title: 'Box plot'),
      size: const Size(390, 2400),
      dark: false,
      name: 'boxplot_phone_light',
      target: find.byType(ChartCard).first,
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.text('post'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// 箱线图 · 手机 · 深色（同一份数据，验证深色下的中位线/离群点对比度）。
  testWidgets('箱线图 · 手机 · 深色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'boxplot', title: 'Box plot'),
      size: const Size(390, 2400),
      dark: true,
      name: 'boxplot_phone_dark',
      target: find.byType(ChartCard).first,
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.text('post'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// 分组箱线图：按 method 分 3 组并列（多组布局）。
  testWidgets('分组箱线图 · 宽屏 · 浅色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'boxplot', title: 'Box plot'),
      size: const Size(760, 2400),
      dark: false,
      name: 'boxplot_grouped_light',
      target: find.byType(ChartCard).first,
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.text('post'));
        await tester.pumpAndSettle();
        // 「分组变量（可选）」下拉 → method（3 组）
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('method').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// 误差条图：均值 ± 95% CI，含总体均值参考线与图例。
  testWidgets('误差条图 · 手机 · 深色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'errorbar', title: 'Error bar'),
      size: const Size(390, 2400),
      dark: true,
      name: 'errorbar_phone_dark',
      target: find.byType(ChartCard).first,
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.text('post'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// Q-Q 图：45° 参考线 + 理论/样本分位轴标题 + 偏离最大的点。
  testWidgets('Q-Q 图 · 手机 · 浅色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'qqplot', title: 'Q-Q plot'),
      size: const Size(390, 2400),
      dark: false,
      name: 'qq_phone_light',
      target: find.byType(ChartCard).first,
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.text('post'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// 协方差分析：参数区（因变量 / 因子 / 协变量）+ 类型 III 表 +
  /// 协变量斜率 + 原始/调整均值三张表（v1.4.0 新增）。
  testWidgets('协方差分析 · 宽屏 · 浅色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'ancova', title: 'ANCOVA'),
      size: const Size(760, 1500),
      dark: false,
      name: 'ancova_wide_light',
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        // 因变量 → post
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('post').last);
        await tester.pumpAndSettle();
        // 因子 A → method（3 组）
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('method').last);
        await tester.pumpAndSettle();
        // 协变量 → pre
        await tester.tap(find.widgetWithText(FilterChip, 'pre'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// 多项 logistic：系数表（Wald / OR / 95% CI）+ 似然比检验 + 混淆矩阵（深色）。
  /// 用宽屏，让 7 列的系数表完整呈现（手机宽度下表格本身可横向滚动）。
  testWidgets('多项 logistic · 宽屏 · 深色', (t) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await snap(
      t,
      page: const AnalysisRunner(analysisId: 'multinomial', title: 'Multinomial logistic'),
      size: const Size(760, 1900),
      dark: true,
      name: 'multinomial_wide_dark',
      before: (tester) async {
        await tester.pump(const Duration(seconds: 3));
        // 因变量 → method（3 类）
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('method').last);
        await tester.pumpAndSettle();
        // 自变量 → pre, hours
        await tester.tap(find.widgetWithText(FilterChip, 'pre'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, 'hours'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run analysis'));
        await tester.pumpAndSettle();
      },
    );
  });

  /// 碎石图：特征值折线 + 肘部虚线标记。
  testWidgets('碎石图 · 手机 · 浅色', (t) async {
    await snap(
      t,
      page: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(12),
          child: ChartCard(
            title: 'Scree plot',
            height: 300,
            child: ScreePlot(eigenvalues: [4.2, 1.6, 0.9, 0.6, 0.4]),
          ),
        ),
      ),
      size: const Size(390, 420),
      dark: false,
      name: 'scree_phone_light',
    );
  });
}

/// 宽屏下必然横向溢出的表格（16 列 × 40 行）。
Dataset _gridDataset() => Dataset(
      name: 'wide',
      variables: [
        for (var c = 0; c < 16; c++)
          Variable(name: 'v${(c + 1).toString().padLeft(2, '0')}', decimals: 1),
      ],
      cases: [
        for (var r = 0; r < 40; r++)
          [for (var c = 0; c < 16; c++) r * 10 + c],
      ],
    );

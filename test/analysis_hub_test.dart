import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/analysis/analysis_catalog.dart';
import 'package:stats_flutter/features/analysis/analysis_hub.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/analysis_prefs.dart';

const _seed = Color(0xFF2F6FED);

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
    );

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await analysisPrefs.load();
  });

  testWidgets('按分类渲染分析目录，首个分类默认展开', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const AnalysisHub()));
    await tester.pumpAndSettle();

    // 第一个分类的标题与条目可见
    final firstCategory = analysisCatalog.first;
    expect(find.text(firstCategory.title(l10n)), findsOneWidget);
    for (final item in firstCategory.items) {
      expect(find.text(item.title(l10n)), findsOneWidget,
          reason: '首个分类应展示 ${item.id}');
    }

    // 目录总量与分类数对齐
    final total = analysisCatalog
        .expand((c) => c.items)
        .map((i) => i.id)
        .toSet()
        .length;
    expect(total, greaterThanOrEqualTo(30));
    expect(analysisCatalog.length, greaterThanOrEqualTo(6));
  });

  testWidgets('搜索按标题 / 描述 / id 过滤，并给出空态', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const AnalysisHub()));
    await tester.pumpAndSettle();

    // id 命中：regress -> regression
    await tester.enterText(find.byType(TextField), 'regress');
    await tester.pumpAndSettle();

    expect(find.text(l10n.anResults), findsOneWidget);
    expect(find.text(analysisById('regression')!.title(l10n)), findsOneWidget);
    expect(find.text(analysisById('descriptives')!.title(l10n)), findsNothing);

    // 无命中：空状态
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();
    expect(find.text(l10n.anNoMatch), findsOneWidget);

    // 清空后恢复分类视图
    await tester.tap(find.byTooltip(l10n.cancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.anResults), findsNothing);
    expect(find.text(analysisCatalog.first.title(l10n)), findsOneWidget);
  });

  testWidgets('收藏与取消收藏会写入偏好并出现在收藏区', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 1200);
    addTearDown(tester.view.reset);

    const id = 'descriptives';
    await tester.pumpWidget(_app(const AnalysisHub()));
    await tester.pumpAndSettle();

    expect(analysisPrefs.isFavorite(id), isFalse);
    expect(find.text(l10n.anFavorites), findsNothing);

    // 收藏首个分类的第一条
    await tester.tap(find.byTooltip(l10n.addFavorite).first);
    await tester.pumpAndSettle();

    expect(analysisPrefs.isFavorite(id), isTrue);
    expect(find.text(l10n.anFavorites), findsOneWidget);
    // 分类保持展开：收藏区块插入后不再折叠列表
    expect(find.byIcon(Icons.star_border_rounded), findsWidgets);

    // 取消收藏
    await tester.tap(find.byTooltip(l10n.removeFavorite).first);
    await tester.pumpAndSettle();

    expect(analysisPrefs.isFavorite(id), isFalse);
    expect(find.text(l10n.anFavorites), findsNothing);
  });

  testWidgets('点击条目进入分析运行页', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const AnalysisHub()));
    await tester.pumpAndSettle();

    final item = analysisCatalog.first.items.first;
    await tester.tap(find.text(item.title(l10n)));
    await tester.pumpAndSettle();

    // 运行页有 AppBar + 参数区 + 运行按钮
    expect(find.text(item.title(l10n)), findsOneWidget);
    expect(find.text(l10n.runAnalysis), findsOneWidget);
  });
}

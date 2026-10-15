import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/core/theme/design_tokens.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/ui/ui.dart';

const _seed = Color(0xFF2F6FED);

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      darkTheme: AppTheme.dark(_seed),
      home: Scaffold(body: child),
    );

void main() {
  group('设计令牌 / 主题', () {
    test('间距与圆角为递增的有序刻度', () {
      expect(AppSpacing.x1, lessThan(AppSpacing.x2));
      expect(AppSpacing.x2, lessThan(AppSpacing.x3));
      expect(AppSpacing.x3, lessThan(AppSpacing.x4));
      expect(AppSpacing.x4, lessThan(AppSpacing.x5));
      expect(AppSpacing.x5, lessThan(AppSpacing.x6));
      expect(AppRadius.sm, lessThan(AppRadius.lg));
    });

    test('明暗主题都注册 AppColors，并含 6 色图表色板', () {
      for (final theme in [AppTheme.light(_seed), AppTheme.dark(_seed)]) {
        final app = theme.extension<AppColors>();
        expect(app, isNotNull);
        expect(app!.chart, hasLength(6));
        expect(app.chartAt(7), app.chart[1]); // 循环取色
        expect(app.shadowSm, isNotEmpty);
        expect(app.shadowMd, isNotEmpty);
        expect(app.shadowLg, isNotEmpty);
      }
    });

    test('语义色在明暗模式下不同（保证对比度）', () {
      final light = AppColors.light;
      final dark = AppColors.dark;
      expect(light.success, isNot(dark.success));
      expect(light.negative, isNot(dark.negative));
      expect(light.missing, isNot(dark.missing));
    });

    test('tabularText 保留字体特征并强制等宽数字', () {
      final s = AppTheme.tabularText(const TextStyle(fontSize: 12));
      expect(s.fontFeatures, isNotNull);
      expect(s.fontFeatures!.any((f) => f.feature == 'tnum'), isTrue);
    });
  });

  group('AppCard / SectionHeader / StatTile', () {
    testWidgets('AppCard 渲染内容并响应点按', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(AppCard(
          onTap: () => tapped = true,
          child: const Text('card-body'),
        )),
      );
      expect(find.text('card-body'), findsOneWidget);
      await tester.tap(find.text('card-body'));
      expect(tapped, isTrue);
    });

    testWidgets('SectionHeader 渲染标题、副标题与尾部动作', (tester) async {
      await tester.pumpWidget(
        _host(const SectionHeader(
          title: 'Overview',
          subtitle: 'sub',
          icon: Icons.info_outline,
          trailing: Text('trail'),
        )),
      );
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('sub'), findsOneWidget);
      expect(find.text('trail'), findsOneWidget);
    });

    testWidgets('StatTile / StatChip 渲染数值与标签', (tester) async {
      await tester.pumpWidget(
        _host(const Column(
          children: [
            StatTile(value: '128', label: 'Cases', unit: 'n'),
            StatChip(label: 'Vars', value: '6'),
          ],
        )),
      );
      expect(find.text('128'), findsOneWidget);
      expect(find.text('Cases'), findsOneWidget);
      expect(find.text('Vars'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });
  });

  group('EmptyState / 骨架屏', () {
    testWidgets('EmptyState 展示标题、说明与主行动', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        _host(EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing here',
          message: 'Add some data',
          actionLabel: 'Add',
          onAction: () => acted = true,
        )),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add some data'), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(acted, isTrue);
    });

    testWidgets('骨架屏渲染占位块', (tester) async {
      await tester.pumpWidget(
        _host(const SkeletonList(count: 3)),
      );
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('ParamVarPicker', () {
    testWidgets('多选累积选择并通过回调上报', (tester) async {
      var sel = <String>[];
      await tester.pumpWidget(
        _host(StatefulBuilder(
          builder: (ctx, setState) => ParamVarPicker(
            label: 'Variables',
            names: const ['a', 'b', 'c'],
            selected: sel,
            onChanged: (v) => setState(() => sel = v),
          ),
        )),
      );
      await tester.tap(find.text('a'));
      await tester.pumpAndSettle();
      expect(sel, ['a']);

      await tester.tap(find.text('b'));
      await tester.pumpAndSettle();
      expect(sel, containsAll(['a', 'b']));
    });

    testWidgets('单选模式替换而非累积', (tester) async {
      var sel = <String>[];
      await tester.pumpWidget(
        _host(StatefulBuilder(
          builder: (ctx, setState) => ParamVarPicker(
            label: 'Y',
            single: true,
            names: const ['x', 'y'],
            selected: sel,
            onChanged: (v) => setState(() => sel = v),
          ),
        )),
      );
      await tester.tap(find.text('x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('y'));
      await tester.pumpAndSettle();
      expect(sel, ['y']);
    });

    testWidgets('变量较多时可搜索过滤，无命中给出空提示', (tester) async {
      await tester.pumpWidget(
        _host(ParamVarPicker(
          label: 'Variables',
          names: const ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta',
              'eta', 'theta'],
          selected: const [],
          onChanged: (_) {},
        )),
      );
      expect(find.text('alpha'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('alpha'), findsNothing);
      expect(find.text('No matching variables'), findsOneWidget);
    });
  });

  group('SignificanceBadge', () {
    testWidgets('渲染星级并暴露本地化的语义标签', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const SignificanceBadge(p: 0.004, stars: '**')),
      );
      expect(find.text('**'), findsOneWidget);
      final node = tester.getSemantics(find.byType(SignificanceBadge));
      expect(node.label, contains('**'));
      expect(node.label.toLowerCase(), contains('significance'));
      handle.dispose();
    });

    testWidgets('空星级时不渲染文本', (tester) async {
      await tester.pumpWidget(
        _host(const SignificanceBadge(p: 0.5)),
      );
      expect(find.byType(SignificanceBadge), findsOneWidget);
      expect(find.text('*'), findsNothing);
    });
  });

  group('响应式导航', () {
    const items = [
      NavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Home'),
      NavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Settings'),
    ];

    testWidgets('窄屏用底部栏，宽屏用侧栏', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 840);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(AdaptiveNavScaffold(
          index: 0,
          onIndexChanged: (_) {},
          items: items,
          body: const Text('body'),
        )),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      tester.view.physicalSize = const Size(1100, 840);
      await tester.pumpWidget(
        _host(AdaptiveNavScaffold(
          index: 0,
          onIndexChanged: (_) {},
          items: items,
          body: const Text('body'),
        )),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    test('断点分类互斥', () {
      expect(AppBreakpoints.compact, lessThan(AppBreakpoints.medium));
      expect(AppBreakpoints.medium, lessThan(AppBreakpoints.expanded));
      expect(AppBreakpoints.useRail, isNotNull);
    });
  });

  group('确认对话框', () {
    testWidgets('返回 true / false', (tester) async {
      late Future<bool> result;
      await tester.pumpWidget(_host(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () {
            result = showConfirmDialog(
              ctx,
              title: 'Reset?',
              message: 'This cannot be undone.',
              confirmLabel: 'Reset',
              danger: true,
            );
          },
          child: const Text('open'),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('This cannot be undone.'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });
}

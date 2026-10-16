/// v1.3.1 M4：入场 stagger（含 reduced-motion）、定制焦点环、键盘遍历。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/data_editor/editable_data_grid.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';
import 'package:stats_flutter/shared/ui/ui.dart';

const _seed = Color(0xFF2F6FED);

Widget _host(Widget home, {bool disableAnimations = false}) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
      builder: disableAnimations
          ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
          : null,
    );

void main() {
  group('焦点环', () {
    /// 卡片是否正在显示焦点环（AppFocus.ring 以 BoxShadow 形式绘制）。
    bool ringShown(WidgetTester tester, int cardIndex) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppCard).at(cardIndex),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final shadows = (box.decoration as BoxDecoration).boxShadow ?? const [];
      return shadows.isNotEmpty;
    }

    List<bool> rings(WidgetTester tester) =>
        [ringShown(tester, 0), ringShown(tester, 1)];

    Future<void> pumpTwoCards(WidgetTester tester, void Function() onTap) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 240,
                    child: AppCard(
                      onTap: onTap,
                      child: const Text('first card'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 240,
                    child: AppCard(
                      onTap: onTap,
                      child: const Text('second card'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('键盘聚焦显示焦点环，触摸点击不留常驻焦点环', (tester) async {
      var taps = 0;
      await pumpTwoCards(tester, () => taps++);

      expect(rings(tester), [false, false], reason: '初始无焦点环');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(rings(tester), [true, false], reason: 'Tab 聚焦到第一张卡片');

      // 触摸点击（InkWell 会拿焦点，但高亮模式为 touch）→ 不应留下焦点环
      await tester.tap(find.byType(AppCard).first);
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(rings(tester), [false, false], reason: '触摸点击不留焦点环');
    });

    testWidgets('焦点环不额外占用 Tab 停靠点', (tester) async {
      await pumpTwoCards(tester, () {});

      // 每张卡片恰好一个 Tab 停靠点：第一次到第一张，第二次到第二张，
      // 第三次回到第一张（整棵树的遍历环，而不是第三个「隐形」停靠点）。
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(rings(tester), [true, false]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(rings(tester), [false, true], reason: '第二次 Tab 直接到第二张卡片');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        rings(tester),
        [true, false],
        reason: '第三次 Tab 回到第一张（恰好两个停靠点，无隐形停靠点）',
      );
    });
  });

  group('入场 stagger', () {
    Finder innerOpacity() => find.descendant(
          of: find.byType(StaggeredItem),
          matching: find.byType(Opacity),
        );

    testWidgets('首帧在入场中，动画结束后不再包 Opacity', (tester) async {
      await tester.pumpWidget(
        _host(const Scaffold(body: StaggeredItem(index: 0, child: Text('item')))),
      );

      expect(innerOpacity(), findsOneWidget, reason: '首帧应处于入场动画中');
      await tester.pumpAndSettle();
      expect(innerOpacity(), findsNothing, reason: '动画结束后直接渲染子节点');
    });

    testWidgets('reduced-motion 下直接落到终态', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: StaggeredItem(index: 4, child: Text('item'))),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(innerOpacity(), findsNothing, reason: '系统关闭动效时不播放入场动画');
      expect(find.text('item'), findsOneWidget);
    });

    testWidgets('长列表最后一个项目的总时长不超过 300ms', (tester) async {
      // index 很大时延迟被截断：不需要等 index × 24ms
      await tester.pumpWidget(
        _host(
          const Scaffold(
            body: StaggeredItem(index: 60, child: Text('last')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(innerOpacity(), findsNothing);
    });
  });

  group('数据表格键盘遍历', () {
    Dataset ds() => Dataset(
          name: 'kbd',
          variables: [Variable(name: 'a', decimals: 1)],
          cases: [
            [1.0],
            [2.0],
          ],
        );

    Future<void> pumpGrid(WidgetTester tester, {FocusNode? after}) async {
      datasetStore.replace(ds());
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Column(
              children: [
                const Expanded(child: EditableDataGrid()),
                if (after != null)
                  Focus(focusNode: after, child: const SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 释放数据集替换触发的自动保存防抖计时器
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('Esc 放弃编辑并还原原值', (tester) async {
      await pumpGrid(tester);

      // 测试宿主平台不是手机，单击不进入编辑（桌面用长按 / 双击），
      // 这里用长按，跨平台行为一致。
      await tester.longPress(find.text('1.0'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget, reason: '长按进入编辑');

      await tester.enterText(find.byType(TextField), '99');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing, reason: 'Esc 退出编辑');
      expect(find.text('1.0'), findsOneWidget, reason: 'Esc 放弃修改');
      expect(find.text('99'), findsNothing);
    });

    testWidgets('Tab 提交并右移，未编辑时能离开网格', (tester) async {
      final after = FocusNode(debugLabel: 'afterGrid');
      addTearDown(after.dispose);
      await pumpGrid(tester, after: after);

      await tester.longPress(find.text('1.0'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      // 只有一列，Tab 会先提交再尝试右移（越界即停在原地）；
      // 数值列按 decimals: 1 显示为 5.0
      expect(find.text('5.0'), findsOneWidget, reason: 'Tab 提交了编辑');
      expect(find.text('1.0'), findsNothing, reason: '原值已被替换');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      var moved = 0;
      while (!after.hasFocus && moved < 8) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        moved++;
      }
      expect(after.hasFocus, isTrue, reason: '未编辑时 Tab 不应被网格困住');
    });

    testWidgets('方向键移动选中单元格，Enter 从选中格进入编辑', (tester) async {
      datasetStore.replace(
        Dataset(
          name: 'kbd2',
          variables: [
            Variable(name: 'a', decimals: 1),
            Variable(name: 'b', decimals: 1),
          ],
          cases: [
            [1.0, 10.0],
            [2.0, 20.0],
          ],
        ),
      );
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const Scaffold(body: EditableDataGrid())));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      String editorText() =>
          tester.widget<TextField>(find.byType(TextField)).controller!.text;

      // 单击第 1 行第 1 列：桌面端只选中、不进入编辑
      await tester.tap(find.text('1.0'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing, reason: '桌面端单击不进入编辑');

      // → 到第 2 列，Enter 开始编辑
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget, reason: 'Enter 从选中格进入编辑');
      expect(editorText(), '10.0', reason: '→ 把选中格右移一列');

      // Esc 退出，↓ 到第 2 行，Enter 再编辑
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(editorText(), '20.0', reason: '↓ 把选中格下移一行');
    });
  });
}

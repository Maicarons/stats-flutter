/// 数据表格冻结首列（v1.3.1）：
/// - 宽屏（≥ 600）：行号列 + 首个变量列冻结，横向滚动只移动其余列，纵向滚动两区同步；
/// - 窄屏：只冻结行号列，变量列全部参与横向滚动。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/data_editor/editable_data_grid.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';

const _seed = Color(0xFF2F6FED);

Widget _host(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: home,
    );

/// 16 列 × 40 行（1 位小数，显示值形如 `12.0`，与行号 `12` 不会混淆）：
/// 列宽下限 72px，宽屏下必然横向溢出。
Dataset _wideDataset() => Dataset(
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

void main() {
  setUp(() {
    datasetStore.replace(_wideDataset());
  });

  /// 给定窗口尺寸渲染表格。
  Future<void> pumpGrid(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const Scaffold(body: EditableDataGrid())));
    await tester.pumpAndSettle();
  }

  /// 纵向滚动位置（冻结区 + 滚动区各一个）。
  List<ScrollPosition> verticalPositions(WidgetTester tester) => tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .map((s) => s.position)
      .where((p) => p.axis == Axis.vertical)
      .toList();

  // 冻结列（v01）首行值 / 滚动列（v03）首行值，均唯一
  const frozenCell = '0.0';
  const scrolledCell = '2.0';

  testWidgets('宽屏：横向滚动只移动非冻结列', (tester) async {
    await pumpGrid(tester, const Size(900, 600));

    expect(find.text('v01'), findsOneWidget);
    expect(find.text('v03'), findsOneWidget);
    final frozenBefore = tester.getTopLeft(find.text(frozenCell));
    final scrolledBefore = tester.getTopLeft(find.text(scrolledCell));

    await tester.drag(find.text(scrolledCell), const Offset(-120, 0));
    await tester.pumpAndSettle();

    // 冻结列原位不动
    expect(tester.getTopLeft(find.text(frozenCell)), frozenBefore);
    // 非冻结列随横向滚动左移
    expect(
      tester.getTopLeft(find.text(scrolledCell)).dx,
      lessThan(scrolledBefore.dx - 60),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏：纵向滚动两区逐像素同步', (tester) async {
    await pumpGrid(tester, const Size(900, 600));

    final before = verticalPositions(tester);
    expect(before.length, 2, reason: '冻结区与滚动区各一个纵向滚动视图');
    expect(before[0].pixels, 0);
    expect(before[1].pixels, 0);

    await tester.drag(find.text(scrolledCell), const Offset(0, -102));
    await tester.pumpAndSettle();

    final after = verticalPositions(tester);
    expect(after[1].pixels, greaterThan(0), reason: '滚动区应向下滚动');
    expect(after[0].pixels, greaterThan(0), reason: '冻结区应跟随');
    expect(after[0].pixels, closeTo(after[1].pixels, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏：拖冻结区，滚动区跟随', (tester) async {
    await pumpGrid(tester, const Size(900, 600));

    await tester.drag(find.text(frozenCell), const Offset(0, -80));
    await tester.pumpAndSettle();

    final after = verticalPositions(tester);
    expect(after[0].pixels, greaterThan(0), reason: '冻结区应向下滚动');
    expect(after[1].pixels, greaterThan(0), reason: '滚动区应跟随');
    expect(after[0].pixels, closeTo(after[1].pixels, 0.5));
  });

  testWidgets('窄屏：只冻结行号列，变量列随横向滚动', (tester) async {
    await pumpGrid(tester, const Size(375, 700));

    final before = tester.getTopLeft(find.text(frozenCell));

    await tester.drag(find.text(frozenCell), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text(frozenCell)).dx,
      lessThan(before.dx - 60),
      reason: '窄屏下首个变量列不应被冻结',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1 万行只构建视口内的行（虚拟化未被冻结列破坏）', (tester) async {
    datasetStore.replace(
      Dataset(
        name: 'big',
        variables: [
          Variable(name: 'a', decimals: 1),
          Variable(name: 'b', decimals: 1),
        ],
        cases: [
          for (var i = 0; i < 10000; i++)
            [i.toDouble(), (i * 2).toDouble()],
        ],
      ),
    );
    await pumpGrid(tester, const Size(900, 600));

    // 每个可视单元格一个 Listener（1 万行 × 2 列全量构建会是 2 万个）
    final built = find.byType(Listener).evaluate().length;
    expect(built, lessThan(200), reason: '只应构建视口内的行，实际 $built');

    // 视口外的行不构建
    expect(find.text('9999.0'), findsNothing);
    expect(find.text('0.0'), findsWidgets, reason: '首行在视口内');
    expect(tester.takeException(), isNull);
  });
}

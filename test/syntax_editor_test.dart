/// v1.5.0 M3.4 / M3.5：语法编辑器——结果带行列、可点击跳转；`.sps` 往返。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/core/theme/app_theme.dart';
import 'package:stats_flutter/features/syntax/syntax_editor_page.dart';
import 'package:stats_flutter/features/syntax/syntax_highlight_controller.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';
import 'package:stats_flutter/shared/dataset_store.dart';

const _seed = Color(0xFF2F6FED);

Widget _app() => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(_seed),
      home: const SyntaxEditorPage(),
    );

/// 两行小数据集：`LIST` 输出短，结果卡片都留在可视区
Dataset _small() {
  final d = Dataset(name: 'small');
  d.addVariable(Variable(name: 'score'));
  d.addCase(<Object?>[1]);
  d.addCase(<Object?>[2]);
  return d;
}

TextEditingController _code(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!;

Future<void> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1000, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

Future<void> _setCode(WidgetTester tester, String text) async {
  _code(tester).text = text;
  await tester.pumpAndSettle();
}

Future<void> _runCode(WidgetTester tester) async {
  await tester.tap(find.text('Run syntax'));
  await tester.pumpAndSettle();
}

/// 收尾：`datasetStore` 的自动保存有 2 秒去抖计时器，必须让它跑完
Future<void> _settleTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets('默认模板：注释以句点结尾，全部命令成功', (tester) async {
    datasetStore.replace(Dataset.demoScores(zh: false));
    await _pump(tester);
    expect(_code(tester).text, contains('* Stats-flutter syntax demo.'));
    await _runCode(tester);
    expect(find.text('Done: 6 ok, 0 failed'), findsOneWidget);
    expect(find.textContaining('DESCRIPTIVES'), findsWidgets);
    await _settleTimers(tester);
  });

  testWidgets('失败结果带行号，点击跳回源码该行', (tester) async {
    datasetStore.replace(_small());
    await _pump(tester);
    await _setCode(tester, 'LIST.\nNOPE.\nLIST.');
    await _runCode(tester);

    expect(find.text('Done: 2 ok, 1 failed'), findsOneWidget);
    expect(find.text('Line 2'), findsOneWidget);

    await tester.tap(find.text('NOPE'));
    await tester.pumpAndSettle();
    // `LIST.\n` 共 6 字符 → NOPE 的起点
    expect(_code(tester).selection.baseOffset, 6);
    expect(_code(tester).selection.extentOffset, 10);
    await _settleTimers(tester);
  });

  testWidgets('提示（注释吞掉后续命令）标为 Hint 而不是失败', (tester) async {
    datasetStore.replace(_small());
    await _pump(tester);
    await _setCode(tester, '* 忘了句点\nLIST.');
    await _runCode(tester);

    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('Done: 1 ok, 0 failed'), findsOneWidget);
    await _settleTimers(tester);
  });

  testWidgets('光标位置行/列随选区更新', (tester) async {
    datasetStore.replace(_small());
    await _pump(tester);
    await _setCode(tester, 'LIST.\nDESCRIPTIVES score.');
    expect(find.text('Ln 1, Col 1'), findsOneWidget);

    _code(tester).selection = const TextSelection.collapsed(offset: 6);
    await tester.pumpAndSettle();
    expect(find.text('Ln 2, Col 1'), findsOneWidget);

    _code(tester).selection = const TextSelection.collapsed(offset: 10);
    await tester.pumpAndSettle();
    expect(find.text('Ln 2, Col 5'), findsOneWidget);
    await _settleTimers(tester);
  });

  testWidgets('高亮：已实现动词按命令色，未实现的动词不上色，注释与 !宏 有独立颜色',
      (tester) async {
    final ctrl = SyntaxHighlightController(
      text: 'SORT CASES BY score.\n'
          'COMMENT 说明.\n'
          '!desc score.\n'
          'WEIGHT BY score.\n',
    );
    addTearDown(ctrl.dispose);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(_seed),
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return TextField(controller: ctrl);
        }),
      ),
    ));
    final scheme = Theme.of(ctx).colorScheme;
    final span = ctrl.buildTextSpan(context: ctx, withComposing: false);
    final styles = <String, Color?>{};
    span.visitChildren((s) {
      if (s is TextSpan && s.text != null && s.text!.trim().isNotEmpty) {
        styles[s.text!.trim()] = s.style?.color;
      }
      return true;
    });
    expect(styles['SORT'], scheme.primary, reason: '已实现动词应按命令色');
    expect(styles['COMMENT 说明.'], scheme.outline, reason: 'COMMENT 行整体是注释色');
    expect(styles['!desc'], macroHighlightColor, reason: '!宏 应有独立颜色');
    expect(styles['WEIGHT'], isNot(scheme.primary),
        reason: 'WEIGHT 本版未实现，不应高亮成命令');
  });
}

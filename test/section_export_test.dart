/// v1.3.1 M5：报告分区导出菜单（复制 / 导出 Markdown / 导出 HTML）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/output/report_export.dart';
import 'package:stats_flutter/features/output/section_export_menu.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

const _section = ReportSection(
  heading: 'Group statistics',
  slug: 'descriptives',
  body: 'Two groups compared.',
  tables: [
    ReportTable(
      headers: ['Group', 'n', 'p'],
      rows: [
        ['A', '12', '.023'],
      ],
      caption: 'Table 1',
    ),
  ],
  notes: 'Equal variances assumed.',
);

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('导出的文件名与内容：Markdown / HTML', () {
    const menu = SectionExportMenu(
      section: _section,
      reportTitle: 'T-Test',
      index: 0,
    );

    expect(menu.fileName(html: false), 'stats-T-Test-descriptives-${_stamp()}.md');
    expect(menu.fileName(html: true), 'stats-T-Test-descriptives-${_stamp()}.html');

    final md = menu.content(html: false);
    expect(md, contains('# T-Test'));
    expect(md, contains('| Group | n | p |'));

    final html = menu.content(html: true);
    expect(html, startsWith('<!DOCTYPE html>'));
    expect(html, contains('<h1>T-Test</h1>'));
  });

  testWidgets('菜单三项：复制 / 导出 Markdown / 导出 HTML', (tester) async {
    await tester.pumpWidget(
      _host(
        const SectionExportMenu(
          section: _section,
          reportTitle: 'T-Test',
          index: 0,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Copy section'), findsOneWidget);
    expect(find.text('Export Markdown'), findsOneWidget);
    expect(find.text('Export HTML'), findsOneWidget);
  });

  testWidgets('复制本节：剪贴板拿到 Markdown（含报告标题）', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _host(
        const SectionExportMenu(
          section: _section,
          reportTitle: 'T-Test',
          index: 0,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy section'));
    await tester.pumpAndSettle();

    final copy = calls.where((c) => c.method == 'Clipboard.setData').toList();
    expect(copy, hasLength(1), reason: '应调用一次剪贴板写入');
    final text = (copy.single.arguments as Map)['text'] as String;
    expect(text, startsWith('# T-Test'));
    expect(text, contains('## Group statistics'));
    expect(text, contains('> Equal variances assumed.'));

    // 复制成功提示
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });
}

/// 与 [sectionFileBase] 的默认日期戳一致（今天）。
String _stamp() {
  final d = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}';
}

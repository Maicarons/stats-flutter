import 'package:flutter_test/flutter_test.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/output/report_export.dart';

AnalysisReport _report() => AnalysisReport(
      title: 'T-Test <独立样本>',
      subtitle: 'Independent samples',
      createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      sections: [
        ReportSection(
          heading: 'Group statistics',
          body: 'Two groups compared.',
          tables: [
            ReportTable(
              headers: const ['Group', 'n', 'Mean', 'SD', 'p'],
              rows: const [
                ['A', '12', '78.40', '5.20', '.023'],
                ['B', '13', '71.10', '6.80', '<.001'],
                ['C', '11', '70.05', '6.10', '.412'],
              ],
              caption: 'Table 1',
            ),
          ],
          notes: 'Equal variances assumed.',
        ),
      ],
    );

void main() {
  test('纯文本导出包含标题、分区与表格表头', () {
    final txt = _report().toPlainText();
    expect(txt, contains('T-Test'));
    expect(txt, contains('## Group statistics'));
    expect(txt, contains('Mean'));
  });

  test('Markdown 导出包含标题、引用块与表格分隔行', () {
    final md = reportToMarkdown(_report());
    expect(md, contains('# T-Test'));
    expect(md, contains('**Independent samples**'));
    expect(md, contains('## Group statistics'));
    expect(md, contains('| Group | n | Mean | SD | p |'));
    expect(md, contains('| --- | --- | --- | --- | --- |'));
    expect(md, contains('> Equal variances assumed.'));
  });

  test('HTML 导出：结构完整、转义、数值列右对齐', () {
    final html = reportToHtml(_report());

    expect(html, contains('<!DOCTYPE html>'));
    expect(html, contains('<table>'));
    expect(html, contains('<th>Mean</th>'));
    // 标题里的 < > 被转义，注入无效
    expect(html, contains('&lt;独立样本&gt;'));
    expect(html, isNot(contains('<独立样本>')));
    // 数值列（n / Mean / SD）右对齐
    expect(html, contains('class="num"'));
  });

  test('HTML 导出：p 值列按显著性加星并着色', () {
    final html = reportToHtml(_report());
    // .023 -> * ；<.001 -> *** ；.412 -> 不显著
    expect(html, contains('<span class="stars">*</span>'));
    expect(html, contains('<span class="stars">***</span>'));
    expect(html, contains('sig'));
    // 不显著的行不加星
    final lines = html.split('\n').where((l) => l.contains('.412'));
    expect(lines, isNotEmpty);
    expect(lines.first.contains('stars'), isFalse);
  });

  test('Markdown 导出不转义 HTML（纯文本语义）', () {
    final md = reportToMarkdown(_report());
    expect(md, contains('<独立样本>'));
  });
}

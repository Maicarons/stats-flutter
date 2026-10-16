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

  group('分区导出', () {
    ReportSection section({String? slug}) => ReportSection(
          heading: 'Group statistics',
          slug: slug,
          body: 'Two groups compared.',
          tables: [
            ReportTable(
              headers: const ['Group', 'n', 'p'],
              rows: const [
                ['A', '12', '.023'],
              ],
              caption: 'Table 1',
            ),
          ],
          notes: 'Equal variances assumed.',
        );

    test('sectionToMarkdown 带报告标题，作为独立文档可读', () {
      final md = sectionToMarkdown(section(), reportTitle: 'T-Test');
      expect(md, startsWith('# T-Test'));
      expect(md, contains('## Group statistics'));
      expect(md, contains('| Group | n | p |'));
      expect(md, contains('> Equal variances assumed.'));
      // 分区导出不应带整份报告的副标题
      expect(md, isNot(contains('Independent samples')));
    });

    test('sectionToHtml 是完整文档且复用整份导出的 CSS 与显著性标注', () {
      final html = sectionToHtml(section(), reportTitle: 'T-Test <A>');
      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, endsWith('</html>\n'));
      expect(html, contains('<style>'));
      expect(html, contains('prefers-color-scheme:dark'));
      expect(html, contains('@media print'));
      expect(html, contains('&lt;A&gt;'));
      expect(html, contains('<h1>T-Test &lt;A&gt;</h1>'));
      expect(html, contains('<h2><span class="rule"></span>Group statistics</h2>'));
      expect(html, contains('class="num"'));
      expect(html, contains('<span class="stars">*</span>'));
      expect(html, contains('<div class="note">Equal variances assumed.</div>'));
    });

    test('fileSafeSlug 只保留 ASCII 字母数字与连字符', () {
      expect(fileSafeSlug('T-Test 独立样本'), 'T-Test');
      expect(fileSafeSlug('描述统计/分组 (n=30)'), 'n-30');
      expect(fileSafeSlug('中文标题'), '');
      expect(fileSafeSlug('--a--b--'), 'a-b');
      expect(fileSafeSlug('x' * 80).length, 48);
    });

    test('sectionFileBase：中文标题回退为分区序号', () {
      final at = DateTime(2026, 10, 15);
      expect(
        sectionFileBase(
          reportTitle: 'T-Test',
          section: section(slug: 'descriptives'),
          index: 0,
          at: at,
        ),
        'stats-T-Test-descriptives-20261015',
      );
      // 没有 slug 且标题是中文 → 回退序号（index 1 → section-2）
      expect(
        sectionFileBase(
          reportTitle: '描述统计',
          section: section(),
          index: 1,
          at: at,
        ),
        'stats-Group-statistics-20261015',
      );
      expect(
        sectionFileBase(
          reportTitle: '描述统计',
          section: ReportSection(heading: '基本信息'),
          index: 1,
          at: at,
        ),
        'stats-section-2-20261015',
      );
    });
  });
}

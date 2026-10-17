/// M4.2a PDF 纵切：中文字体自带、表格/分页/星号可用，并量一下体积与耗时。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/features/output/report_builder.dart';
import 'package:stats_flutter/features/output/report_pdf.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

/// PDF 里的页数：取 `/Count n`（页树节点）里的最大值。
int _pageCount(Uint8List bytes) {
  final s = latin1.decode(bytes, allowInvalid: true);
  final counts = RegExp(r'/Count (\d+)')
      .allMatches(s)
      .map((m) => int.parse(m.group(1)!))
      .toList();
  return counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
}

String _head(Uint8List bytes, int n) =>
    latin1.decode(bytes.sublist(0, n), allowInvalid: true);

/// 排查排版时把生成的 PDF 落盘：
/// `flutter test --dart-define=PDF_DUMP=%TEMP%\report.pdf test/report_pdf_test.dart`
const String _dumpPath = String.fromEnvironment('PDF_DUMP');

Future<void> _maybeDump(Uint8List bytes) async {
  if (_dumpPath.isEmpty) return;
  await File(_dumpPath).writeAsBytes(bytes, flush: true);
}

/// 含中英混排、希腊字母、上下标与全角标点的长报告（同时用于分页验证）。
AnalysisReport _zhReport(AppLocalizations l10n) {
  final byVar = {
    '成绩': Descriptives.compute([78, 85, 91, 66, 72, 88, 95, 81, 74, 90]),
    '满意度': Descriptives.compute([4, 5, 3, 4, 5, 2, 4, 5, 3, 4]),
  };
  final base = reportDescriptives(l10n, byVar, datasetName: '演示数据集');

  // 追加一个长表格 + 一段中文正文，验证分页与断行
  final long = ReportSection(
    heading: '长表格分页检查',
    body: '说明：本段用于检查中文断行与分页行为。显著性水平取 α=0.05，'
        '统计量记为 χ²、η²、ω²，区间写作 [1.00, 2.00]，'
        '含全角标点（，。；：“”《》）与上下标 x₁、x²、H₂O 的混排效果。',
    tables: [
      ReportTable(
        caption: '表 1 逐行数据',
        headers: const ['序号', '变量', 'N', 'Mean', 'SD', 'p'],
        rows: [
          for (var i = 1; i <= 60; i++)
            [
              '$i',
              '变量 $i（第 ${i % 7 + 1} 组）',
              '${i * 3}',
              (i * 1.37).toStringAsFixed(3),
              (i % 5 + 1).toStringAsFixed(3),
              formatP(i % 9 == 0 ? 0.0004 : (i % 3 == 0 ? 0.031 : 0.412)),
            ],
        ],
      ),
    ],
    notes: '注：*** p < .001，** p < .01，* p < .05。',
  );
  return AnalysisReport(
    title: base.title,
    subtitle: base.subtitle,
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    sections: [...base.sections, long],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations zh;

  setUpAll(() async {
    zh = await AppLocalizations.delegate.load(const Locale('zh'));
  });

  test('字体资源可载入：Inter 拉丁 + 中文子集', () async {
    final fonts = await ReportFonts.load();
    expect(fonts.regular.length, greaterThan(100000));
    expect(fonts.bold.length, greaterThan(100000));
    // 中文子集约 2.3 MB：太大说明没子集化，太小说明字形不够
    expect(fonts.cjk.length, inInclusiveRange(1500000, 6000000));
  });

  test('中文报告渲染为 PDF：结构、字体嵌入与体积', () async {
    final fonts = await ReportFonts.load();
    final sw = Stopwatch()..start();
    final bytes = await reportToPdf(_zhReport(zh), fonts: fonts);
    sw.stop();

    final head = _head(bytes, 8);
    expect(head, startsWith('%PDF-1.'));
    expect(latin1.decode(bytes.sublist(bytes.length - 32), allowInvalid: true),
        contains('%%EOF'));
    // 中文子集被嵌入（字体名出现在 FontDescriptor 里）
    expect(latin1.decode(bytes, allowInvalid: true), contains('StatsSansSC'));

    final pages = _pageCount(bytes);
    expect(pages, greaterThanOrEqualTo(2), reason: '60 行长表要翻页');
    expect(bytes.length, greaterThan(20000));
    await _maybeDump(bytes);

    // 结论记录（M4.2a 的量化输出）
    // ignore: avoid_print
    print('[pdf-spike] pages=$pages bytes=${bytes.length} '
        'fonts=${fonts.cjk.length} ms=${sw.elapsedMilliseconds}');
  });

  test('纯中文长正文不抛异常（断行 + 回退字体）', () async {
    final fonts = await ReportFonts.load();
    final report = AnalysisReport(
      title: '中文断行',
      subtitle: '',
      createdAt: DateTime.utc(2026, 1, 2),
      sections: [
        ReportSection(
          heading: '正文',
          body: '这是一段没有任何空格的中文正文，用于验证 PDF 排版能否在汉字之间断行；'
              '如果断行失败，这一行会一直向右溢出页面边界。'
              '“引号”、（括号）、【方括号】、100%％、±1.96、p<.05、①②③ 也要能正常显示。',
        ),
      ],
    );
    final bytes = await reportToPdf(report, fonts: fonts);
    expect(_head(bytes, 5), startsWith('%PDF'));
  });

  test('无分区也能导出（空报告兜底）', () async {
    final fonts = await ReportFonts.load();
    final bytes = await reportToPdf(
      AnalysisReport(
        title: '空报告',
        subtitle: '',
        createdAt: DateTime.utc(2026, 1, 2),
        sections: const [],
      ),
      fonts: fonts,
    );
    expect(_pageCount(bytes), 1);
  });
}

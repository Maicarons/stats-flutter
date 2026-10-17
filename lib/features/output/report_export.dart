/// 报告导出（v1.3）：HTML / Markdown。
/// HTML 版与 App 内报告保持同一视觉语言：细描边卡片、等宽数字、数值右对齐，并支持打印与深色模式。
library;

import '../output/report_builder.dart';
import '../output/report_style.dart';

String reportToHtml(AnalysisReport report, {String title = 'StatLab Report'}) {
  final b = StringBuffer();
  b.writeln('<!DOCTYPE html>');
  b.writeln('<html lang="zh-CN">');
  b.writeln('<head>');
  b.writeln('<meta charset="utf-8">');
  b.writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">');
  b.writeln('<title>${_esc(title)} — ${_esc(report.title)}</title>');
  b.writeln('<style>');
  b.writeln(_css);
  b.writeln('</style></head><body><div class="wrap">');
  b.writeln('<header>');
  b.writeln('<div class="bar"></div>');
  b.writeln('<h1>${_esc(report.title)}</h1>');
  if (report.subtitle.isNotEmpty) {
    b.writeln('<div class="sub">${_esc(report.subtitle)}</div>');
  }
  b.writeln('</header>');

  for (final s in report.sections) {
    _writeSectionHtml(b, s);
  }
  b.writeln(
      '<footer>${_esc(report.title)} · ${report.createdAt.toLocal()} · Stats-flutter</footer>');
  b.writeln('</div></body></html>');
  return b.toString();
}

/// 单个分区的独立 HTML：完整 `<head>` 与整份导出同一套 CSS
/// （配色 / 表格 / 显著性加星 / 暗色 / 打印），可直接打开或分享。
String sectionToHtml(ReportSection section, {required String reportTitle}) {
  final b = StringBuffer();
  b.writeln('<!DOCTYPE html>');
  b.writeln('<html lang="zh-CN">');
  b.writeln('<head>');
  b.writeln('<meta charset="utf-8">');
  b.writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">');
  b.writeln(
      '<title>${_esc(reportTitle)} — ${_esc(section.heading)}</title>');
  b.writeln('<style>');
  b.writeln(_css);
  b.writeln('</style></head><body><div class="wrap">');
  b.writeln('<header>');
  b.writeln('<div class="bar"></div>');
  b.writeln('<h1>${_esc(reportTitle)}</h1>');
  b.writeln('<div class="sub">${_esc(section.heading)}</div>');
  b.writeln('</header>');
  _writeSectionHtml(b, section);
  b.writeln('<footer>${_esc(reportTitle)} · Stats-flutter</footer>');
  b.writeln('</div></body></html>');
  return b.toString();
}

/// 把一个分区写进 HTML 缓冲区（整份导出与分区导出共用）。
void _writeSectionHtml(StringBuffer b, ReportSection s) {
  b.writeln('<section>');
  b.writeln('<h2><span class="rule"></span>${_esc(s.heading)}</h2>');
  if (s.body != null) {
    b.writeln('<pre class="body">${_esc(s.body!)}</pre>');
  }
  for (final t in s.tables) {
    if (t.caption != null) {
      b.writeln('<div class="cap">${_esc(t.caption!)}</div>');
    }
    final style = ReportTableStyle.of(t);
    b.writeln('<div class="scroll"><table><thead><tr>');
    for (final h in t.headers) {
      b.writeln('<th>${_esc(h)}</th>');
    }
    b.writeln('</tr></thead><tbody>');
    for (final r in t.rows) {
      b.writeln('<tr>');
      for (var i = 0; i < t.headers.length; i++) {
        final cell = styleBodyCell(style, i < r.length ? r[i] : '', i);
        var html = _esc(cell.label);
        if (cell.stars.isNotEmpty) {
          html = '$html<span class="stars">${cell.stars}</span>';
        }
        final cls = [
          if (cell.numeric) 'num',
          if (cell.significant) 'sig',
        ].join(' ');
        b.writeln('<td${cls.isEmpty ? '' : ' class="$cls"'}>$html</td>');
      }
      b.writeln('</tr>');
    }
    b.writeln('</tbody></table></div>');
  }
  if (s.notes != null) {
    b.writeln('<div class="note">${_esc(s.notes!)}</div>');
  }
  b.writeln('</section>');
}

const String _css = '''
:root{
  --bg:#f5f6f9; --card:#ffffff; --fg:#151922; --muted:#5b6472;
  --border:#e4e7ee; --head:#f2f4f9; --accent:#2f6fed;
  --mono:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,monospace;
}
@media (prefers-color-scheme:dark){
  :root{--bg:#101317;--card:#171b21;--fg:#e7eaf0;--muted:#9aa3b2;
        --border:#272d36;--head:#1e242c;--accent:#7aa5ff}
}
*{box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"PingFang SC","Microsoft YaHei",system-ui,sans-serif;
     margin:0;padding:24px 16px 48px;background:var(--bg);color:var(--fg);line-height:1.6;
     -webkit-font-smoothing:antialiased}
.wrap{max-width:920px;margin:0 auto}
header{position:relative;padding-left:14px;margin-bottom:20px}
.bar{position:absolute;left:0;top:4px;bottom:4px;width:4px;border-radius:4px;
     background:linear-gradient(180deg,var(--accent),transparent)}
h1{margin:0 0 2px;font-size:23px;font-weight:800;letter-spacing:-.2px}
.sub{color:var(--muted);font-size:13px}
section{background:var(--card);border:1px solid var(--border);border-radius:14px;
        padding:16px 18px;margin-bottom:14px}
h2{display:flex;align-items:center;gap:8px;margin:0 0 10px;font-size:15px;font-weight:700;color:var(--fg)}
.rule{width:3px;height:14px;border-radius:2px;background:var(--accent);display:inline-block}
.body{white-space:pre-wrap;font-family:var(--mono);font-size:12px;background:var(--head);
      border:1px solid var(--border);padding:10px 12px;border-radius:8px;margin:6px 0 10px}
.scroll{overflow-x:auto;margin:8px 0 4px;border:1px solid var(--border);border-radius:10px}
table{border-collapse:collapse;width:100%;font-size:12.5px;font-variant-numeric:tabular-nums}
th,td{padding:7px 11px;text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
th{background:var(--head);font-weight:700;position:sticky;top:0}
tbody tr:last-child td{border-bottom:none}
tbody tr:nth-child(even) td{background:color-mix(in srgb,var(--head) 55%,transparent)}
td.num,th.num{text-align:right}
.sig{color:var(--accent);font-weight:600}
.stars{margin-left:4px;color:var(--accent);font-weight:800;letter-spacing:.5px}
.cap{color:var(--accent);font-size:12px;font-weight:700;margin:12px 0 2px}
.note{color:var(--muted);font-size:12px;margin-top:8px}
footer{color:var(--muted);font-size:11px;margin-top:22px;text-align:center}
@media print{
  :root{--bg:#fff;--card:#fff;--border:#d8dbe2;--head:#f4f4f6}
  body{padding:0}
  section{break-inside:avoid;box-shadow:none}
}
''';

String reportToMarkdown(AnalysisReport report) {
  final b = StringBuffer();
  b.writeln('# ${report.title}');
  b.writeln();
  b.writeln('**${report.subtitle}**');
  b.writeln();
  for (final s in report.sections) {
    _writeSectionMarkdown(b, s);
  }
  return b.toString();
}

/// 单个分区的 Markdown（含报告标题作为一级标题，单独分享时仍知道出处）。
String sectionToMarkdown(
  ReportSection section, {
  required String reportTitle,
}) {
  final b = StringBuffer();
  b.writeln('# $reportTitle');
  b.writeln();
  _writeSectionMarkdown(b, section);
  return b.toString();
}

/// 把一个分区写进 Markdown 缓冲区（整份导出与分区导出共用）。
void _writeSectionMarkdown(StringBuffer b, ReportSection s) {
  b.writeln('## ${s.heading}');
  b.writeln();
  if (s.body != null) {
    b.writeln('```');
    b.writeln(s.body);
    b.writeln('```');
  }
  for (final t in s.tables) {
    if (t.caption != null) {
      b.writeln('**${t.caption}**');
    }
    b.writeln();
    b.writeln('| ${t.headers.join(' | ')} |');
    b.writeln('| ${t.headers.map((_) => '---').join(' | ')} |');
    for (final r in t.rows) {
      final cells = [
        for (var i = 0; i < t.headers.length; i++) i < r.length ? r[i] : ''
      ];
      b.writeln('| ${cells.join(' | ')} |');
    }
    b.writeln();
  }
  if (s.notes != null) {
    b.writeln('> ${s.notes}');
    b.writeln();
  }
}

/// 文件名安全 slug：只保留 ASCII 字母数字与 `-`。
///
/// 中文等非 ASCII 标题会被清空（返回空串），交由调用方回退到分区序号，
/// 避免出现 `????.md` 或跨平台非法字符。
String fileSafeSlug(String s) {
  final cleaned = s
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return cleaned.length > 48 ? cleaned.substring(0, 48) : cleaned;
}

/// 分区导出文件名（不含扩展名）：`stats-报告名-分区标题-20261015`。
///
/// [index] 用于纯中文标题的回退（`section-2`）。
String sectionFileBase({
  required String reportTitle,
  required ReportSection section,
  required int index,
  DateTime? at,
}) {
  final d = at ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final reportPart = fileSafeSlug(reportTitle);
  final slug = section.slug ?? section.heading;
  final safeSlug = fileSafeSlug(slug);
  final sectionPart = safeSlug.isEmpty ? 'section-${index + 1}' : safeSlug;
  return [
    'stats',
    if (reportPart.isNotEmpty) reportPart,
    sectionPart,
    '${d.year}${two(d.month)}${two(d.day)}',
  ].join('-');
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

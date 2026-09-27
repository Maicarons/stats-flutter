/// 报告 HTML 导出（v1.1）
library;

import '../output/report_builder.dart';

String reportToHtml(AnalysisReport report, {String title = 'StatLab Report'}) {
  final b = StringBuffer();
  b.writeln('<!DOCTYPE html>');
  b.writeln('<html lang="zh-CN">');
  b.writeln('<head>');
  b.writeln('<meta charset="utf-8">');
  b.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
  b.writeln('<title>${_esc(title)} — ${_esc(report.title)}</title>');
  b.writeln('<style>');
  b.writeln('''
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"PingFang SC","Microsoft YaHei",sans-serif;
     margin:0;padding:24px;background:#f6f7fb;color:#1a1d26;line-height:1.55}
.wrap{max-width:900px;margin:0 auto}
header{margin-bottom:24px}
h1{margin:0 0 4px;font-size:22px}
.sub{color:#5b6472;font-size:13px}
section{background:#fff;border-radius:12px;padding:18px 20px;margin-bottom:14px;
        box-shadow:0 1px 3px rgba(16,24,40,.08)}
h2{margin:0 0 10px;font-size:15px;color:#2f6fed}
table{border-collapse:collapse;width:100%;font-size:13px;margin:8px 0}
th,td{border:1px solid #e5e8f0;padding:8px 10px;text-align:left}
th{background:#f0f3fa;font-weight:600}
tr:nth-child(even) td{background:#fafbfe}
.note{color:#5b6472;font-size:12px;margin-top:8px}
.cap{color:#2f6fed;font-size:12px;font-weight:600;margin:10px 0 4px}
footer{color:#8a93a3;font-size:11px;margin-top:20px;text-align:center}
''');
  b.writeln('</style></head><body><div class="wrap">');
  b.writeln('<header><h1>${_esc(report.title)}</h1>');
  b.writeln('<div class="sub">${_esc(report.subtitle)}</div></header>');

  for (final s in report.sections) {
    b.writeln('<section>');
    b.writeln('<h2>${_esc(s.heading)}</h2>');
    if (s.body != null) {
      b.writeln('<pre style="white-space:pre-wrap;font-family:ui-monospace,monospace;font-size:12px;background:#f8f9fc;padding:10px;border-radius:8px">${_esc(s.body!)}</pre>');
    }
    for (final t in s.tables) {
      if (t.caption != null) {
        b.writeln('<div class="cap">${_esc(t.caption!)}</div>');
      }
      b.writeln('<table><thead><tr>');
      for (final h in t.headers) {
        b.writeln('<th>${_esc(h)}</th>');
      }
      b.writeln('</tr></thead><tbody>');
      for (final r in t.rows) {
        b.writeln('<tr>');
        for (var i = 0; i < t.headers.length; i++) {
          b.writeln('<td>${_esc(i < r.length ? r[i] : '')}</td>');
        }
        b.writeln('</tr>');
      }
      b.writeln('</tbody></table>');
    }
    if (s.notes != null) {
      b.writeln('<div class="note">${_esc(s.notes!)}</div>');
    }
    b.writeln('</section>');
  }
  b.writeln('<footer>${_esc(report.title)} · ${report.createdAt.toLocal()} · Stats-flutter</footer>');
  b.writeln('</div></body></html>');
  return b.toString();
}

String reportToMarkdown(AnalysisReport report) {
  final b = StringBuffer();
  b.writeln('# ${report.title}');
  b.writeln();
  b.writeln('**${report.subtitle}**');
  b.writeln();
  for (final s in report.sections) {
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
          for (var i = 0; i < t.headers.length; i++)
            i < r.length ? r[i] : ''
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
  return b.toString();
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// 报告导出（v1.3）：HTML / Markdown。
/// HTML 版与 App 内报告保持同一视觉语言：细描边卡片、等宽数字、数值右对齐，并支持打印与深色模式。
library;

import '../output/report_builder.dart';

/// 判断某列是否为纯数值列（除首列外），用于右对齐。
bool _numericColumn(ReportTable t, int c) {
  if (c == 0) return false;
  final re = RegExp(r'^-?[0-9][0-9,.\s]*%?$');
  var seen = false;
  for (final r in t.rows) {
    if (c >= r.length) continue;
    final s = r[c].trim();
    if (s.isEmpty) continue;
    seen = true;
    if (!re.hasMatch(s)) return false;
  }
  return seen;
}

/// 判断某列是否为 p 值列（用于显著性标注）。
final RegExp _pHeaderRe = RegExp(
  r'^(p\b|p值|sig\.?\b|显著性)',
  caseSensitive: false,
);

double? _parseP(String s) {
  final t = s.trim();
  if (t.isEmpty || t == '—' || t == '-') return null;
  if (t.startsWith('<') || t.startsWith('≤')) {
    final v = _toDouble(t.substring(1).trim());
    return v == null ? null : v / 2;
  }
  return _toDouble(t);
}

double? _toDouble(String t) {
  final v = t.startsWith('.') ? '0$t' : t;
  return double.tryParse(v.replaceAll(',', ''));
}

String _stars(double p) =>
    p < 0.001 ? '***' : (p < 0.01 ? '**' : (p < 0.05 ? '*' : ''));

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
    b.writeln('<section>');
    b.writeln('<h2><span class="rule"></span>${_esc(s.heading)}</h2>');
    if (s.body != null) {
      b.writeln('<pre class="body">${_esc(s.body!)}</pre>');
    }
    for (final t in s.tables) {
      if (t.caption != null) {
        b.writeln('<div class="cap">${_esc(t.caption!)}</div>');
      }
      final numeric = [
        for (var c = 0; c < t.headers.length; c++) _numericColumn(t, c),
      ];
      final isP = [
        for (final h in t.headers) _pHeaderRe.hasMatch(h.trim()),
      ];
      b.writeln('<div class="scroll"><table><thead><tr>');
      for (final h in t.headers) {
        b.writeln('<th>${_esc(h)}</th>');
      }
      b.writeln('</tr></thead><tbody>');
      for (final r in t.rows) {
        b.writeln('<tr>');
        for (var i = 0; i < t.headers.length; i++) {
          var html = _esc(i < r.length ? r[i] : '');
          var cls = numeric[i] ? 'num' : '';
          if (isP[i]) {
            final p = _parseP(i < r.length ? r[i] : '');
            if (p != null) {
              final st = _stars(p);
              if (st.isNotEmpty) {
                html = '$html<span class="stars">$st</span>';
                cls = cls.isEmpty ? 'sig' : '$cls sig';
              }
            }
          }
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
  b.writeln(
      '<footer>${_esc(report.title)} · ${report.createdAt.toLocal()} · Stats-flutter</footer>');
  b.writeln('</div></body></html>');
  return b.toString();
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

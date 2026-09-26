/// 分析结果模型 + 纯文本报告渲染
library;

import 'package:statkit/statkit.dart';

class AnalysisReport {
  final String title;
  final String subtitle;
  final List<ReportSection> sections;
  final DateTime createdAt;

  AnalysisReport({
    required this.title,
    required this.subtitle,
    required this.sections,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String toPlainText() {
    final b = StringBuffer();
    b.writeln('=' * 48);
    b.writeln(title);
    b.writeln(subtitle);
    b.writeln(createdAt.toIso8601String());
    b.writeln('=' * 48);
    for (final s in sections) {
      b.writeln();
      b.writeln('## ${s.heading}');
      if (s.body != null) {
        b.writeln(s.body);
      }
      for (final t in s.tables) {
        b.writeln();
        b.writeln(t.toText());
      }
      if (s.notes != null) {
        b.writeln();
        b.writeln(s.notes);
      }
    }
    return b.toString();
  }
}

class ReportSection {
  final String heading;
  final String? body;
  final List<ReportTable> tables;
  final String? notes;
  const ReportSection({
    required this.heading,
    this.body,
    this.tables = const [],
    this.notes,
  });
}

class ReportTable {
  final List<String> headers;
  final List<List<String>> rows;
  final String? caption;
  const ReportTable({
    required this.headers,
    required this.rows,
    this.caption,
  });

  String toText() {
    final cols = headers.length;
    final data = [headers, ...rows];
    final widths = List.filled(cols, 0);
    for (final r in data) {
      for (var i = 0; i < cols && i < r.length; i++) {
        if (r[i].length > widths[i]) widths[i] = r[i].length;
      }
    }
    final b = StringBuffer();
    if (caption != null) b.writeln(caption);
    String line(List<String> r) {
      final parts = <String>[];
      for (var i = 0; i < cols; i++) {
        final cell = i < r.length ? r[i] : '';
        parts.add(cell.padLeft(widths[i]));
      }
      return parts.join('  ');
    }

    b.writeln(line(headers));
    b.writeln(widths.map((w) => '─' * w).join('  '));
    for (final r in rows) {
      b.writeln(line(r));
    }
    return b.toString();
  }
}

/// 把描述统计渲染为报告
AnalysisReport reportDescriptives(
  Map<String, Descriptives> byVar, {
  String datasetName = '',
}) {
  return AnalysisReport(
    title: '描述统计',
    subtitle: datasetName,
    sections: [
      ReportSection(
        heading: '描述统计量',
        tables: [
          ReportTable(
            caption: '各变量描述统计',
            headers: const [
              '变量', 'N', '均值', '标准差', '方差', '最小', '最大', '偏度', '峰度'
            ],
            rows: byVar.entries
                .map((e) => [
                      e.key,
                      '${e.value.n}',
                      formatNum(e.value.mean),
                      formatNum(e.value.sd),
                      formatNum(e.value.variance),
                      formatNum(e.value.min),
                      formatNum(e.value.max),
                      formatNum(e.value.skewness),
                      formatNum(e.value.kurtosis),
                    ])
                .toList(),
          ),
          ReportTable(
            caption: '分位数与置信区间',
            headers: const ['变量', 'Q1', '中位数', 'Q3', 'IQR', '95% CI 下限', '95% CI 上限', '标准误'],
            rows: byVar.entries
                .map((e) => [
                      e.key,
                      formatNum(e.value.q1),
                      formatNum(e.value.median),
                      formatNum(e.value.q3),
                      formatNum(e.value.iqr),
                      formatNum(e.value.ciLower95),
                      formatNum(e.value.ciUpper95),
                      formatNum(e.value.se),
                    ])
                .toList(),
          ),
        ],
        notes: '置信区间基于 t 分布，置信水平 95%。',
      ),
    ],
  );
}

AnalysisReport reportTTest(TTestResult r, {required String label}) {
  return AnalysisReport(
    title: 't 检验 · $label',
    subtitle: r.mode,
    sections: [
      ReportSection(
        heading: '组统计量',
        tables: [
          ReportTable(
            headers: const ['组', 'N', '均值', '标准差', '标准误'],
            rows: [
              ['组1', '${r.n1}', formatNum(r.mean1), formatNum(r.sd1), formatNum(r.sd1 / (r.n1 > 0 ? _sqrt(r.n1.toDouble()) : 1))],
              ['组2', '${r.n2}', formatNum(r.mean2), formatNum(r.sd2), formatNum(r.sd2 / (r.n2 > 0 ? _sqrt(r.n2.toDouble()) : 1))],
            ],
          ),
        ],
      ),
      ReportSection(
        heading: '独立样本检验' ,
        tables: [
          ReportTable(
            headers: const [
              't', 'df', 'p(双尾)', '均值差', '差值标准误', '95%CI下', '95%CI上', 'Cohen d'
            ],
            rows: [
              [
                formatNum(r.t),
                formatNum(r.df, digits: 1),
                formatP(r.pTwoTail),
                formatNum(r.meanDiff),
                formatNum(r.seDiff),
                formatNum(r.ciLower95),
                formatNum(r.ciUpper95),
                formatNum(r.cohensD),
              ],
            ],
          ),
        ],
        notes: r.leveneP == null
            ? null
            : 'Levene 方差齐性：F=${formatNum(r.leveneF!)}, p=${formatP(r.leveneP!)}；'
                '${r.equalVarAssumed ? '假定方差齐性' : '不假定方差齐性（Welch）'}。',
      ),
    ],
  );
}

AnalysisReport reportAnova(AnovaResult r, {String title = '单因素方差分析'}) {
  return AnalysisReport(
    title: title,
    subtitle: 'ONEWAY ANOVA',
    sections: [
      ReportSection(
        heading: '描述统计',
        tables: [
          ReportTable(
            headers: const ['组', 'N', '均值', '标准差', '方差'],
            rows: r.groups
                .map((g) => [
                      g.label,
                      '${g.n}',
                      formatNum(g.mean),
                      formatNum(g.sd),
                      formatNum(g.variance),
                    ])
                .toList(),
          ),
        ],
      ),
      ReportSection(
        heading: '方差分析表',
        tables: [
          ReportTable(
            headers: const ['来源', '平方和', 'df', '均方', 'F', 'p', 'η²'],
            rows: [
              [
                '组间',
                formatNum(r.ssBetween),
                '${r.dfBetween}',
                formatNum(r.msBetween),
                formatNum(r.f),
                formatP(r.p),
                formatNum(r.etaSquared),
              ],
              [
                '组内',
                formatNum(r.ssWithin),
                '${r.dfWithin}',
                formatNum(r.msWithin),
                '',
                '',
                '',
              ],
              [
                '总计',
                formatNum(r.ssTotal),
                '${r.dfBetween + r.dfWithin}',
                '',
                '',
                '',
                '',
              ],
            ],
          ),
        ],
        notes:
            'ω²=${formatNum(r.omegaSquared)}；Levene F=${formatNum(r.levene.f)}, p=${formatP(r.levene.p)}。',
      ),
    ],
  );
}

AnalysisReport reportCorrelation(
  Map<String, Map<String, CorrelationResult>> matrix, {
  String method = 'Pearson',
}) {
  final names = matrix.keys.toList();
  final rows = <List<String>>[];
  for (final a in names) {
    final row = <String>[a];
    for (final b in names) {
      final r = matrix[a]![b]!;
      if (a == b) {
        row.add('1');
      } else {
        row.add('${formatNum(r.r)} ${significanceStars(r.p)}');
      }
    }
    rows.add(row);
  }
  final pRows = <List<String>>[];
  for (final a in names) {
    final row = <String>[a];
    for (final b in names) {
      row.add(a == b ? '—' : formatP(matrix[a]![b]!.p));
    }
    pRows.add(row);
  }
  return AnalysisReport(
    title: '相关分析',
    subtitle: method,
    sections: [
      ReportSection(
        heading: '相关系数',
        tables: [
          ReportTable(headers: ['', ...names], rows: rows),
          ReportTable(
            caption: '显著性 (双尾 p)',
            headers: ['', ...names],
            rows: pRows,
          ),
        ],
        notes: '*** p<.001  ** p<.01  * p<.05',
      ),
    ],
  );
}

AnalysisReport reportRegression(RegressionResult r, {String yName = 'Y'}) {
  return AnalysisReport(
    title: '线性回归',
    subtitle: '因变量：$yName',
    sections: [
      ReportSection(
        heading: '模型摘要',
        tables: [
          ReportTable(
            headers: const ['R', 'R²', '调整 R²', '标准误', 'F', 'p', 'DW'],
            rows: [
              [
                formatNum(r.r),
                formatNum(r.r2),
                formatNum(r.adjR2),
                formatNum(r.stdError),
                formatNum(r.f),
                formatP(r.pF),
                formatNum(r.durbinWatson),
              ],
            ],
          ),
        ],
      ),
      ReportSection(
        heading: '方差分析',
        tables: [
          ReportTable(
            headers: const ['来源', '平方和', 'df', '均方', 'F', 'p'],
            rows: [
              ['回归', formatNum(r.ssRegression), '${r.dfModel}', formatNum(r.msRegression), formatNum(r.f), formatP(r.pF)],
              ['残差', formatNum(r.ssResidual), '${r.dfResidual}', formatNum(r.msResidual), '', ''],
              ['总计', formatNum(r.ssTotal), '${r.dfModel + r.dfResidual}', '', '', ''],
            ],
          ),
        ],
      ),
      ReportSection(
        heading: '系数',
        tables: [
          ReportTable(
            headers: const ['项', 'B', '标准β', 'SE', 't', 'p', '95%CI下', '95%CI上', 'VIF'],
            rows: r.coefficients
                .map((c) => [
                      c.name,
                      formatNum(c.beta),
                      formatNum(c.stdBeta),
                      formatNum(c.se),
                      formatNum(c.t),
                      formatP(c.p),
                      formatNum(c.ciLower95),
                      formatNum(c.ciUpper95),
                      c.vif == null ? '—' : formatNum(c.vif!),
                    ])
                .toList(),
          ),
        ],
      ),
    ],
  );
}

AnalysisReport reportChiSquare(ChiSquareResult r, {String title = '卡方检验'}) {
  return AnalysisReport(
    title: title,
    subtitle: 'Pearson χ²',
    sections: [
      ReportSection(
        heading: '卡方检验',
        tables: [
          ReportTable(
            headers: const ['统计量', '值', 'df', 'p'],
            rows: [
              ['Pearson χ²', formatNum(r.chiSquare), '${r.df}', formatP(r.p)],
              ['似然比 G²', formatNum(r.likelihoodRatio), '${r.df}', formatP(r.pLikelihood)],
              ['N', formatNum(r.n), '', ''],
            ],
          ),
          if (r.cramersV != null)
            ReportTable(
              headers: const ['关联度', '值'],
              rows: [
                ['φ', formatNum(r.phi!)],
                ["Cramér's V", formatNum(r.cramersV!)],
              ],
            ),
        ],
      ),
      ReportSection(
        heading: '单元格（观察 / 期望）',
        tables: [
          ReportTable(
            headers: const ['#', '观察', '期望', '残差', '标准化残差'],
            rows: List.generate(
              r.cells.length,
              (i) => [
                '${i + 1}',
                formatNum(r.cells[i].observed),
                formatNum(r.cells[i].expected),
                formatNum(r.cells[i].residual),
                formatNum(r.cells[i].stdResidual),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

double _sqrt(double x) => _mathSqrt(x);

// 避免与 statkit 重名
double _mathSqrt(double x) {
  // 牛顿迭代
  if (x <= 0) return 0;
  double g = x;
  for (var i = 0; i < 30; i++) {
    g = 0.5 * (g + x / g);
  }
  return g;
}

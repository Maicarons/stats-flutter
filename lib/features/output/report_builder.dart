/// 分析结果模型 + 纯文本报告渲染（i18n）
library;

import 'package:statkit/statkit.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

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
  AppLocalizations l10n,
  Map<String, Descriptives> byVar, {
  String datasetName = '',
}) {
  return AnalysisReport(
    title: l10n.descriptivesTitle,
    subtitle: datasetName,
    sections: [
      ReportSection(
        heading: l10n.descriptivesStats,
        tables: [
          ReportTable(
            caption: l10n.descByVar,
            headers: [
              l10n.reportVar, 'N', l10n.mean, l10n.stdDev, l10n.variance,
              l10n.minWord, l10n.maxWord, l10n.skewness, l10n.kurtosis,
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
            caption: l10n.quantilesCi,
            headers: [
              l10n.reportVar, 'Q1', l10n.median, 'Q3', 'IQR',
              l10n.ciLower, l10n.ciUpper, l10n.se,
            ],
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
        notes: l10n.ciNote,
      ),
    ],
  );
}

AnalysisReport reportTTest(AppLocalizations l10n, TTestResult r,
    {required String label}) {
  return AnalysisReport(
    title: '${l10n.ttestTitle} · $label',
    subtitle: r.mode,
    sections: [
      ReportSection(
        heading: l10n.groupStats,
        tables: [
          ReportTable(
            headers: [l10n.group, 'N', l10n.mean, l10n.stdDev, l10n.se],
            rows: [
              [
                l10n.group1,
                '${r.n1}',
                formatNum(r.mean1),
                formatNum(r.sd1),
                formatNum(r.sd1 / (r.n1 > 0 ? _sqrt(r.n1.toDouble()) : 1)),
              ],
              [
                l10n.group2,
                '${r.n2}',
                formatNum(r.mean2),
                formatNum(r.sd2),
                formatNum(r.sd2 / (r.n2 > 0 ? _sqrt(r.n2.toDouble()) : 1)),
              ],
            ],
          ),
        ],
      ),
      ReportSection(
        heading: l10n.independentTest,
        tables: [
          ReportTable(
            headers: [
              't', 'df', l10n.pTwoTail, l10n.meanDiff, l10n.seDiff,
              l10n.ciLower, l10n.ciUpper, 'Cohen d',
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
            : l10n.leveneNote(
                formatNum(r.leveneF!),
                formatP(r.leveneP!),
                r.equalVarAssumed
                    ? l10n.equalVarAssumed
                    : l10n.equalVarNotAssumed,
              ),
      ),
    ],
  );
}

AnalysisReport reportAnova(AppLocalizations l10n, AnovaResult r,
    {String? title}) {
  return AnalysisReport(
    title: title ?? l10n.anovaTitle,
    subtitle: 'ONEWAY ANOVA',
    sections: [
      ReportSection(
        heading: l10n.descriptivesStats,
        tables: [
          ReportTable(
            headers: [
              l10n.group, 'N', l10n.mean, l10n.stdDev, l10n.variance,
            ],
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
        heading: l10n.anovaTable,
        tables: [
          ReportTable(
            headers: [
              l10n.source, l10n.ss, 'df', l10n.ms, 'F', 'p', 'η²',
            ],
            rows: [
              [
                l10n.betweenGroups,
                formatNum(r.ssBetween),
                '${r.dfBetween}',
                formatNum(r.msBetween),
                formatNum(r.f),
                formatP(r.p),
                formatNum(r.etaSquared),
              ],
              [
                l10n.withinGroups,
                formatNum(r.ssWithin),
                '${r.dfWithin}',
                formatNum(r.msWithin),
                '',
                '',
                '',
              ],
              [
                l10n.total,
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
        notes: l10n.anovaNote(
            formatNum(r.omegaSquared), formatNum(r.levene.f), formatP(r.levene.p)),
      ),
    ],
  );
}

AnalysisReport reportCorrelation(
  AppLocalizations l10n,
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
    title: l10n.corrTitle,
    subtitle: method,
    sections: [
      ReportSection(
        heading: l10n.corrCoef,
        tables: [
          ReportTable(headers: ['', ...names], rows: rows),
          ReportTable(
            caption: l10n.sigTwoTail,
            headers: ['', ...names],
            rows: pRows,
          ),
        ],
        notes: l10n.corrStars,
      ),
    ],
  );
}

AnalysisReport reportRegression(AppLocalizations l10n, RegressionResult r,
    {String yName = 'Y'}) {
  return AnalysisReport(
    title: l10n.regressionTitle,
    subtitle: l10n.depVarColon(yName),
    sections: [
      ReportSection(
        heading: l10n.modelSummary,
        tables: [
          ReportTable(
            headers: ['R', 'R²', l10n.adjR2, l10n.se, 'F', 'p', 'DW'],
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
        heading: l10n.anovaTable,
        tables: [
          ReportTable(
            headers: [l10n.source, l10n.ss, 'df', l10n.ms, 'F', 'p'],
            rows: [
              [
                l10n.regressionWord,
                formatNum(r.ssRegression),
                '${r.dfModel}',
                formatNum(r.msRegression),
                formatNum(r.f),
                formatP(r.pF),
              ],
              [
                l10n.residual,
                formatNum(r.ssResidual),
                '${r.dfResidual}',
                formatNum(r.msResidual),
                '',
                '',
              ],
              [
                l10n.total,
                formatNum(r.ssTotal),
                '${r.dfModel + r.dfResidual}',
                '',
                '',
                '',
              ],
            ],
          ),
        ],
      ),
      ReportSection(
        heading: l10n.coefficients,
        tables: [
          ReportTable(
            headers: [
              l10n.term, 'B', l10n.stdBeta, 'SE', 't', 'p',
              l10n.ciLower, l10n.ciUpper, 'VIF',
            ],
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

AnalysisReport reportChiSquare(AppLocalizations l10n, ChiSquareResult r,
    {String? title}) {
  return AnalysisReport(
    title: title ?? l10n.chiSquareTitle,
    subtitle: 'Pearson χ²',
    sections: [
      ReportSection(
        heading: l10n.chiSquareTitle,
        tables: [
          ReportTable(
            headers: [l10n.statistic, l10n.valueWord, 'df', 'p'],
            rows: [
              ['Pearson χ²', formatNum(r.chiSquare), '${r.df}', formatP(r.p)],
              [
                l10n.likelihoodRatio,
                formatNum(r.likelihoodRatio),
                '${r.df}',
                formatP(r.pLikelihood),
              ],
              ['N', formatNum(r.n), '', ''],
            ],
          ),
          if (r.cramersV != null)
            ReportTable(
              headers: [l10n.association, l10n.valueWord],
              rows: [
                ['φ', formatNum(r.phi!)],
                ["Cramér's V", formatNum(r.cramersV!)],
              ],
            ),
        ],
      ),
      ReportSection(
        heading: l10n.cellsObsExp,
        tables: [
          ReportTable(
            headers: ['#', l10n.observed, l10n.expected, l10n.residual, l10n.stdResidual],
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

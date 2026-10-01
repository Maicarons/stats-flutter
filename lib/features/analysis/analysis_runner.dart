import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';
import '../../core/io/missing_aware.dart';
import '../output/report_builder.dart';
import '../output/report_export.dart';

class AnalysisRunner extends StatefulWidget {
  final String analysisId;
  final String title;
  const AnalysisRunner({super.key, required this.analysisId, required this.title});

  @override
  State<AnalysisRunner> createState() => _AnalysisRunnerState();
}

class _AnalysisRunnerState extends State<AnalysisRunner> {
  final List<String> _selectedVars = [];
  String? _groupVar;
  String? _yVar;
  String? _xVar;
  String _corMethod = 'Pearson';
  int _kClusters = 3;
  final _muCtrl = TextEditingController(text: '0');
  AnalysisReport? _report;
  Widget? _chart;
  bool _busy = false;

  Dataset get ds => datasetStore.data;
  AppLocalizations get l10n => AppLocalizations.of(context);

  List<String> get _numericVars => ds.variables
      .where((v) => v.isNumeric)
      .map((v) => v.name)
      .toList();

  @override
  void dispose() {
    _muCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_report != null)
            IconButton(
              tooltip: l10n.shareReport,
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(_report!.toPlainText(),
                  subject: _report!.title),
            ),
          if (_report != null)
            IconButton(
              tooltip: l10n.exportHtml,
              icon: const Icon(Icons.html),
              onPressed: () => _exportHtml(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildParams(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_busy ? l10n.running : l10n.runAnalysis),
          ),
          if (_report != null) ...[
            const SizedBox(height: 20),
            _ReportView(report: _report!),
          ],
          if (_chart != null) ...[
            const SizedBox(height: 16),
            _chart!,
          ],
        ],
      ),
    );
  }

  Widget _buildParams() {
    final l10n = AppLocalizations.of(context);
    final id = widget.analysisId;
    final multiVars = {
      'descriptives',
      'frequencies',
      'explore',
      'histogram',
      'bar',
      'reliability',
      'correlation',
    };
    final needGroup = {
      'ttest_ind',
      'anova',
      'mannwhitney',
      'kruskal',
    };
    final needPair = {'ttest_paired', 'wilcoxon'};
    final needXY = {'regression', 'scatter', 'kmeans'};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.params,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (multiVars.contains(id))
              _VarPicker(
                label: l10n.selectVariables,
                names: _numericVars,
                selected: _selectedVars,
                onChanged: (v) => setState(() {}),
              ),
            if (needGroup.contains(id)) ...[
              _VarPicker(
                label: l10n.analysisVariable,
                names: _numericVars,
                selected: _selectedVars.take(1).toList(),
                single: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: l10n.groupVariable,
                value: _groupVar,
                items: ds.variables.map((v) => v.name).toList(),
                onChanged: (v) => setState(() => _groupVar = v),
              ),
            ],
            if (needPair.contains(id))
              _VarPicker(
                label: l10n.pairVariables,
                names: _numericVars,
                selected: _selectedVars,
                max: 2,
                onChanged: (_) => setState(() {}),
              ),
            if (id == 'ttest_one') ...[
              _VarPicker(
                label: l10n.analysisVariable,
                names: _numericVars,
                selected: _selectedVars.take(1).toList(),
                single: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _muCtrl,
                decoration: InputDecoration(labelText: l10n.testValue),
                keyboardType: TextInputType.number,
              ),
            ],
            if (needXY.contains(id)) ...[
              _Dropdown(
                label: id == 'regression' ? l10n.dependentVar : l10n.varY,
                value: _yVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: id == 'regression' ? l10n.independentVar : l10n.varX,
                value: _xVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _xVar = v),
              ),
              if (id == 'kmeans') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l10n.clusterCount),
                    Expanded(
                      child: Slider(
                        value: _kClusters.toDouble(),
                        min: 2,
                        max: 6,
                        divisions: 4,
                        label: '$_kClusters',
                        onChanged: (v) =>
                            setState(() => _kClusters = v.round()),
                      ),
                    ),
                    Text('$_kClusters'),
                  ],
                ),
              ],
            ],
            if (id == 'crosstabs') ...[
              _Dropdown(
                label: l10n.rowVariable,
                value: _yVar,
                items: ds.variables.map((v) => v.name).toList(),
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: l10n.columnVariable,
                value: _xVar,
                items: ds.variables.map((v) => v.name).toList(),
                onChanged: (v) => setState(() => _xVar = v),
              ),
            ],
            if (id == 'correlation') ...[
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Pearson', label: Text('Pearson')),
                  ButtonSegment(value: 'Spearman', label: Text('Spearman')),
                ],
                selected: {_corMethod},
                onSelectionChanged: (s) =>
                    setState(() => _corMethod = s.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportHtml() async {
    final r = _report;
    if (r == null) return;
    final html = reportToHtml(r);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/${r.title.replaceAll(RegExp(r"\s+"), "_")}.html');
      await f.writeAsString(html);
      await Share.shareXFiles([XFile(f.path)], subject: r.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _report = null;
      _chart = null;
    });
    try {
      switch (widget.analysisId) {
        case 'descriptives':
          _runDescriptives();
          break;
        case 'frequencies':
          _runBar();
          break;
        case 'explore':
          _runDescriptives();
          break;
        case 'ttest_one':
          _runTTestOne();
          break;
        case 'ttest_ind':
          _runTTestInd();
          break;
        case 'ttest_paired':
          _runTTestPaired();
          break;
        case 'anova':
          _runAnova();
          break;
        case 'correlation':
          _runCorrelation();
          break;
        case 'regression':
          _runRegression();
          break;
        case 'crosstabs':
          _runCrosstabs();
          break;
        case 'kmeans':
          _runKmeans();
          break;
        case 'mannwhitney':
          _runMannWhitney();
          break;
        case 'wilcoxon':
          _runWilcoxon();
          break;
        case 'kruskal':
          _runKruskal();
          break;
        case 'reliability':
          _runReliability();
          break;
        case 'histogram':
          _runHistogram();
          break;
        case 'scatter':
          _runScatter();
          break;
        case 'bar':
          _runBar();
          break;
        case 'means':
          _runMeans();
          break;
        case 'normality':
          _runNormality();
          break;
        case 'examine_full':
          _runExamine();
          break;
        case 'boxplot':
          _runBoxplot();
          break;
        case 'qqplot':
          _runQQ();
          break;
        case 'factor_full':
          _runFactorFull();
          break;
        case 'roc':
          _runRoc();
          break;
        case 'tukey':
          _runTukey();
          break;
        case 'factor_pca':
          _runFactor();
          break;
        case 'logistic':
          _runLogistic();
          break;
        case 'logistic_full':
          _runLogisticFull();
          break;
        case 'glm_two':
          _runGlmTwo();
          break;
        case 'stepwise':
          _runStepwise();
          break;
        case 'ctables':
          _runCtables();
          break;
        default:
          _report = AnalysisReport(
            title: widget.title,
            subtitle: l10n.notImplementedTitle,
            sections: [
              ReportSection(
                  heading: l10n.hintTitle, body: l10n.notImplemented),
            ],
          );
      }
    } catch (e) {
      _report = AnalysisReport(
        title: widget.title,
        subtitle: l10n.error,
        sections: [
          ReportSection(heading: l10n.failed, body: e.toString()),
        ],
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  void _runDescriptives() {
    final map = <String, Descriptives>{};
    for (final name in _selectedVars) {
      map[name] = Descriptives.compute(MissingAware.numeric(ds, name));
    }
    if (map.isEmpty) throw l10n.pleaseSelectVars;
    _report = reportDescriptives(l10n, map, datasetName: ds.name);
    final wName = ds.weightVariable;
    if (wName != null && wName.isNotEmpty) {
      final w = ds.numericColumn(wName);
      final notes = StringBuffer('WEIGHT CASES: ');
      notes.writeln(wName);
      for (final name in _selectedVars) {
        final v = ds.numericColumn(name);
        final ww = WeightedDescriptives.compute(v, w);
        notes.writeln(
            '$name  weighted mean=${ww.mean.toStringAsFixed(4)}  N_w=${ww.nWeighted}');
      }
      final prev = _report!;
      _report = AnalysisReport(
        title: prev.title,
        subtitle: prev.subtitle,
        sections: [
          ...prev.sections,
          ReportSection(heading: 'WEIGHT CASES', body: notes.toString()),
        ],
      );
    }
  }

  void _runTTestOne() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectTestVar;
    final mu = double.tryParse(_muCtrl.text) ?? 0;
    final r = TTest.oneSample(ds.numericColumn(name), mu0: mu);
    _report = reportTTest(
        l10n, r,
        label: l10n.oneSampleLabel(name, mu.toString()));
  }

  void _runTTestInd() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final groups = _splitByGroup(vName, _groupVar!);
    if (groups.length < 2) throw l10n.needTwoGroups;
    final keys = groups.keys.take(2).toList();
    final r = TTest.independentSamples(groups[keys[0]]!, groups[keys[1]]!);
    _report = reportTTest(
        l10n, r,
        label: '$vName by $_groupVar (${keys[0]} vs ${keys[1]})');
  }

  void _runTTestPaired() {
    if (_selectedVars.length < 2) throw l10n.pleaseSelectPaired;
    final a = ds.numericColumn(_selectedVars[0]);
    final b = ds.numericColumn(_selectedVars[1]);
    final n = a.length < b.length ? a.length : b.length;
    final r = TTest.paired(a.sublist(0, n), b.sublist(0, n));
    _report = reportTTest(
        l10n, r,
        label: l10n.pairedLabel(_selectedVars[0], _selectedVars[1]));
  }

  void _runAnova() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final groups = _splitByGroup(vName, _groupVar!);
    final labels = groups.keys.toList();
    final r = OnewayAnova.compute(
      labels.map((k) => groups[k]!).toList(),
      labels: labels,
    );
    _report = reportAnova(l10n, r,
        title: l10n.anovaOfLabel(vName, _groupVar!));
  }

  void _runCorrelation() {
    if (_selectedVars.length < 2) throw l10n.needTwoVars;
    final cols = {
      for (final n in _selectedVars) n: ds.numericColumn(n),
    };
    final matrix = <String, Map<String, CorrelationResult>>{};
    for (final a in _selectedVars) {
      matrix[a] = {};
      for (final b in _selectedVars) {
        final fn = _corMethod == 'Spearman'
            ? Correlation.spearman
            : Correlation.pearson;
        matrix[a]![b] = fn(cols[a]!, cols[b]!);
      }
    }
    _report = reportCorrelation(l10n, matrix, method: _corMethod);
  }

  void _runRegression() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectXY;
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final r = Regression.simple(
        x.sublist(0, n), y.sublist(0, n),
        xName: _xVar!, yName: _yVar!);
    _report = reportRegression(l10n, r, yName: _yVar!);
  }

  void _runCrosstabs() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectRowCol;
    final rowVals = ds.rawColumn(_yVar!);
    final colVals = ds.rawColumn(_xVar!);
    final rowCats = <Object>{};
    final colCats = <Object>{};
    for (var i = 0; i < rowVals.length && i < colVals.length; i++) {
      final a = rowVals[i];
      final b = colVals[i];
      if (a == null || b == null) continue;
      rowCats.add(a);
      colCats.add(b);
    }
    final rowList = rowCats.toList();
    final colList = colCats.toList();
    final table = List.generate(
        rowList.length, (_) => List.filled(colList.length, 0.0));
    for (var i = 0; i < rowVals.length && i < colVals.length; i++) {
      final a = rowVals[i];
      final b = colVals[i];
      if (a == null || b == null) continue;
      table[rowList.indexOf(a)][colList.indexOf(b)] += 1;
    }
    final r = ChiSquareTest.independence(table);
    _report = reportChiSquare(l10n, r,
        title: '${l10n.chiSquareTitle}: ${_yVar!} × ${_xVar!}');
  }

  void _runKmeans() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectTwoVars;
    final x = ds.numericColumn(_xVar!);
    final y = ds.numericColumn(_yVar!);
    final n = x.length < y.length ? x.length : y.length;
    final pts = List.generate(n, (i) => [x[i], y[i]]);
    final r = KMeans.cluster(pts,
        k: _kClusters, seed: 42, variableNames: [_xVar!, _yVar!]);
    final rows = <List<String>>[];
    for (var c = 0; c < r.k; c++) {
      final center = r.centers[c];
      rows.add([
        '${c + 1}',
        formatNum(center.centroid[0]),
        formatNum(center.centroid[1]),
        '${center.size}',
      ]);
    }
    _report = AnalysisReport(
      title: l10n.kmeansTitle,
      subtitle: l10n.kmeansSubtitle(
          _kClusters, r.iterations, formatNum(r.inertia)),
      sections: [
        ReportSection(
          heading: l10n.finalClusterCenters,
          tables: [
            ReportTable(
              headers: [l10n.cluster, 'X', 'Y', l10n.caseCount],
              rows: rows,
            ),
          ],
          notes: 'X=$_xVar  Y=$_yVar',
        ),
      ],
    );
    _chart = _ScatterClusters(pts: pts, assignments: r.assignments, centers: r.centers);
  }

  void _runMannWhitney() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final groups = _splitByGroup(vName, _groupVar!);
    final keys = groups.keys.take(2).toList();
    if (keys.length < 2) throw l10n.atLeastTwoGroups;
    final r = Nonparametric.mannWhitney(groups[keys[0]]!, groups[keys[1]]!);
    _report = _nonparamReport(r);
  }

  void _runWilcoxon() {
    if (_selectedVars.length < 2) throw l10n.pleaseSelectTwoVars;
    final a = ds.numericColumn(_selectedVars[0]);
    final b = ds.numericColumn(_selectedVars[1]);
    final n = a.length < b.length ? a.length : b.length;
    final r = Nonparametric.wilcoxon(a.sublist(0, n), b.sublist(0, n));
    _report = _nonparamReport(r);
  }

  void _runKruskal() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final groups = _splitByGroup(vName, _groupVar!);
    final r = Nonparametric.kruskalWallis(groups.values.toList());
    _report = _nonparamReport(r);
  }

  void _runReliability() {
    if (_selectedVars.length < 2) throw l10n.pleaseSelectItems;
    final cols = _selectedVars.map((n) => ds.numericColumn(n)).toList();
    final n = cols.map((c) => c.length).reduce((a, b) => a < b ? a : b);
    final items = cols.map((c) => c.sublist(0, n)).toList();
    final r = Reliability.cronbachAlpha(items, names: _selectedVars);
    _report = AnalysisReport(
      title: l10n.reliabilityTitle,
      subtitle: 'Cronbach α',
      sections: [
        ReportSection(
          heading: l10n.reliabilityStats,
          tables: [
            ReportTable(
              headers: ['Cronbach α', l10n.stdAlpha, l10n.nItemsWord, 'N'],
              rows: [
                [formatNum(r.alpha), formatNum(r.standardizedAlpha), '${r.nItems}', '${r.nCases}'],
              ],
            ),
            ReportTable(
              caption: l10n.itemStats,
              headers: [
                l10n.itemWord, l10n.mean, l10n.variance,
                l10n.itemTotalCorr, l10n.alphaIfDeleted,
              ],
              rows: r.items
                  .map((e) => [
                        e.name,
                        formatNum(e.mean),
                        formatNum(e.variance),
                        formatNum(e.itemTotalCorrelation),
                        formatNum(e.alphaIfDeleted),
                      ])
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  void _runHistogram() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    final values = ds.numericColumn(name);
    final bins = Frequencies.histogramBins(values);
    _report = AnalysisReport(
      title: l10n.histogramTitle,
      subtitle: name,
      sections: [
        ReportSection(
          heading: l10n.binFreq,
          tables: [
            ReportTable(
              headers: [l10n.lower, l10n.upper, l10n.freq],
              rows: bins
                  .map((b) =>
                      [formatNum(b.start), formatNum(b.end), '${b.count}'])
                  .toList(),
            ),
          ],
        ),
      ],
    );
    _chart = SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            bins.length,
            (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: bins[i].count.toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= bins.length) return const SizedBox();
                  return Text(formatNum(bins[i].midpoint, digits: 1),
                      style: const TextStyle(fontSize: 9));
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: true)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
        ),
      ),
    );
  }

  void _runScatter() {
    if (_xVar == null || _yVar == null) throw l10n.pleaseSelectXYShort;
    final x = ds.numericColumn(_xVar!);
    final y = ds.numericColumn(_yVar!);
    final n = x.length < y.length ? x.length : y.length;
    final r = Correlation.pearson(
        x.sublist(0, n), y.sublist(0, n));
    final fit = Regression.simple(x.sublist(0, n), y.sublist(0, n),
        xName: _xVar!, yName: _yVar!);
    _report = AnalysisReport(
      title: l10n.scatterTitle,
      subtitle: '$_yVar ~ $_xVar',
      sections: [
        ReportSection(
          heading: l10n.corrFit,
          tables: [
            ReportTable(
              headers: ['r', 'p', 'R²', l10n.slope, l10n.intercept],
              rows: [
                [
                  formatNum(r.r),
                  formatP(r.p),
                  formatNum(fit.r2),
                  formatNum(fit.coefficients[1].beta),
                  formatNum(fit.intercept),
                ],
              ],
            ),
          ],
        ),
      ],
    );
    _chart = SizedBox(
      height: 280,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [
            for (var i = 0; i < n; i++)
              ScatterSpot(x[i], y[i]),
          ],
          minX: (x.sublist(0, n).reduce((a, b) => a < b ? a : b)),
          maxX: (x.sublist(0, n).reduce((a, b) => a > b ? a : b)),
          minY: (y.sublist(0, n).reduce((a, b) => a < b ? a : b)),
          maxY: (y.sublist(0, n).reduce((a, b) => a > b ? a : b)),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );
  }

  void _runBar() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    final raw = ds.rawColumn(name);
    final freq = Frequencies.compute(raw, variableName: name);
    _report = AnalysisReport(
      title: l10n.barTitle,
      subtitle: name,
      sections: [
        ReportSection(
          heading: l10n.freqTable,
          tables: [
            ReportTable(
              headers: [
                l10n.category, l10n.freq, l10n.percent,
                l10n.validPercent, l10n.cumulativePercent,
              ],
              rows: freq.rows
                  .map((e) => [
                        e.label,
                        '${e.frequency}',
                        formatNum(e.percent, digits: 1),
                        formatNum(e.validPercent, digits: 1),
                        formatNum(e.cumulativePercent, digits: 1),
                      ])
                  .toList(),
            ),
          ],
          notes: l10n.freqNote(freq.nValid, freq.nMissing),
        ),
      ],
    );
    _chart = SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            freq.rows.length,
            (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: freq.rows[i].frequency.toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= freq.rows.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(freq.rows[i].label,
                        style: const TextStyle(fontSize: 9)),
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: true)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  void _runMeans() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final groups = _splitByGroup(vName, _groupVar!);
    final r = meansTable(groups, layerVar: _groupVar!, valueVar: vName);
    _report = AnalysisReport(
      title: l10n.meansTitle,
      subtitle: '$vName by ${_groupVar!}',
      sections: [
        ReportSection(
          heading: 'Means',
          tables: [
            ReportTable(
              headers: [
                l10n.group, 'N', l10n.mean, l10n.stdDev, l10n.se,
                l10n.median, l10n.minWord, l10n.maxWord,
              ],
              rows: [
                for (final g in r.rows)
                  [
                    g.group,
                    '${g.n}',
                    formatNum(g.mean),
                    formatNum(g.sd),
                    formatNum(g.se),
                    formatNum(g.median),
                    formatNum(g.min),
                    formatNum(g.max),
                  ],
                [
                  l10n.total,
                  '${r.total.n}',
                  formatNum(r.total.mean),
                  formatNum(r.total.sd),
                  formatNum(r.total.se),
                  formatNum(r.total.median),
                  formatNum(r.total.min),
                  formatNum(r.total.max),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _runNormality() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    final v = ds.numericColumn(name);
    final r = normalityTest(v);
    _report = AnalysisReport(
      title: l10n.normalityTitle,
      subtitle: name,
      sections: [
        ReportSection(
          heading: l10n.resultWord,
          tables: [
            ReportTable(
              headers: [
                l10n.testWord, l10n.statistic, 'p',
                l10n.skewness, l10n.kurtosis, l10n.verdictWord,
              ],
              rows: [
                [
                  r.test,
                  formatNum(r.statistic),
                  formatP(r.p),
                  formatNum(r.skewness),
                  formatNum(r.kurtosis),
                  r.looksNormal ? l10n.looksNormal : l10n.deviatesNormal,
                ],
              ],
            ),
          ],
          notes: l10n.normalityNote,
        ),
      ],
    );
  }

  void _runRoc() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectStateVar;
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final med = percentile(List.of(y.sublist(0, n))..sort(), 50);
    final pos = <double>[];
    final neg = <double>[];
    for (var i = 0; i < n; i++) {
      if (y[i] >= med) {
        pos.add(x[i]);
      } else {
        neg.add(x[i]);
      }
    }
    final r = rocCurve(pos, neg);
    _report = AnalysisReport(
      title: l10n.rocTitle,
      subtitle: '${_yVar!} (>=median) × ${_xVar!}',
      sections: [
        ReportSection(
          heading: l10n.aucSection,
          tables: [
            ReportTable(
              headers: ['AUC', 'SE', l10n.ciLower, l10n.ciUpper, 'N+', 'N-'],
              rows: [
                [
                  formatNum(r.auc),
                  formatNum(r.se),
                  formatNum(r.ciLower),
                  formatNum(r.ciUpper),
                  '${r.nPos}',
                  '${r.nNeg}',
                ],
              ],
            ),
          ],
          notes: l10n.rocNote,
        ),
      ],
    );
  }

  void _runTukey() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final groups = _splitByGroup(vName, _groupVar!);
    final labels = groups.keys.toList();
    final anova = OnewayAnova.compute(
      labels.map((k) => groups[k]!).toList(),
      labels: labels,
    );
    final pairs = tukeyHsd(anova);
    _report = AnalysisReport(
      title: l10n.tukeyTitle,
      subtitle: 'Tukey HSD · $vName by ${_groupVar!}',
      sections: [
        ReportSection(
          heading: l10n.pairwise,
          tables: [
            ReportTable(
              headers: [l10n.group1, l10n.group2, l10n.meanDiff, 'p', l10n.significant],
              rows: pairs
                  .map((e) => [
                        e.g1,
                        e.g2,
                        formatNum(e.meanDiff),
                        formatP(e.p),
                        e.significant ? 'Y' : '',
                      ])
                  .toList(),
            ),
          ],
          notes: l10n.tukeyNote(formatNum(anova.f), formatP(anova.p)),
        ),
      ],
    );
  }


  void _runFactor() {
    if (_selectedVars.length < 2) throw l10n.needTwoVars;
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorPca(cols, names: _selectedVars, maxFactors: 3);
    _report = AnalysisReport(
      title: l10n.factorPcaTitle,
      subtitle: 'PCA · ${_selectedVars.join(", ")}',
      sections: [
        ReportSection(
          heading: l10n.eigenSection,
          tables: [
            ReportTable(
              headers: [l10n.component, l10n.eigenvalue, l10n.varExplained, l10n.cumulative],
              rows: [
                for (var i = 0; i < r.eigenvalues.length; i++)
                  [
                    'PC${i + 1}',
                    formatNum(r.eigenvalues[i]),
                    '${(r.eigenvalues[i] / _selectedVars.length * 100).toStringAsFixed(1)}%',
                    '${(r.eigenvalues.sublist(0, i + 1).fold<double>(0, (a, b) => a + b) / _selectedVars.length * 100).toStringAsFixed(1)}%',
                  ],
              ],
            ),
            ReportTable(
              caption: l10n.loadingsMatrix,
              headers: [
                l10n.reportVar,
                for (var i = 0; i < r.eigenvalues.length; i++) 'PC${i + 1}'
              ],
              rows: [
                for (var v = 0; v < _selectedVars.length; v++)
                  [
                    r.variables[v],
                    for (final l in r.loadings[v]) formatNum(l),
                  ],
              ],
            ),
          ],
          notes: l10n.factorPcaNote(formatNum(r.totalVarianceExplained)),
        ),
      ],
    );
  }

  void _runLogistic() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectDepVar;
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final med = percentile(List.of(y.sublist(0, n))..sort(), 50);
    final xs = [x.sublist(0, n)];
    final ys = [
      for (var i = 0; i < n; i++) y[i] >= med ? 1 : 0,
    ];
    final r = logisticRegression(xs, ys, names: [_xVar!]);
    _report = AnalysisReport(
      title: l10n.logisticTitle,
      subtitle: '${_yVar!} (>=median) ~ ${_xVar!}',
      sections: [
        ReportSection(
          heading: l10n.modelWord,
          tables: [
            ReportTable(
              headers: [l10n.term, 'B (log-odds)', l10n.orExpB],
              rows: [
                for (var i = 0; i < r.coefficients.length; i++)
                  [
                    r.names[i],
                    formatNum(r.coefficients[i]),
                    formatNum(math.exp(r.coefficients[i])),
                  ],
              ],
            ),
            ReportTable(
              headers: [l10n.pseudoR2Mcfadden, l10n.accuracy, l10n.iterations],
              rows: [
                [
                  formatNum(r.pseudoR2),
                  '${(r.accuracy * 100).toStringAsFixed(1)}%',
                  '${r.iterations}',
                ],
              ],
            ),
          ],
          notes: l10n.logisticNote,
        ),
      ],
    );
  }


  void _runExamine() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    final r = examine(ds.numericColumn(name));
    _report = AnalysisReport(
      title: 'EXAMINE',
      subtitle: name,
      sections: [
        ReportSection(
          heading: l10n.examineDesc,
          tables: [
            ReportTable(
              headers: ['N', l10n.mean, 'SD', l10n.median, 'Q1', 'Q3', l10n.skewness, l10n.kurtosis],
              rows: [
                [
                  '${r.desc.n}',
                  formatNum(r.desc.mean),
                  formatNum(r.desc.sd),
                  formatNum(r.desc.median),
                  formatNum(r.desc.q1),
                  formatNum(r.desc.q3),
                  formatNum(r.desc.skewness),
                  formatNum(r.desc.kurtosis),
                ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: l10n.percentileWord,
          tables: [
            ReportTable(
              headers: ['P', l10n.valueWord],
              rows: [for (final p in r.percentiles.rows) ['${p.p}', formatNum(p.value)]],
            ),
          ],
          notes: l10n.trimmedNote(
              formatNum(r.percentiles.trimmedMean5),
              formatNum(r.percentiles.winsorizedMean5)),
        ),
        ReportSection(
          heading: l10n.extremes,
          tables: [
            ReportTable(
              headers: ['#', l10n.lowest, l10n.highest],
              rows: List.generate(
                r.extremes.lowest.length,
                (i) => [
                  '${i + 1}',
                  '${formatNum(r.extremes.lowest[i].value)} (${r.extremes.lowest[i].caseIndex})',
                  '${formatNum(r.extremes.highest[i].value)} (${r.extremes.highest[i].caseIndex})',
                ],
              ),
            ),
          ],
        ),
        ReportSection(
          heading: l10n.boxSection,
          tables: [
            ReportTable(
              headers: [l10n.lowerWhisker, 'Q1', l10n.medianShort, 'Q3', l10n.upperWhisker, l10n.outliers],
              rows: [
                [
                  formatNum(r.box.lowerWhisker),
                  formatNum(r.box.q1),
                  formatNum(r.box.median),
                  formatNum(r.box.q3),
                  formatNum(r.box.upperWhisker),
                  '${r.box.outliers.length}',
                ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: l10n.stemLeaf,
          body: '${r.stemLeaf.header}\n${r.stemLeaf.rows.map((e) => '${e.stem} | ${e.leaf}  (${e.frequency})').join('\n')}',
        ),
        ReportSection(
          heading: l10n.normalityDap,
          tables: [
            ReportTable(
              headers: [l10n.zSkew, l10n.zKurt, 'χ²', 'df', 'p', l10n.verdictWord],
              rows: [
                [
                  formatNum(r.normality.zSkew),
                  formatNum(r.normality.zKurt),
                  formatNum(r.normality.chiSquare),
                  '2',
                  formatP(r.normality.p),
                  r.normality.looksNormal ? l10n.looksNormal : l10n.deviatesNormal,
                ],
              ],
            ),
          ],
        ),
      ],
    );
    _chart = SizedBox(
      height: 280,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [
            for (final p in r.qq) ScatterSpot(p.theoretical, p.sample),
          ],
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  void _runBoxplot() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    List<BoxPlotData> boxes;
    List<String> labels;
    if (_groupVar != null) {
      final g = _splitByGroup(name, _groupVar!);
      labels = g.keys.toList();
      boxes = boxPlotGroups(labels.map((k) => g[k]!).toList());
    } else {
      labels = [name];
      boxes = [boxPlot(ds.numericColumn(name))];
    }
    _report = AnalysisReport(
      title: l10n.boxplotTitle,
      subtitle: name,
      sections: [
        ReportSection(
          heading: l10n.distSummary,
          tables: [
            ReportTable(
              headers: [l10n.group, 'N', l10n.median, 'Q1', 'Q3', 'IQR', l10n.outliers],
              rows: [
                for (var i = 0; i < boxes.length; i++)
                  [
                    labels[i],
                    '${ds.numericColumn(name).length}',
                    formatNum(boxes[i].median),
                    formatNum(boxes[i].q1),
                    formatNum(boxes[i].q3),
                    formatNum(boxes[i].iqr),
                    '${boxes[i].outliers.length}',
                  ],
              ],
            ),
          ],
        ),
      ],
    );
    // simple chart as bar of quartiles is weak; use report only + QQ reuse skipped
  }

  void _runQQ() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    final pts = normalQQPointsStandardized(ds.numericColumn(name));
    _report = AnalysisReport(
      title: l10n.qqTitle,
      subtitle: name,
      sections: [
        ReportSection(
          heading: l10n.qqSection,
          body: l10n.qqNote(pts.length),
        ),
      ],
    );
    _chart = SizedBox(
      height: 280,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [for (final p in pts) ScatterSpot(p.theoretical, p.sample)],
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  void _runFactorFull() {
    if (_selectedVars.length < 2) throw l10n.needTwoVars;
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorAnalyze(cols, names: _selectedVars, maxFactors: 3, rotate: true);
    final rot = r.rotatedLoadings;
    _report = AnalysisReport(
      title: l10n.factorFullTitle,
      subtitle: 'PCA + Varimax',
      sections: [
        ReportSection(
          heading: l10n.adequacySection,
          tables: [
            ReportTable(
              headers: const ['KMO', 'Bartlett χ²', 'df', 'p'],
              rows: [
                [
                  formatNum(r.kmo.overall),
                  formatNum(r.bartlett.chiSquare),
                  formatNum(r.bartlett.df, digits: 0),
                  formatP(r.bartlett.p),
                ],
              ],
            ),
            ReportTable(
              caption: l10n.kmoPerVar,
              headers: [l10n.reportVar, 'KMO'],
              rows: [
                for (var i = 0; i < r.kmo.names.length; i++)
                  [r.kmo.names[i], formatNum(r.kmo.perVariable[i])],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: l10n.eigenCommunalities,
          tables: [
            ReportTable(
              headers: [l10n.reportVar, l10n.communality, 'PC1', 'PC2', 'PC3'],
              rows: [
                for (var v = 0; v < _selectedVars.length; v++)
                  [
                    _selectedVars[v],
                    formatNum(r.communalities[v]),
                    for (var c = 0; c < 3; c++)
                      c < r.unrotated.loadings[v].length
                          ? formatNum(r.unrotated.loadings[v][c])
                          : '—',
                  ],
              ],
            ),
          ],
        ),
        if (rot != null)
          ReportSection(
            heading: l10n.varimaxLoadings,
            tables: [
              ReportTable(
                headers: [
                  l10n.reportVar,
                  for (var i = 0; i < rot[0].length; i++) 'F${i + 1}'
                ],
                rows: [
                  for (var v = 0; v < rot.length; v++)
                    [
                      v < _selectedVars.length ? _selectedVars[v] : 'X${v + 1}',
                      for (final l in rot[v]) formatNum(l),
                    ],
                ],
              ),
            ],
            notes: l10n.rotationNote(formatNum(r.rotationSS)),
          ),
      ],
    );
  }


  void _runLogisticFull() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectDepVar;
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final med = percentile(List.of(y.sublist(0, n))..sort(), 50);
    final r = logisticRegressionFull(
      [x.sublist(0, n)],
      [for (var i = 0; i < n; i++) y[i] >= med ? 1 : 0],
      names: [_xVar!],
    );
    _report = AnalysisReport(
      title: l10n.logisticFullTitle,
      subtitle: '${_yVar!} ~ ${_xVar!}',
      sections: [
        ReportSection(
          heading: l10n.waldCoefficients,
          tables: [
            ReportTable(
              headers: [l10n.term, 'B', 'SE', 'Wald', 'p', 'OR', 'OR 95%CI'],
              rows: [
                for (final c in r.coefficients)
                  [
                    c.name,
                    formatNum(c.beta),
                    formatNum(c.se),
                    formatNum(c.wald),
                    formatP(c.p),
                    formatNum(c.oddsRatio),
                    '[${formatNum(c.orLower95)}, ${formatNum(c.orUpper95)}]',
                  ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: l10n.modelClassification,
          tables: [
            ReportTable(
              headers: [l10n.pseudoR2Mcfadden, 'Omnibus χ²', 'p', 'N'],
              rows: [
                [
                  formatNum(r.pseudoR2),
                  formatNum(r.omnibusChi),
                  formatP(r.omnibusP),
                  '${r.n}',
                ],
              ],
            ),
            ReportTable(
              caption: l10n.classificationTable,
              headers: [l10n.accuracy, l10n.sensitivity, l10n.specificity, l10n.precision],
              rows: [
                [
                  '${(r.table.accuracy * 100).toStringAsFixed(1)}%',
                  '${(r.table.sensitivity * 100).toStringAsFixed(1)}%',
                  '${(r.table.specificity * 100).toStringAsFixed(1)}%',
                  '${(r.table.precision * 100).toStringAsFixed(1)}%',
                ],
              ],
            ),
            ReportTable(
              caption: 'Hosmer-Lemeshow',
              headers: ['χ²', 'df', 'p', l10n.nGroups],
              rows: [
                [
                  formatNum(r.hl.chiSquare),
                  '${r.hl.df}',
                  formatP(r.hl.p),
                  '${r.hl.groups}',
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _runGlmTwo() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    // Use groupVar as A, and method-like second factor if available from selected else singleton B
    final aName = _groupVar!;
    final bName = _selectedVars.length > 1 ? _selectedVars[1] : aName;
    final gi = ds.indexOf(aName);
    final bi = ds.indexOf(bName);
    final vi = ds.indexOf(vName);
    if (gi < 0 || vi < 0) throw l10n.varNotFound;
    final cells = <(String, String), List<double>>{};
    for (final row in ds.cases) {
      final a = gi < row.length ? ds.variables[gi].displayValue(row[gi]) : null;
      final b = bi >= 0 && bi < row.length
          ? ds.variables[bi].displayValue(row[bi])
          : '—';
      final raw = vi < row.length ? row[vi] : null;
      if (a == null || raw is! num) continue;
      cells.putIfAbsent((a, b), () => []).add(raw.toDouble());
    }
    if (cells.isEmpty) throw l10n.noValidData;
    final r = cells.length == 1 || aName == bName
        ? glmOneWay({for (final e in cells.entries) e.key.$1: e.value}, yName: vName)
        : glmTwoWay(cells, yName: vName);
    _report = AnalysisReport(
      title: aName == bName ? l10n.glmOneTitle : l10n.glmTwoTitle,
      subtitle: vName,
      sections: [
        ReportSection(
          heading: l10n.betweenEffects,
          tables: [
            ReportTable(
              headers: [l10n.source, 'SS', 'df', 'MS', 'F', 'p', l10n.partialEta2],
              rows: [
                for (final t in r.terms)
                  [
                    t.name,
                    formatNum(t.ss),
                    '${t.df}',
                    formatNum(t.ms),
                    formatNum(t.f),
                    formatP(t.p),
                    formatNum(t.partialEta2),
                  ],
                [
                  l10n.errorWord,
                  formatNum(r.ssError),
                  '${r.dfError}',
                  formatNum(r.msError),
                  '',
                  '',
                  '',
                ],
              ],
            ),
          ],
          notes: l10n.glmNote(formatNum(r.r2), formatNum(r.adjR2),
              formatNum(r.rmse), r.n),
        ),
      ],
    );
  }

  void _runStepwise() {
    if (_selectedVars.length < 2) throw l10n.pleaseSelectPredictors;
    if (_yVar == null) throw l10n.pleaseSelectDepVar;
    final y = ds.numericColumn(_yVar!);
    final names = List<String>.from(_selectedVars);
    final xs = [for (final n in names) ds.numericColumn(n)];
    final n = y.length < xs.first.length ? y.length : xs.first.length;
    final r = stepwiseRegression(
      [for (final col in xs) col.sublist(0, n)],
      y.sublist(0, n),
      names: names,
      method: StepwiseMethod.both,
    );
    _report = AnalysisReport(
      title: l10n.stepwiseTitle,
      subtitle: '${_yVar!} ~ stepwise',
      sections: [
        ReportSection(
          heading: l10n.enteredVars,
          body: r.selected.isEmpty ? l10n.noneEntered : r.selected.join(', '),
          tables: [
            ReportTable(
              headers: [l10n.step, l10n.action, l10n.reportVar, 'R²', l10n.adjR2],
              rows: [
                for (var i = 0; i < r.steps.length; i++)
                  [
                    '${i + 1}',
                    r.steps[i].action == 'enter' ? l10n.enter : l10n.remove,
                    r.steps[i].variable,
                    formatNum(r.steps[i].r2),
                    formatNum(r.steps[i].adjR2),
                  ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _runCtables() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectRowCol;
    final rowKeys = ds.rawColumn(_yVar!);
    final colKeys = ds.rawColumn(_xVar!);
    final r = crosstabSummary(
      rowKeys: rowKeys,
      colKeys: colKeys,
      rowVar: _yVar!,
      colVar: _xVar!,
      summary: CellSummary.count,
      rowLabels: {
        for (final e in ds.variables[ds.indexOf(_yVar!)].valueLabels.entries)
          e.key: e.value,
      },
      colLabels: {
        for (final e in ds.variables[ds.indexOf(_xVar!)].valueLabels.entries)
          e.key: e.value,
      },
    );
    _report = AnalysisReport(
      title: l10n.ctablesTitle,
      subtitle: '${_yVar!} × ${_xVar!}',
      sections: [
        ReportSection(
          heading: l10n.summaryCounts,
          tables: [
            ReportTable(
              headers: ['', ...r.colLabels, l10n.total],
              rows: [
                for (var i = 0; i < r.rowLabels.length; i++)
                  [
                    r.rowLabels[i],
                    for (final c in r.cells[i]) c.display,
                    r.rowTotals[i].display,
                  ],
                [
                  l10n.total,
                  for (final c in r.colTotals) c.display,
                  r.grandTotal.display,
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  AnalysisReport _nonparamReport(NonparametricResult r) {
    return AnalysisReport(
      title: r.testName,
      subtitle: l10n.nonparamSubtitle,
      sections: [
        ReportSection(
          heading: l10n.testResult,
          tables: [
            ReportTable(
              headers: [l10n.statistic, l10n.valueWord, 'Z', 'p'],
              rows: [
                [
                  r.statisticName,
                  formatNum(r.statistic),
                  r.z == null ? '—' : formatNum(r.z!),
                  formatP(r.p),
                ],
              ],
            ),
            ReportTable(
              headers: ['n1', 'n2', l10n.meanRank1, l10n.meanRank2],
              rows: [
                [
                  '${r.n1}',
                  '${r.n2}',
                  r.meanRank1 == null ? '—' : formatNum(r.meanRank1!),
                  r.meanRank2 == null ? '—' : formatNum(r.meanRank2!),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Map<String, List<double>> _splitByGroup(String valueVar, String groupVar) {
    final vi = ds.indexOf(valueVar);
    final gi = ds.indexOf(groupVar);
    if (vi < 0 || gi < 0) throw l10n.varNotFound;
    final out = <String, List<double>>{};
    for (final row in ds.cases) {
      final gRaw = gi < row.length ? row[gi] : null;
      final vRaw = vi < row.length ? row[vi] : null;
      if (gRaw == null || vRaw == null) continue;
      final v = vRaw is num
          ? vRaw.toDouble()
          : double.tryParse(vRaw.toString());
      if (v == null) continue;
      final label = ds.variables[gi].displayValue(gRaw);
      out.putIfAbsent(label, () => []).add(v);
    }
    return out;
  }
}

class _VarPicker extends StatelessWidget {
  final String label;
  final List<String> names;
  final List<String> selected;
  final bool single;
  final int? max;
  final ValueChanged<List<String>> onChanged;

  const _VarPicker({
    required this.label,
    required this.names,
    required this.selected,
    required this.onChanged,
    this.single = false,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: names.map((n) {
            final isSel = selected.contains(n);
            return FilterChip(
              label: Text(n),
              selected: isSel,
              onSelected: (v) {
                final list = List<String>.from(selected);
                if (single || max == 1) {
                  list
                    ..clear()
                    ..add(n);
                } else if (v) {
                  if (max != null && list.length >= max!) {
                    list.removeAt(0);
                  }
                  list.add(n);
                } else {
                  list.remove(n);
                }
                selected
                  ..clear()
                  ..addAll(list);
                onChanged(list);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ReportView extends StatelessWidget {
  final AnalysisReport report;
  const _ReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(report.subtitle,
              style: TextStyle(color: scheme.outline, fontSize: 13)),
          const Divider(height: 24),
          for (final s in report.sections) ...[
            Text(s.heading,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (s.body != null) ...[
              const SizedBox(height: 6),
              Text(s.body!),
            ],
            for (final t in s.tables) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _TableWidget(table: t),
              ),
            ],
            if (s.notes != null) ...[
              const SizedBox(height: 8),
              Text(s.notes!,
                  style: TextStyle(color: scheme.outline, fontSize: 12)),
            ],
            const SizedBox(height: 16),
          ],
          Text(
            l10n.generatedAt(report.createdAt.toLocal().toIso8601String()),
            style: TextStyle(color: scheme.outline, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TableWidget extends StatelessWidget {
  final ReportTable table;
  const _TableWidget({required this.table});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (table.caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(table.caption!,
                style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        DataTable(
          headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12),
          dataTextStyle: const TextStyle(fontSize: 12),
          columns: [
            for (final h in table.headers) DataColumn(label: Text(h)),
          ],
          rows: [
            for (final r in table.rows)
              DataRow(cells: [
                for (var i = 0; i < table.headers.length; i++)
                  DataCell(Text(i < r.length ? r[i] : '')),
              ]),
          ],
        ),
      ],
    );
  }
}

class _ScatterClusters extends StatelessWidget {
  final List<List<double>> pts;
  final List<int> assignments;
  final List<ClusterCenter> centers;
  const _ScatterClusters({
    required this.pts,
    required this.assignments,
    required this.centers,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [
            for (var i = 0; i < pts.length; i++)
              ScatterSpot(pts[i][0], pts[i][1]),
            for (final c in centers)
              ScatterSpot(c.centroid[0], c.centroid[1]),
          ],
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}

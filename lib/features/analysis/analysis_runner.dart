import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/io/missing_aware.dart';
import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';
import '../../shared/ui/charts/charts.dart';
import '../../shared/ui/ui.dart';
import '../output/report_builder.dart';
import '../output/report_export.dart';
import '../output/section_export_menu.dart';

class AnalysisRunner extends StatefulWidget {
  final String analysisId;
  final String title;
  const AnalysisRunner({super.key, required this.analysisId, required this.title});

  @override
  State<AnalysisRunner> createState() => _AnalysisRunnerState();
}

class _AnalysisRunnerState extends State<AnalysisRunner> {
  List<String> _selectedVars = [];
  String? _groupVar;
  String? _yVar;
  String? _xVar;

  /// GLM 双元的第二个因素（可选，null = 单因素）。
  String? _factorB;
  String _corMethod = 'Pearson';
  int _kClusters = 3;
  final _muCtrl = TextEditingController(text: '0');
  AnalysisReport? _report;
  Widget? _chart;

  /// 与 [_chart] 配套的图例（每次运行前清空，避免串味）。
  List<ChartLegendItem> _legend = const [];
  bool _busy = false;
  String? _error;

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
      body: ConstrainedContent(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.x3,
            bottom: AppSpacing.x6,
          ),
          children: [
            _buildParams(),
            const SizedBox(height: AppSpacing.x4),
            if (_error != null) ...[
              InlineError(message: _error!),
              const SizedBox(height: AppSpacing.x3),
            ],
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
              const SizedBox(height: AppSpacing.x5),
              _ReportView(report: _report!),
            ],
            if (_chart != null) ...[
              const SizedBox(height: AppSpacing.x4),
              ChartCard(
                title: l10n.chartSection,
                height: 260,
                legend: _legend,
                child: Semantics(
                  container: true,
                  label: '${l10n.chartSection}. ${l10n.chartSemanticsHint}',
                  child: _chart!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // —— 参数需求表 ——
  // 把「哪个分析要哪些选择器」集中定义。目录（analysis_catalog）新增条目时，
  // 必须在这里归入某一类，否则运行时只会报「请选择变量」而无处可选。

  /// 只需一个数值变量（无分组）。
  static const Set<String> _singleVarOnly = {
    'qqplot',
    'normality',
    'examine_full',
  };

  /// 一个数值变量 + 必需分组变量。
  static const Set<String> _varPlusGroup = {
    'ttest_ind',
    'anova',
    'mannwhitney',
    'kruskal',
    'means',
    'tukey',
    'glm_two',
  };

  /// 一个数值变量 + 可选分组变量（不选则按单组处理）。
  static const Set<String> _varPlusOptionalGroup = {
    'boxplot',
    'errorbar',
  };

  /// 多选数值变量。
  static const Set<String> _multiVar = {
    'descriptives',
    'frequencies',
    'explore',
    'histogram',
    'bar',
    'reliability',
    'correlation',
    'factor_pca',
    'factor_full',
  };

  /// 成对变量（正好 2 个）。
  static const Set<String> _pairedVar = {'ttest_paired', 'wilcoxon'};

  /// Y / X 两个下拉（数值变量）。
  static const Set<String> _xyVar = {
    'regression',
    'scatter',
    'kmeans',
    'roc',
    'logistic',
    'logistic_full',
  };

  bool _needsSingleVar(String id) =>
      id == 'ttest_one' ||
      _singleVarOnly.contains(id) ||
      _varPlusGroup.contains(id) ||
      _varPlusOptionalGroup.contains(id);

  String _yLabel(String id, AppLocalizations l10n) => switch (id) {
        'regression' || 'logistic' || 'logistic_full' => l10n.dependentVar,
        'roc' => l10n.stateVar,
        _ => l10n.varY,
      };

  String _xLabel(String id, AppLocalizations l10n) => switch (id) {
        'regression' || 'logistic' || 'logistic_full' => l10n.independentVar,
        'roc' => l10n.testVar,
        _ => l10n.varX,
      };

  Widget _buildParams() {
    final l10n = AppLocalizations.of(context);
    final id = widget.analysisId;
    final allVars = ds.variables.map((v) => v.name).toList();

    Widget singleVarPicker() => ParamVarPicker(
          label: l10n.analysisVariable,
          names: _numericVars,
          selected: _selectedVars.take(1).toList(),
          single: true,
          onChanged: (v) => setState(() => _selectedVars = v),
        );

    Widget groupDropdown({required bool optional}) => _Dropdown(
          label: optional ? l10n.groupVariableOptional : l10n.groupVariable,
          value: _groupVar,
          items: allVars,
          clearable: optional,
          onChanged: (v) => setState(() => _groupVar = v),
        );

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
            if (_multiVar.contains(id))
              ParamVarPicker(
                label: l10n.selectVariables,
                names: _numericVars,
                selected: _selectedVars,
                onChanged: (v) => setState(() => _selectedVars = v),
              )
            else if (_needsSingleVar(id))
              singleVarPicker(),
            if (_pairedVar.contains(id))
              ParamVarPicker(
                label: l10n.pairVariables,
                names: _numericVars,
                selected: _selectedVars,
                max: 2,
                onChanged: (v) => setState(() => _selectedVars = v),
              ),
            if (_varPlusGroup.contains(id) ||
                _varPlusOptionalGroup.contains(id)) ...[
              const SizedBox(height: 12),
              groupDropdown(optional: _varPlusOptionalGroup.contains(id)),
            ],
            if (id == 'glm_two') ...[
              const SizedBox(height: 12),
              _Dropdown(
                label: l10n.factorB,
                value: _factorB,
                items: allVars,
                clearable: true,
                onChanged: (v) => setState(() => _factorB = v),
              ),
            ],
            if (id == 'ttest_one') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _muCtrl,
                decoration: InputDecoration(labelText: l10n.testValue),
                keyboardType: TextInputType.number,
              ),
            ],
            if (id == 'stepwise') ...[
              _Dropdown(
                label: l10n.dependentVar,
                value: _yVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              ParamVarPicker(
                label: l10n.predictors,
                names: _numericVars,
                selected: _selectedVars,
                onChanged: (v) => setState(() => _selectedVars = v),
              ),
            ],
            if (_xyVar.contains(id)) ...[
              _Dropdown(
                label: _yLabel(id, l10n),
                value: _yVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: _xLabel(id, l10n),
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
            if (id == 'crosstabs' || id == 'ctables') ...[
              _Dropdown(
                label: l10n.rowVariable,
                value: _yVar,
                items: allVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: l10n.columnVariable,
                value: _xVar,
                items: allVars,
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
      _error = null;
      _report = null;
      _chart = null;
      _legend = const [];
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
        case 'errorbar':
          _runErrorBar();
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
      _error = e.toString();
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
    _chart = ClusterScatterChart(
      points: [for (var i = 0; i < n; i++) Offset(x[i], y[i])],
      assignments: r.assignments,
      centers: [
        for (final c in r.centers) Offset(c.centroid[0], c.centroid[1]),
      ],
      emptyLabel: l10n.chartNoData,
    );
    _legend = [
      for (var c = 0; c < r.centers.length; c++)
        ChartLegendItem(
          color: context.appColors.chartAt(c),
          label: '${l10n.cluster} ${c + 1}',
        ),
      ChartLegendItem(
        color: Theme.of(context).colorScheme.outline,
        label: l10n.legendClusterCenter,
      ),
    ];
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
    _chart = HistogramChart(
      bins: bins,
      emptyLabel: l10n.chartNoData,
      xTitle: name,
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
    _chart = ScatterChartView(
      points: [for (var i = 0; i < n; i++) Offset(x[i], y[i])],
      emptyLabel: l10n.chartNoData,
      xTitle: _xVar,
      yTitle: _yVar,
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
    _chart = FrequencyBarChart(
      rows: freq.rows,
      emptyLabel: l10n.chartNoData,
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
    _chart = QQPlot(
      points: r.qq,
      emptyLabel: l10n.chartNoData,
      xTitle: l10n.theoreticalQuantile,
      yTitle: l10n.sampleQuantile,
    );
  }

  void _runErrorBar() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw l10n.pleaseSelectVar;
    final groups = _groupVar != null
        ? _splitByGroup(name, _groupVar!)
        : {name: ds.numericColumn(name)};
    final bars = errorBarsFromGroups(groups);
    final nAll = groups.values.fold<int>(0, (a, b) => a + b.length);
    final grandMean = nAll == 0
        ? null
        : groups.values
                .expand((e) => e)
                .fold<double>(0, (a, b) => a + b) /
            nAll;
    _report = AnalysisReport(
      title: l10n.errorBarTitle,
      subtitle: _groupVar == null ? name : '$name by ${_groupVar!}',
      sections: [
        ReportSection(
          heading: l10n.distSummary,
          tables: [
            ReportTable(
              headers: [l10n.group, 'N', l10n.mean, 'SD', l10n.se, l10n.ci95],
              rows: [
                for (final b in bars)
                  [
                    b.label,
                    '${b.n}',
                    formatNum(b.mean),
                    formatNum(b.se * math.sqrt(b.n)),
                    formatNum(b.se),
                    '[${formatNum(b.low)}, ${formatNum(b.high)}]',
                  ],
              ],
            ),
          ],
          notes: l10n.errorBarNote,
        ),
      ],
    );
    final accent = context.appColors.chartAt(0);
    _chart = ErrorBarChart(
      bars: bars,
      emptyLabel: l10n.chartNoData,
      referenceLine: grandMean,
      tooltips: [
        for (final b in bars)
          [
            b.label,
            '${l10n.mean}: ${formatNum(b.mean)}',
            '${l10n.ci95} [${formatNum(b.low)}, ${formatNum(b.high)}]',
            '${l10n.caseCount}: ${b.n}',
          ].join('\n'),
      ],
    );
    _legend = [
      ChartLegendItem(color: accent, label: l10n.legendMean),
      ChartLegendItem(color: context.appColors.ci, label: l10n.legendCi),
    ];
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
          notes: [
            l10n.boxPlotNote,
            if (boxes.length > BoxPlotChart.maxGroups)
              l10n.moreGroupsHidden(boxes.length - BoxPlotChart.maxGroups),
          ].join(' '),
        ),
      ],
    );
    final scheme = Theme.of(context).colorScheme;
    final accent = context.appColors.chartAt(0);
    final hidden = boxes.length - BoxPlotChart.maxGroups;
    _chart = BoxPlotChart(
      boxes: boxes,
      labels: labels,
      emptyLabel: l10n.chartNoData,
      overflowLabel: hidden > 0 ? l10n.moreGroupsHidden(hidden) : null,
      tooltips: [
        for (var i = 0; i < boxes.length; i++)
          _boxTooltip(l10n, labels[i], boxes[i]),
      ],
    );
    _legend = [
      ChartLegendItem(
        color: accent.withValues(alpha: 0.35),
        label: l10n.legendBox,
      ),
      ChartLegendItem(color: accent, label: l10n.legendMedian),
      ChartLegendItem(color: scheme.outline, label: l10n.legendMean),
    ];
  }

  /// 箱线图悬停提示：中位数 / 均值 / 四分位 / 须 / 离群数。
  String _boxTooltip(AppLocalizations l10n, String label, BoxPlotData b) {
    return [
      label,
      '${l10n.median}: ${formatNum(b.median)}',
      '${l10n.mean}: ${formatNum(b.mean)}',
      'Q1–Q3: ${formatNum(b.q1)} – ${formatNum(b.q3)}',
      '${l10n.whisker}: ${formatNum(b.lowerWhisker)} – ${formatNum(b.upperWhisker)}',
      '${l10n.outliers}: ${b.outliers.length}',
    ].join('\n');
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
    _chart = QQPlot(
      points: pts,
      emptyLabel: l10n.chartNoData,
      xTitle: l10n.theoreticalQuantile,
      yTitle: l10n.sampleQuantile,
    );
    _legend = [
      ChartLegendItem(
        color: context.appColors.chartAt(0),
        label: l10n.sampleQuantile,
      ),
      ChartLegendItem(
        color: Theme.of(context).colorScheme.outline,
        label: l10n.qqRefLine,
      ),
      ChartLegendItem(
        color: context.appColors.warning,
        label: l10n.legendTopDeviation(3),
      ),
    ];
  }

  void _runFactorFull() {
    if (_selectedVars.length < 2) throw l10n.needTwoVars;
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorAnalyze(cols, names: _selectedVars, maxFactors: 3, rotate: true);
    final rot = r.rotatedLoadings;
    final kept = r.unrotated.eigenvalues;
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
        ReportSection(
          heading: l10n.screePlot,
          body: l10n.screeNote(kept.length),
        ),
      ],
    );
    final p = _selectedVars.length;
    final cum = kept.fold<double>(0, (a, b) => a + b);
    final elbow = ScreePlot.elbowComponent(kept);
    final scheme = Theme.of(context).colorScheme;
    _chart = ScreePlot(
      eigenvalues: kept,
      emptyLabel: l10n.chartNoData,
      componentLabel: (i) => 'PC$i',
    );
    _legend = [
      ChartLegendItem(
        color: context.appColors.chartAt(0),
        label: l10n.eigenvalue,
      ),
      if (elbow != null)
        ChartLegendItem(
          color: scheme.outline,
          label: l10n.elbowAt('PC$elbow'),
        ),
      ChartLegendItem(
        color: scheme.outlineVariant,
        label: '${l10n.cumulativeVariance} = '
            '${p == 0 ? 0 : (cum / p * 100).toStringAsFixed(1)}%',
      ),
    ];
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
    final bName = _factorB ?? aName;
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

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  /// 允许「不选」（可选分组 / 可选因素），首项为占位。
  final bool clearable;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.clearable = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        if (clearable) const DropdownMenuItem<String>(child: Text('—')),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
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
    final text = Theme.of(context).textTheme;

    return SelectionArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (report.subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            report.subtitle,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.shareReport,
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: report.toPlainText()),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copiedToClipboard),
                        duration: const Duration(milliseconds: 1200),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: AppSpacing.x5),
            for (final (i, s) in report.sections.indexed)
              _SectionBlock(
                section: s,
                reportTitle: report.title,
                index: i,
              ),
            Text(
              l10n.generatedAt(report.createdAt.toLocal().toIso8601String()),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 报告分区：标题 + 可选复制 + 正文 + 表格 + 注释。
class _SectionBlock extends StatelessWidget {
  final ReportSection section;

  /// 所属报告标题（分区导出时作为一级标题与文件名的一部分）。
  final String reportTitle;

  /// 分区序号（纯中文标题回退为 `section-N`）。
  final int index;

  const _SectionBlock({
    required this.section,
    required this.reportTitle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                section.heading,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SectionExportMenu(
              section: section,
              reportTitle: reportTitle,
              index: index,
            ),
          ],
        ),
        if (section.body != null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.x2,
              top: AppSpacing.x1,
            ),
            child: Text(
              section.body!,
              style: text.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        for (final t in section.tables) ...[
          const SizedBox(height: AppSpacing.x2),
          _TableWidget(table: t),
        ],
        if (section.notes != null) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(
            section.notes!,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x5),
      ],
    );
  }
}

class _TableWidget extends StatelessWidget {
  final ReportTable table;
  const _TableWidget({required this.table});

  static final RegExp _numericRe = RegExp(r'^-?[0-9][0-9,.\s]*%?$');
  static final RegExp _starRe = RegExp(r'^(.*?)\s*(\*{1,3})$');
  static final RegExp _pHeaderRe = RegExp(
    r'^(p\b|p值|sig\.?\b|显著性)',
    caseSensitive: false,
  );

  /// 从 `.023` / `<.001` / `0.023` 解析 p 值；无法解析返回 null。
  static double? _parseP(String s) {
    final t = s.trim();
    if (t.isEmpty || t == '—' || t == '-') return null;
    if (t.startsWith('<') || t.startsWith('≤')) {
      final v = _toDouble(t.substring(1).trim());
      return v == null ? null : v / 2;
    }
    return _toDouble(t);
  }

  static double? _toDouble(String t) {
    final v = t.startsWith('.') ? '0$t' : t;
    return double.tryParse(v.replaceAll(',', ''));
  }

  static String _starsFor(double p) =>
      p < 0.001 ? '***' : (p < 0.01 ? '**' : (p < 0.05 ? '*' : ''));

  static double _pForStars(String stars) => switch (stars.length) {
        >= 3 => 0.0005,
        2 => 0.005,
        _ => 0.03,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cols = table.headers.length;

    // 全列数值 → 右对齐（首列除外）
    final numericCol = <bool>[
      for (var c = 0; c < cols; c++)
        c > 0 &&
            table.rows.any((r) => c < r.length && r[c].trim().isNotEmpty) &&
            table.rows
                .where((r) => c < r.length && r[c].trim().isNotEmpty)
                .every((r) => _numericRe.hasMatch(r[c].trim())),
    ];

    // p 值列：着色 + 星级（颜色与文字冗余表达，色盲友好）
    final pCol = <bool>[
      for (final h in table.headers) _pHeaderRe.hasMatch(h.trim()),
    ];

    Widget cell(String s, int c, {required bool header}) {
      final numeric = !header && numericCol[c];
      var label = s;
      var stars = '';
      double? p;
      if (!header && s.trim().isNotEmpty) {
        if (c < pCol.length && pCol[c]) {
          p = _parseP(s);
          if (p != null) stars = _starsFor(p);
        } else {
          // 相关系数等单元格自带星号，如 "0.62 **"
          final m = _starRe.firstMatch(s.trim());
          if (m != null && m.group(1)!.trim().isNotEmpty) {
            label = m.group(1)!.trim();
            stars = m.group(2)!;
            p = _pForStars(stars);
          }
        }
      }
      final color = (header || p == null)
          ? null
          : (stars.isEmpty ? scheme.onSurfaceVariant : pValueColor(context, p));

      return Container(
        constraints: BoxConstraints(minWidth: c == 0 ? 112 : 76),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: header ? AppSpacing.x2 : AppSpacing.x1 + 3,
        ),
        alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: header
                    ? FontWeight.w700
                    : (stars.isEmpty ? FontWeight.w400 : FontWeight.w600),
                fontFeatures: const [FontFeature.tabularFigures()],
                color: header
                    ? scheme.onSurface
                    : (color ?? scheme.onSurfaceVariant),
              ),
            ),
            if (stars.isNotEmpty) ...[
              const SizedBox(width: 4),
              SignificanceBadge(text: stars, p: p, small: true),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.rMd,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.rMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (table.caption != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x3,
                    AppSpacing.x2,
                    AppSpacing.x3,
                    0,
                  ),
                  child: Text(
                    table.caption!,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                color: scheme.surfaceContainerHigh,
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++)
                      cell(c < table.headers.length ? table.headers[c] : '', c,
                          header: true),
                  ],
                ),
              ),
              for (var r = 0; r < table.rows.length; r++)
                Container(
                  decoration: BoxDecoration(
                    color: r.isOdd
                        ? scheme.surfaceContainerLow.withValues(alpha: 0.5)
                        : null,
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        cell(
                          c < table.rows[r].length ? table.rows[r][c] : '',
                          c,
                          header: false,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:statkit/statkit.dart';

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';
import '../output/report_builder.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_report != null)
            IconButton(
              tooltip: '分享报告',
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(_report!.toPlainText(),
                  subject: _report!.title),
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
            label: Text(_busy ? '计算中…' : '运行分析'),
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
            Text('分析参数',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (multiVars.contains(id))
              _VarPicker(
                label: '变量（可多选）',
                names: _numericVars,
                selected: _selectedVars,
                onChanged: (v) => setState(() {}),
              ),
            if (needGroup.contains(id)) ...[
              _VarPicker(
                label: '分析变量',
                names: _numericVars,
                selected: _selectedVars.take(1).toList(),
                single: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: '分组变量',
                value: _groupVar,
                items: ds.variables.map((v) => v.name).toList(),
                onChanged: (v) => setState(() => _groupVar = v),
              ),
            ],
            if (needPair.contains(id))
              _VarPicker(
                label: '配对变量（选 2 个）',
                names: _numericVars,
                selected: _selectedVars,
                max: 2,
                onChanged: (_) => setState(() {}),
              ),
            if (id == 'ttest_one') ...[
              _VarPicker(
                label: '检验变量',
                names: _numericVars,
                selected: _selectedVars.take(1).toList(),
                single: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _muCtrl,
                decoration: const InputDecoration(labelText: '检验值 μ₀'),
                keyboardType: TextInputType.number,
              ),
            ],
            if (needXY.contains(id)) ...[
              _Dropdown(
                label: id == 'regression' ? '因变量 Y' : '变量 Y',
                value: _yVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: id == 'regression' ? '自变量 X' : '变量 X',
                value: _xVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _xVar = v),
              ),
              if (id == 'kmeans') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('簇数 k'),
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
                label: '行变量',
                value: _yVar,
                items: ds.variables.map((v) => v.name).toList(),
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: '列变量',
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
        default:
          _report = AnalysisReport(
            title: widget.title,
            subtitle: '尚未实现',
            sections: const [
              ReportSection(
                  heading: '提示', body: '该分析正在开发中，可先使用描述统计与 t 检验。'),
            ],
          );
      }
    } catch (e) {
      _report = AnalysisReport(
        title: widget.title,
        subtitle: '错误',
        sections: [
          ReportSection(heading: '运行失败', body: e.toString()),
        ],
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  void _runDescriptives() {
    final map = <String, Descriptives>{};
    for (final name in _selectedVars) {
      map[name] = Descriptives.compute(ds.numericColumn(name));
    }
    if (map.isEmpty) throw '请至少选择一个变量';
    _report = reportDescriptives(map, datasetName: ds.name);
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
    if (name == null) throw '请选择检验变量';
    final mu = double.tryParse(_muCtrl.text) ?? 0;
    final r = TTest.oneSample(ds.numericColumn(name), mu0: mu);
    _report = reportTTest(r, label: '单样本 $name vs μ=$mu');
  }

  void _runTTestInd() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    final groups = _splitByGroup(vName, _groupVar!);
    if (groups.length < 2) throw '分组变量至少需要 2 组';
    final keys = groups.keys.take(2).toList();
    final r = TTest.independentSamples(groups[keys[0]]!, groups[keys[1]]!);
    _report = reportTTest(r, label: '$vName by $_groupVar (${keys[0]} vs ${keys[1]})');
  }

  void _runTTestPaired() {
    if (_selectedVars.length < 2) throw '请选择 2 个配对变量';
    final a = ds.numericColumn(_selectedVars[0]);
    final b = ds.numericColumn(_selectedVars[1]);
    final n = a.length < b.length ? a.length : b.length;
    final r = TTest.paired(a.sublist(0, n), b.sublist(0, n));
    _report = reportTTest(r, label: '配对 ${_selectedVars[0]} vs ${_selectedVars[1]}');
  }

  void _runAnova() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    final groups = _splitByGroup(vName, _groupVar!);
    final labels = groups.keys.toList();
    final r = OnewayAnova.compute(
      labels.map((k) => groups[k]!).toList(),
      labels: labels,
    );
    _report = reportAnova(r, title: '单因素 ANOVA：$vName by $_groupVar');
  }

  void _runCorrelation() {
    if (_selectedVars.length < 2) throw '请至少选择 2 个变量';
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
    _report = reportCorrelation(matrix, method: _corMethod);
  }

  void _runRegression() {
    if (_yVar == null || _xVar == null) throw '请选择 Y 与 X';
    final y = ds.numericColumn(_yVar!);
    final x = ds.numericColumn(_xVar!);
    final n = x.length < y.length ? x.length : y.length;
    final r = Regression.simple(
        x.sublist(0, n), y.sublist(0, n),
        xName: _xVar!, yName: _yVar!);
    _report = reportRegression(r, yName: _yVar!);
  }

  void _runCrosstabs() {
    if (_yVar == null || _xVar == null) throw '请选择行、列变量';
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
    _report = reportChiSquare(r, title: '交叉表卡方：$_yVar × $_xVar');
  }

  void _runKmeans() {
    if (_yVar == null || _xVar == null) throw '请选择 2 个变量';
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
      title: 'K-Means 聚类',
      subtitle: 'k=$_kClusters · ${r.iterations} 次迭代 · inertia=${formatNum(r.inertia)}',
      sections: [
        ReportSection(
          heading: '最终聚类中心',
          tables: [
            ReportTable(
              headers: const ['簇', _xLabel, _yLabel, '个案数'],
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
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    final groups = _splitByGroup(vName, _groupVar!);
    final keys = groups.keys.take(2).toList();
    if (keys.length < 2) throw '至少两组';
    final r = Nonparametric.mannWhitney(groups[keys[0]]!, groups[keys[1]]!);
    _report = _nonparamReport(r);
  }

  void _runWilcoxon() {
    if (_selectedVars.length < 2) throw '请选择 2 个变量';
    final a = ds.numericColumn(_selectedVars[0]);
    final b = ds.numericColumn(_selectedVars[1]);
    final n = a.length < b.length ? a.length : b.length;
    final r = Nonparametric.wilcoxon(a.sublist(0, n), b.sublist(0, n));
    _report = _nonparamReport(r);
  }

  void _runKruskal() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    final groups = _splitByGroup(vName, _groupVar!);
    final r = Nonparametric.kruskalWallis(groups.values.toList());
    _report = _nonparamReport(r);
  }

  void _runReliability() {
    if (_selectedVars.length < 2) throw '请至少选择 2 个题目变量';
    final cols = _selectedVars.map((n) => ds.numericColumn(n)).toList();
    final n = cols.map((c) => c.length).reduce((a, b) => a < b ? a : b);
    final items = cols.map((c) => c.sublist(0, n)).toList();
    final r = Reliability.cronbachAlpha(items, names: _selectedVars);
    _report = AnalysisReport(
      title: '信度分析',
      subtitle: 'Cronbach α',
      sections: [
        ReportSection(
          heading: '可靠性统计量',
          tables: [
            ReportTable(
              headers: const ['Cronbach α', '标准化 α', '项数', 'N'],
              rows: [
                [formatNum(r.alpha), formatNum(r.standardizedAlpha), '${r.nItems}', '${r.nCases}'],
              ],
            ),
            ReportTable(
              caption: '项统计量',
              headers: const ['项', '均值', '方差', '校正项总相关', '删除项后 α'],
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
    if (name == null) throw '请选择变量';
    final values = ds.numericColumn(name);
    final bins = Frequencies.histogramBins(values);
    _report = AnalysisReport(
      title: '直方图',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '分箱频数',
          tables: [
            ReportTable(
              headers: const ['下限', '上限', '频数'],
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
    if (_xVar == null || _yVar == null) throw '请选择 X/Y';
    final x = ds.numericColumn(_xVar!);
    final y = ds.numericColumn(_yVar!);
    final n = x.length < y.length ? x.length : y.length;
    final r = Correlation.pearson(
        x.sublist(0, n), y.sublist(0, n));
    final fit = Regression.simple(x.sublist(0, n), y.sublist(0, n),
        xName: _xVar!, yName: _yVar!);
    _report = AnalysisReport(
      title: '散点图',
      subtitle: '$_yVar ~ $_xVar',
      sections: [
        ReportSection(
          heading: '相关与拟合',
          tables: [
            ReportTable(
              headers: const ['r', 'p', 'R²', '斜率', '截距'],
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
    if (name == null) throw '请选择变量';
    final raw = ds.rawColumn(name);
    final freq = Frequencies.compute(raw, variableName: name);
    _report = AnalysisReport(
      title: '条形图 / 频率',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '频率表',
          tables: [
            ReportTable(
              headers: const ['类别', '频数', '百分比', '有效百分比', '累计%'],
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
          notes: '有效 N=${freq.nValid}  缺失=${freq.nMissing}',
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
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    final groups = _splitByGroup(vName, _groupVar!);
    final r = meansTable(groups, layerVar: _groupVar!, valueVar: vName);
    _report = AnalysisReport(
      title: '分层均值',
      subtitle: '$vName by ${_groupVar!}',
      sections: [
        ReportSection(
          heading: 'Means',
          tables: [
            ReportTable(
              headers: const ['组', 'N', '均值', '标准差', '标准误', '中位数', '最小', '最大'],
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
                  '总计',
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
    if (name == null) throw '请选择变量';
    final v = ds.numericColumn(name);
    final r = normalityTest(v);
    _report = AnalysisReport(
      title: '正态性检验',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '结果',
          tables: [
            ReportTable(
              headers: const ['检验', '统计量', 'p', '偏度', '峰度', '判断'],
              rows: [
                [
                  r.test,
                  formatNum(r.statistic),
                  formatP(r.p),
                  formatNum(r.skewness),
                  formatNum(r.kurtosis),
                  r.looksNormal ? '近似正态' : '偏离正态',
                ],
              ],
            ),
          ],
          notes: 'p>0.05 且 |偏度|<1.5、|峰度|<3 时可近似认为正态。',
        ),
      ],
    );
  }

  void _runRoc() {
    if (_yVar == null || _xVar == null) throw '请选择状态变量与检验变量';
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
      title: 'ROC 曲线',
      subtitle: '${_yVar!} (>=median) × ${_xVar!}',
      sections: [
        ReportSection(
          heading: '曲线下面积',
          tables: [
            ReportTable(
              headers: const ['AUC', 'SE', '95%CI下', '95%CI上', 'N+', 'N-'],
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
          notes: 'AUC 0.5=无诊断力，0.7-0.8 中等，>0.8 较好。',
        ),
      ],
    );
  }

  void _runTukey() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw '请选择分析变量与分组变量';
    final groups = _splitByGroup(vName, _groupVar!);
    final labels = groups.keys.toList();
    final anova = OnewayAnova.compute(
      labels.map((k) => groups[k]!).toList(),
      labels: labels,
    );
    final pairs = tukeyHsd(anova);
    _report = AnalysisReport(
      title: '事后两两比较',
      subtitle: 'Tukey HSD · $vName by ${_groupVar!}',
      sections: [
        ReportSection(
          heading: 'Pairwise',
          tables: [
            ReportTable(
              headers: const ['组1', '组2', '均值差', 'p', '显著'],
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
          notes: '整体 F=${formatNum(anova.f)}, p=${formatP(anova.p)}。',
        ),
      ],
    );
  }


  void _runFactor() {
    if (_selectedVars.length < 2) throw '请至少选择 2 个变量';
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorPca(cols, names: _selectedVars, maxFactors: 3);
    _report = AnalysisReport(
      title: '主成分因子分析',
      subtitle: 'PCA · ${_selectedVars.join(", ")}',
      sections: [
        ReportSection(
          heading: '特征值与方差',
          tables: [
            ReportTable(
              headers: const ['成分', '特征值', '方差贡献率', '累计'],
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
              caption: '载荷矩阵',
              headers: [
                '变量',
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
          notes: '总方差解释率 ${formatNum(r.totalVarianceExplained)}。采用相关矩阵主成分法（未旋转）。',
        ),
      ],
    );
  }

  void _runLogistic() {
    if (_yVar == null || _xVar == null) throw '请选择因变量与自变量';
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
      title: '逻辑回归',
      subtitle: '${_yVar!} (>=median) ~ ${_xVar!}',
      sections: [
        ReportSection(
          heading: '模型',
          tables: [
            ReportTable(
              headers: const ['项', 'B (log-odds)', 'OR=exp(B)'],
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
              headers: const ['伪R² (McFadden)', '正确率', '迭代'],
              rows: [
                [
                  formatNum(r.pseudoR2),
                  '${(r.accuracy * 100).toStringAsFixed(1)}%',
                  '${r.iterations}',
                ],
              ],
            ),
          ],
          notes: '采用梯度下降拟合，样本量建议 ≥ 30。OR>1 表示风险增加。',
        ),
      ],
    );
  }


  void _runExamine() {
    final name = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (name == null) throw '请选择变量';
    final r = examine(ds.numericColumn(name));
    _report = AnalysisReport(
      title: 'EXAMINE',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '描述',
          tables: [
            ReportTable(
              headers: const ['N', '均值', 'SD', '中位数', 'Q1', 'Q3', '偏度', '峰度'],
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
          heading: '百分位',
          tables: [
            ReportTable(
              headers: const ['P', '值'],
              rows: [for (final p in r.percentiles.rows) ['${p.p}', formatNum(p.value)]],
            ),
          ],
          notes: '5% 截尾均值=${formatNum(r.percentiles.trimmedMean5)}  '
              'Winsorized=${formatNum(r.percentiles.winsorizedMean5)}',
        ),
        ReportSection(
          heading: '极值',
          tables: [
            ReportTable(
              headers: const ['#', '最小', '最大'],
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
          heading: '箱线',
          tables: [
            ReportTable(
              headers: const ['下须', 'Q1', '中位', 'Q3', '上须', '离群数'],
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
          heading: '茎叶图',
          body: '${r.stemLeaf.header}\n${r.stemLeaf.rows.map((e) => '${e.stem} | ${e.leaf}  (${e.frequency})').join('\n')}',
        ),
        ReportSection(
          heading: '正态性 (D\'Agostino-Pearson)',
          tables: [
            ReportTable(
              headers: const ['Z偏度', 'Z峰度', 'χ²', 'df', 'p', '判断'],
              rows: [
                [
                  formatNum(r.normality.zSkew),
                  formatNum(r.normality.zKurt),
                  formatNum(r.normality.chiSquare),
                  '2',
                  formatP(r.normality.p),
                  r.normality.looksNormal ? '近似正态' : '偏离正态',
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
    if (name == null) throw '请选择变量';
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
      title: '箱线图',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '分布摘要',
          tables: [
            ReportTable(
              headers: const ['组', 'N', '中位数', 'Q1', 'Q3', 'IQR', '离群'],
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
    if (name == null) throw '请选择变量';
    final pts = normalQQPointsStandardized(ds.numericColumn(name));
    _report = AnalysisReport(
      title: 'Q-Q 图',
      subtitle: name,
      sections: [
        ReportSection(
          heading: '正态分位对照',
          body: '点数 ${pts.length}；点越贴近 y=x 直线越接近正态。',
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
    if (_selectedVars.length < 2) throw '请至少选择 2 个变量';
    final cols = [for (final n in _selectedVars) ds.numericColumn(n)];
    final r = factorAnalyze(cols, names: _selectedVars, maxFactors: 3, rotate: true);
    final rot = r.rotatedLoadings;
    _report = AnalysisReport(
      title: '因子分析（全）',
      subtitle: 'PCA + Varimax',
      sections: [
        ReportSection(
          heading: '适切性与球形检验',
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
              caption: '逐变量 KMO',
              headers: const ['变量', 'KMO'],
              rows: [
                for (var i = 0; i < r.kmo.names.length; i++)
                  [r.kmo.names[i], formatNum(r.kmo.perVariable[i])],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: '特征值 / 共同度',
          tables: [
            ReportTable(
              headers: const ['变量', '共同度', 'PC1', 'PC2', 'PC3'],
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
            heading: 'Varimax 旋转载荷',
            tables: [
              ReportTable(
                headers: [
                  '变量',
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
            notes: '旋转平方和=${formatNum(r.rotationSS)}',
          ),
      ],
    );
  }

  AnalysisReport _nonparamReport(NonparametricResult r) {
    return AnalysisReport(
      title: r.testName,
      subtitle: '非参数检验',
      sections: [
        ReportSection(
          heading: '检验结果',
          tables: [
            ReportTable(
              headers: const ['统计量', '值', 'Z', 'p'],
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
              headers: const ['n1', 'n2', '平均秩1', '平均秩2'],
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
    if (vi < 0 || gi < 0) throw '变量不存在';
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

// 占位符常量避免字符串插值进 const
const _xLabel = 'X';
const _yLabel = 'Y';

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
            '生成时间：${report.createdAt.toLocal()}',
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

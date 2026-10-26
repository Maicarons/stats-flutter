import 'dart:math' as math;

// 应用是 statkit 的同仓第一消费者：应用发布与 statkit 版本绑定（当前
// statkit 0.5.0 ↔ app 1.4.0），两者的 API 调整在同一次发布里一起改，
// 因此这里可以有意使用 statkit 标注为 @experimental 的入口。
// ignore_for_file: experimental_member_use

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:statkit/statkit.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/io/missing_aware.dart';
import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';
import '../../shared/ui/charts/charts.dart';
import '../../shared/ui/ui.dart';
import '../output/output_store.dart';
import '../output/output_tree.dart';
import '../output/report_builder.dart';
import '../output/report_export_menu.dart';
import '../output/report_labels.dart';

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

  /// 置换检验的设计：false = 两独立样本，true = 配对样本。
  bool _permPaired = false;
  int _kClusters = 3;
  final _muCtrl = TextEditingController(text: '0');

  /// 输出树：同一分析连跑多次会累积（会话内保留，最新在最前）。
  List<AnalysisReport> _reports = const [];

  /// 最近一次运行的报告（null = 还没跑过）。
  AnalysisReport? get _report => _reports.isEmpty ? null : _reports.first;

  /// 分析实现统一用 `_report = …` 落结果：写进输出树，最新在最前。
  /// `_report = null` 仍然表示「清空输出」（目前只有测试与清空按钮会用到）。
  set _report(AnalysisReport? r) {
    if (r == null) {
      OutputStore.clear(widget.analysisId);
    } else {
      if (_splitPrefix != null) {
        r = AnalysisReport(
          title: '${r.title} · ${_splitPrefix!}',
          subtitle: r.subtitle,
          sections: r.sections,
          createdAt: r.createdAt,
        );
      }
      OutputStore.add(widget.analysisId, r);
    }
  }

  Widget? _chart;

  /// 与 [_chart] 配套的图例（每次运行前清空，避免串味）。
  List<ChartLegendItem> _legend = const [];
  bool _busy = false;
  String? _error;

  /// SPLIT FILE 生效时的组内数据（null = 用完整活动数据集）。
  Dataset? _dsOverride;

  /// 当前分组的标签（如 "gender = 1"），写进报告卡片标题。
  String? _splitPrefix;

  Dataset get ds => _dsOverride ?? datasetStore.data;
  AppLocalizations get l10n => AppLocalizations.of(context);

  List<String> get _numericVars => ds.variables
      .where((v) => v.isNumeric)
      .map((v) => v.name)
      .toList();

  @override
  void initState() {
    super.initState();
    // 输出树按分析页存在静态存储里：切页面再回来结果还在（重启即空）。
    _reports = OutputStore.of(widget.analysisId);
  }

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
          if (_reports.isNotEmpty)
            IconButton(
              tooltip: l10n.shareAllOutput,
              icon: const Icon(Icons.share),
              onPressed: () =>
                  SharePlus.instance.share(
                      ShareParams(text: _allText(), subject: widget.title)),
            ),
          if (_reports.isNotEmpty)
            PopupMenuButton<ReportFileKind>(
              tooltip: l10n.exportAllOutput,
              icon: const Icon(Icons.download_outlined),
              onSelected: _exportAll,
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: ReportFileKind.pdf,
                  child: Text(l10n.exportPdf),
                ),
                PopupMenuItem(
                  value: ReportFileKind.html,
                  child: Text(l10n.exportHtml),
                ),
                PopupMenuItem(
                  value: ReportFileKind.markdown,
                  child: Text(l10n.exportMarkdown),
                ),
              ],
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
            if (_reports.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x5),
              OutputTree(
                reports: _reports,
                nameBase: reportFileBase(widget.analysisId),
                onDelete: (r) =>
                    setState(() => OutputStore.remove(widget.analysisId, r)),
                onClear: _clearOutput,
              ),
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
    'jt_trend',
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
            if (id == 'ancova') ...[
              _Dropdown(
                label: l10n.dependentVar,
                value: _yVar,
                items: _numericVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              groupDropdown(optional: false),
              const SizedBox(height: 12),
              _Dropdown(
                label: l10n.factorB,
                value: _factorB,
                items: allVars,
                clearable: true,
                onChanged: (v) => setState(() => _factorB = v),
              ),
              const SizedBox(height: 12),
              ParamVarPicker(
                label: l10n.covariates,
                names: _numericVars,
                selected: _selectedVars,
                onChanged: (v) => setState(() => _selectedVars = v),
              ),
            ],
            if (id == 'multinomial') ...[
              _Dropdown(
                label: l10n.dependentVar,
                value: _yVar,
                items: allVars,
                onChanged: (v) => setState(() => _yVar = v),
              ),
              const SizedBox(height: 12),
              ParamVarPicker(
                label: l10n.independentVar,
                names: _numericVars,
                selected: _selectedVars,
                onChanged: (v) => setState(() => _selectedVars = v),
              ),
            ],
            if (id == 'permutation') ...[
              Text(l10n.permDesign,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.permIndependent)),
                  ButtonSegment(value: true, label: Text(l10n.permPaired)),
                ],
                selected: {_permPaired},
                onSelectionChanged: (s) =>
                    setState(() => _permPaired = s.first),
              ),
              const SizedBox(height: 12),
              if (_permPaired)
                ParamVarPicker(
                  label: l10n.pairVariables,
                  names: _numericVars,
                  selected: _selectedVars,
                  max: 2,
                  onChanged: (v) => setState(() => _selectedVars = v),
                )
              else ...[
                singleVarPicker(),
                const SizedBox(height: 12),
                groupDropdown(optional: false),
              ],
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

  /// 全部输出拼成一份（最新在前）；只跑过一次就是那一份本身。
  AnalysisReport get _combined => combinedReport(
        _reports,
        title: widget.title,
        createdAt: _reports.isEmpty ? null : _reports.first.createdAt,
      );

  /// 全部输出的纯文本（分享用，最新在前）。
  String _allText() => _reports.map((r) => r.toPlainText()).join('\n');

  /// 导出全部输出（HTML / Markdown / PDF）。
  Future<void> _exportAll(ReportFileKind kind) => exportReportFile(
        context,
        report: _combined,
        kind: kind,
        nameBase: reportFileBase(widget.analysisId),
      );

  /// 清空本页输出（危险操作，二次确认）。
  Future<void> _clearOutput() async {
    if (_reports.isEmpty) return;
    final ok = await showConfirmDialog(
      context,
      title: l10n.clearOutputTitle,
      message: l10n.clearOutputMessage,
      confirmLabel: l10n.clearOutput,
      danger: true,
      icon: Icons.delete_sweep_outlined,
    );
    if (!ok || !mounted) return;
    setState(() => OutputStore.clear(widget.analysisId));
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
      // 输出树刻意不清空：同一分析连跑多次要累积成多张卡片
      // （要清空走「清空输出」按钮）。
      _chart = null;
      _legend = const [];
    });
    try {
      final spec = datasetStore.data.splitVariable;
      if (spec != null && spec.isNotEmpty) {
        _runSplitAll(spec);
      } else {
        _dispatch();
      }
    } catch (e) {
      _error = e.toString();
    }
    _dsOverride = null;
    _splitPrefix = null;
    if (mounted) setState(() => _busy = false);
  }

  /// SPLIT FILE 语义：按拆分变量（逗号分隔，可多个）的组合分组，逐组以
  /// 组内数据运行当前分析；每组一张报告卡片，标题带组标签（PSPP 风格
  /// 「var = value」）。个别组内出错不中断其余组；全部失败才向上抛。
  void _runSplitAll(String spec) {
    final names = spec
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final base = datasetStore.data;
    final idxs = <int>[];
    for (final n in names) {
      final i = base.indexOf(n);
      if (i < 0) throw 'SPLIT FILE: unknown variable: $n';
      idxs.add(i);
    }
    final keys = <String>[];
    final groups = <String, List<List<Object?>>>{};
    for (final row in base.cases) {
      final parts = <String>[];
      for (final i in idxs) {
        final raw = i < row.length ? row[i] : null;
        parts.add(
            '${base.variables[i].name} = ${base.variables[i].displayValue(raw)}');
      }
      final key = parts.join(', ');
      if (!groups.containsKey(key)) {
        keys.add(key);
        groups[key] = [];
      }
      groups[key]!.add(row);
    }
    Object? firstError;
    var ranAny = false;
    for (final key in keys) {
      final g = Dataset(
        name: base.name,
        variables: base.variables.map((v) => v.copy()).toList(),
        cases: [for (final r in groups[key]!) List<Object?>.of(r)],
      )
        ..weightVariable = base.weightVariable
        ..mrSets = base.mrSets;
      _dsOverride = g;
      _splitPrefix = key;
      try {
        _dispatch();
        ranAny = true;
      } catch (e) {
        firstError ??= e;
      }
    }
    if (!ranAny && firstError != null) throw firstError;
  }

  void _dispatch() {
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
        case 'jt_trend':
          _runJtTrend();
          break;
        case 'permutation':
          _runPermutation();
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
        case 'ancova':
          _runAncova();
          break;
        case 'multinomial':
          _runMultinomial();
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
  }

  void _runDescriptives() {
    final map = <String, Descriptives>{};
    for (final name in _selectedVars) {
      map[name] = Descriptives.compute(MissingAware.numeric(ds, name));
    }
    if (map.isEmpty) throw l10n.pleaseSelectVars;
    _report = reportDescriptives(
      l10n,
      map,
      datasetName: ds.name,
      labels: variableLabels(ds, _selectedVars),
      labelNote: variableLabelNote(l10n, ds, _selectedVars),
    );
    final wName = ds.weightVariable;
    if (wName != null && wName.isNotEmpty) {
      final notes = StringBuffer('WEIGHT CASES: ');
      notes.writeln(wName);
      for (final name in _selectedVars) {
        // 规则 C：值与权重都非缺失的个案才进入加权统计
        final (v, w) = MissingAware.weighted(ds, name, wName);
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
        label: l10n.oneSampleLabel(variableLabel(ds, name), mu.toString()));
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
        label:
            '${variableLabel(ds, vName)} by ${variableLabel(ds, _groupVar!)} (${keys[0]} vs ${keys[1]})');
  }

  void _runTTestPaired() {
    if (_selectedVars.length < 2) throw l10n.pleaseSelectPaired;
    // 规则 B：成对完整个案（两变量都不缺失）
    final (a, b) = MissingAware.pairs(ds, _selectedVars[0], _selectedVars[1]);
    final r = TTest.paired(a, b);
    _report = reportTTest(
        l10n, r,
        label: l10n.pairedLabel(
            variableLabel(ds, _selectedVars[0]),
            variableLabel(ds, _selectedVars[1])));
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
        title: l10n.anovaOfLabel(
            variableLabel(ds, vName), variableLabel(ds, _groupVar!)));
  }

  void _runCorrelation() {
    if (_selectedVars.length < 2) throw l10n.needTwoVars;
    final matrix = <String, Map<String, CorrelationResult>>{};
    for (final a in _selectedVars) {
      matrix[a] = {};
      for (final b in _selectedVars) {
        final fn = _corMethod == 'Spearman'
            ? Correlation.spearman
            : Correlation.pearson;
        // 规则 B（成对删除，PSPP / SPSS 默认）：每一对单独取两者都有效的个案
        final (x, y) = MissingAware.pairs(ds, a, b);
        matrix[a]![b] = fn(x, y);
      }
    }
    _report = reportCorrelation(
      l10n,
      matrix,
      method: _corMethod,
      labels: variableLabels(ds, _selectedVars),
      labelNote: variableLabelNote(l10n, ds, _selectedVars),
    );
  }

  void _runRegression() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectXY;
    // 规则 B：成对完整个案
    final (x, y) = MissingAware.pairs(ds, _xVar!, _yVar!);
    final r = Regression.simple(x, y, xName: _xVar!, yName: _yVar!);
    _report = reportRegression(l10n, r, yName: variableLabel(ds, _yVar!));
  }

  void _runCrosstabs() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectRowCol;
    // 规则 E：用户缺失值不计入类别（记为缺失）
    final rowVals = MissingAware.raw(ds, _yVar!);
    final colVals = MissingAware.raw(ds, _xVar!);
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
    final rowVar = ds.variables[ds.indexOf(_yVar!)];
    final colVar = ds.variables[ds.indexOf(_xVar!)];
    _report = reportChiSquare(
      l10n,
      r,
      title: '${l10n.chiSquareTitle}: '
          '${variableLabel(ds, _yVar!)} × ${variableLabel(ds, _xVar!)}',
      rowVar: variableLabel(ds, _yVar!),
      colVar: variableLabel(ds, _xVar!),
      rowLabels: [for (final c in rowList) rowVar.displayValue(c)],
      colLabels: [for (final c in colList) colVar.displayValue(c)],
      labelNote: variableLabelNote(l10n, ds, [_yVar!, _xVar!]),
    );
  }

  void _runKmeans() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectTwoVars;
    // 规则 B：成对完整个案
    final (x, y) = MissingAware.pairs(ds, _xVar!, _yVar!);
    final n = x.length;
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
              headers: [
                l10n.cluster,
                variableLabel(ds, _xVar!),
                variableLabel(ds, _yVar!),
                l10n.caseCount,
              ],
              rows: rows,
            ),
          ],
          notes: variableLabelNote(l10n, ds, [_xVar!, _yVar!]),
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
    // 规则 B：成对完整个案
    final (a, b) = MissingAware.pairs(ds, _selectedVars[0], _selectedVars[1]);
    final r = Nonparametric.wilcoxon(a, b);
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
    // 规则 B：完全案例，列与列之间按个案对齐
    final items = MissingAware.alignedNumeric(ds, _selectedVars);
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
                        variableLabel(ds, e.name),
                        formatNum(e.mean),
                        formatNum(e.variance),
                        formatNum(e.itemTotalCorrelation),
                        formatNum(e.alphaIfDeleted),
                      ])
                  .toList(),
            ),
          ],
          notes: variableLabelNote(l10n, ds, _selectedVars),
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
      subtitle: variableLabel(ds, name),
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
    // 规则 B：成对完整个案
    final (x, y) = MissingAware.pairs(ds, _xVar!, _yVar!);
    final n = x.length;
    final r = Correlation.pearson(x, y);
    final fit = Regression.simple(x, y, xName: _xVar!, yName: _yVar!);
    _report = AnalysisReport(
      title: l10n.scatterTitle,
      subtitle:
          '${variableLabel(ds, _yVar!)} ~ ${variableLabel(ds, _xVar!)}',
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
    final raw = MissingAware.raw(ds, name);
    // 值标签：频数表与条形图的类别都显示标签（如 1 → 男）
    final freq = Frequencies.compute(
      raw,
      variableName: name,
      valueLabels: valueLabelsOf(ds, name),
    );
    _report = AnalysisReport(
      title: l10n.barTitle,
      subtitle: variableLabel(ds, name),
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
          notes: mergeNotes(
            l10n.freqNote(freq.nValid, freq.nMissing),
            variableLabelNote(l10n, ds, [name]),
          ),
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
      subtitle: '${variableLabel(ds, vName)} by '
          '${variableLabel(ds, _groupVar!)}',
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
      subtitle: variableLabel(ds, name),
      sections: [
        ReportSection(
          heading: l10n.resultWord,
          tables: [
            ReportTable(
              headers: [
                l10n.testWord, l10n.statistic, 'p', l10n.pKolmogorov,
                l10n.skewness, l10n.kurtosis, l10n.verdictWord,
              ],
              rows: [
                [
                  r.test,
                  formatNum(r.statistic),
                  formatP(r.p),
                  r.pKolmogorovAsymptotic.isFinite
                      ? formatP(r.pKolmogorovAsymptotic)
                      : '—',
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
      subtitle: '${variableLabel(ds, _yVar!)} (>=median) × '
          '${variableLabel(ds, _xVar!)}',
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
      subtitle: 'Tukey HSD · ${variableLabel(ds, vName)} by '
          '${variableLabel(ds, _groupVar!)}',
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
    // 规则 B：完全案例，列与列之间按个案对齐
    final cols = MissingAware.alignedNumeric(ds, _selectedVars);
    final r = factorPca(cols, names: _selectedVars, maxFactors: 3);
    _report = AnalysisReport(
      title: l10n.factorPcaTitle,
      subtitle: 'PCA · '
          '${_selectedVars.map((v) => variableLabel(ds, v)).join(", ")}',
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
                    variableLabel(ds, r.variables[v]),
                    for (final l in r.loadings[v]) formatNum(l),
                  ],
              ],
            ),
          ],
          notes: mergeNotes(l10n.factorPcaNote(formatNum(r.totalVarianceExplained)),
              variableLabelNote(l10n, ds, _selectedVars)),
        ),
      ],
    );
  }

  void _runLogistic() {
    if (_yVar == null || _xVar == null) throw l10n.pleaseSelectDepVar;
    // 规则 B：成对完整个案
    final (x, y) = MissingAware.pairs(ds, _xVar!, _yVar!);
    final med = percentile(List.of(y)..sort(), 50);
    final xs = [x];
    final ys = [
      for (final v in y) v >= med ? 1 : 0,
    ];
    final r = logisticRegression(xs, ys, names: [_xVar!]);
    _report = AnalysisReport(
      title: l10n.logisticTitle,
      subtitle: '${variableLabel(ds, _yVar!)} (>=median) ~ '
          '${variableLabel(ds, _xVar!)}',
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
      subtitle: variableLabel(ds, name),
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
      subtitle: _groupVar == null
          ? variableLabel(ds, name)
          : '${variableLabel(ds, name)} by ${variableLabel(ds, _groupVar!)}',
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
      subtitle: variableLabel(ds, name),
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
      subtitle: variableLabel(ds, name),
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
    // 规则 B：完全案例，列与列之间按个案对齐
    final cols = MissingAware.alignedNumeric(ds, _selectedVars);
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
                  [
                    variableLabel(ds, r.kmo.names[i]),
                    formatNum(r.kmo.perVariable[i]),
                  ],
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
                    variableLabel(ds, _selectedVars[v]),
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
                      v < _selectedVars.length
                          ? variableLabel(ds, _selectedVars[v])
                          : 'X${v + 1}',
                      for (final l in rot[v]) formatNum(l),
                    ],
                ],
              ),
            ],
            notes: mergeNotes(l10n.rotationNote(formatNum(r.rotationSS)),
                variableLabelNote(l10n, ds, _selectedVars)),
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
    // 规则 B：成对完整个案
    final (x, y) = MissingAware.pairs(ds, _xVar!, _yVar!);
    final med = percentile(List.of(y)..sort(), 50);
    final r = logisticRegressionFull(
      [x],
      [for (final v in y) v >= med ? 1 : 0],
      names: [_xVar!],
    );
    _report = AnalysisReport(
      title: l10n.logisticFullTitle,
      subtitle: '${variableLabel(ds, _yVar!)} ~ '
          '${variableLabel(ds, _xVar!)}',
      sections: [
        ReportSection(
          heading: l10n.waldCoefficients,
          tables: [
            ReportTable(
              headers: [l10n.term, 'B', 'SE', 'Wald', 'p', 'OR', 'OR 95%CI'],
              rows: [
                for (final c in r.coefficients)
                  [
                    variableLabel(ds, c.name),
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
          notes: variableLabelNote(l10n, ds, [_yVar!, _xVar!]),
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
      final aRaw = gi < row.length ? row[gi] : null;
      final bRaw = bi >= 0 && bi < row.length ? row[bi] : null;
      final raw = vi < row.length ? row[vi] : null;
      // 规则 A / D：分析变量与因子缺失（含用户缺失值）的个案整行剔除
      if (ds.variables[vi].isMissing(raw) ||
          ds.variables[gi].isMissing(aRaw) ||
          (bi >= 0 && ds.variables[bi].isMissing(bRaw))) {
        continue;
      }
      if (raw is! num) continue;
      final a = ds.variables[gi].displayValue(aRaw);
      final b = bi >= 0 ? ds.variables[bi].displayValue(bRaw) : '—';
      cells.putIfAbsent((a, b), () => []).add(raw.toDouble());
    }
    if (cells.isEmpty) throw l10n.noValidData;
    final r = cells.length == 1 || aName == bName
        ? glmOneWay({for (final e in cells.entries) e.key.$1: e.value}, yName: vName)
        : glmTwoWay(cells, yName: vName);
    _report = AnalysisReport(
      title: aName == bName ? l10n.glmOneTitle : l10n.glmTwoTitle,
      subtitle: variableLabel(ds, vName),
      sections: [
        ReportSection(
          heading: l10n.betweenEffects,
          tables: [
            ReportTable(
              headers: [l10n.source, 'SS', 'df', 'MS', 'F', 'p', l10n.partialEta2],
              rows: [
                for (final t in r.terms)
                  [
                    variableLabel(ds, t.name),
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
          notes: mergeNotes(
            l10n.glmNote(formatNum(r.r2), formatNum(r.adjR2), formatNum(r.rmse), r.n),
            variableLabelNote(l10n, ds, [
              vName,
              _groupVar!,
              if (_factorB != null && _factorB!.isNotEmpty) _factorB!,
            ]),
          ),
        ),
      ],
    );
  }

  /// 有序分组的水平顺序：先按值标签的键升序（1、2、3… 的语义顺序），
  /// 再把未被值标签覆盖的实际取值补上（数值按大小，其它按显示文本）。
  /// 用于 Jonckheere-Terpstra 与多项 logistic 的类别顺序。
  List<String> _orderedLevels(String groupVar) {
    final vi = ds.indexOf(groupVar);
    if (vi < 0) throw l10n.varNotFound;
    final v = ds.variables[vi];
    final out = <String>[];
    final seen = <String>{};
    for (final k in v.valueLabels.keys.toList()..sort()) {
      final label = v.valueLabels[k]!;
      if (seen.add(label)) out.add(label);
    }
    final rest = <Object?>[];
    for (final row in ds.cases) {
      if (vi >= row.length) continue;
      final raw = row[vi];
      if (v.isMissing(raw)) continue; // 规则 D：用户缺失值不算水平
      if (raw is num && v.valueLabels.containsKey(raw)) continue;
      rest.add(raw);
    }
    if (rest.every((e) => e is num)) {
      rest.sort((a, b) => (a as num).compareTo(b as num));
    } else {
      rest.sort((a, b) => v.displayValue(a).compareTo(v.displayValue(b)));
    }
    for (final raw in rest) {
      final label = v.displayValue(raw);
      if (label.isNotEmpty && seen.add(label)) out.add(label);
    }
    return out;
  }

  /// 有序备择的趋势检验：分组按 [_orderedLevels] 的顺序进入检验。
  void _runJtTrend() {
    final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
    if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
    final byLevel = _splitByGroup(vName, _groupVar!);
    final pairs = <(String, List<double>)>[
      for (final lv in _orderedLevels(_groupVar!))
        if (byLevel[lv] != null && byLevel[lv]!.isNotEmpty) (lv, byLevel[lv]!),
    ];
    if (pairs.length < 2) throw l10n.needTwoGroups;
    final r = NparExtended.jonckheereTerpstra([for (final e in pairs) e.$2]);
    final pOne = r.extra['pOneTail'] as double?;
    _report = AnalysisReport(
      title: l10n.jtTitle,
      subtitle: '${variableLabel(ds, vName)} · '
          '${variableLabel(ds, _groupVar!)}',
      sections: [
        ReportSection(
          heading: l10n.testResult,
          tables: [
            ReportTable(
              headers: [
                l10n.statistic,
                'Z',
                l10n.pTwoTail,
                l10n.pOneTail,
                'k',
                'N',
              ],
              rows: [
                [
                  formatNum(r.statistic),
                  r.z == null ? '—' : formatNum(r.z!),
                  formatP(r.p),
                  pOne == null ? '—' : formatP(pOne),
                  '${pairs.length}',
                  '${r.n1}',
                ],
              ],
            ),
            ReportTable(
              caption: l10n.groupVariable,
              headers: [l10n.group, 'n', l10n.mean, l10n.median],
              rows: [
                for (final (level, values) in pairs)
                  [
                    level,
                    '${values.length}',
                    formatNum(values.reduce((a, b) => a + b) / values.length),
                    formatNum(percentile(List.of(values)..sort(), 50)),
                  ],
              ],
            ),
          ],
          notes: l10n.jtNote,
        ),
      ],
    );
  }

  /// 置换检验：独立样本（均值差）或配对样本（差值的均值）。
  void _runPermutation() {
    const b = 9999;
    if (_permPaired) {
      if (_selectedVars.length < 2) throw l10n.pleaseSelectVars;
      // 规则 B：成对完整个案
      final (x, y) = MissingAware.pairs(ds, _selectedVars[0], _selectedVars[1]);
      final r = Permutation.pairedDifference(x, y, permutations: b);
      _report = _permReport(
        variableLabel(ds, _selectedVars[0]),
        variableLabel(ds, _selectedVars[1]),
        r,
      );
    } else {
      final vName = _selectedVars.isNotEmpty ? _selectedVars.first : null;
      if (vName == null || _groupVar == null) throw l10n.pleaseSelectGroup;
      final groups = _splitByGroup(vName, _groupVar!);
      if (groups.length < 2) throw l10n.needTwoGroups;
      final keys = groups.keys.take(2).toList();
      final r = Permutation.twoSampleMeanDifference(
        groups[keys[0]]!,
        groups[keys[1]]!,
        permutations: b,
      );
      _report = _permReport(keys[0], keys[1], r);
    }
  }

  AnalysisReport _permReport(String g1, String g2, PermutationResult r) {
    final design = _permPaired ? l10n.permPaired : l10n.permIndependent;
    return AnalysisReport(
      title: l10n.permTitle,
      subtitle: '$g1 vs $g2 · $design',
      sections: [
        ReportSection(
          heading: l10n.testResult,
          tables: [
            ReportTable(
              headers: [
                l10n.observedValue,
                'Z',
                l10n.pTwoTail,
                l10n.pGreater,
                l10n.pLess,
              ],
              rows: [
                [
                  formatNum(r.observed),
                  formatNum(r.z),
                  formatP(r.pTwoTail),
                  formatP(r.pGreater),
                  formatP(r.pLess),
                ],
              ],
            ),
            ReportTable(
              caption: l10n.permDistribution,
              headers: [
                l10n.permStatMean,
                l10n.permStatSd,
                l10n.permStatRange,
              ],
              rows: [
                [
                  formatNum(r.meanPermuted),
                  formatNum(r.sdPermuted),
                  '[${formatNum(r.minPermuted)}, ${formatNum(r.maxPermuted)}]',
                ],
              ],
            ),
          ],
          notes: l10n.permRunInfo(
            r.permutations,
            '${r.seed}',
            r.exact ? l10n.permExact : l10n.permRandom,
          ),
        ),
      ],
    );
  }

  /// 协方差分析：类型 III 平方和 + 协变量斜率 + 调整均值（EMM）。
  void _runAncova() {
    if (_yVar == null) throw l10n.pleaseSelectDepVar;
    if (_groupVar == null) throw l10n.pleaseSelectGroup;
    if (_selectedVars.isEmpty) throw l10n.pleaseSelectCovariates;
    final yi = ds.indexOf(_yVar!);
    final ai = ds.indexOf(_groupVar!);
    final bi = _factorB == null ? -1 : ds.indexOf(_factorB!);
    final ci = [for (final n in _selectedVars) ds.indexOf(n)];
    if (yi < 0 || ai < 0 || ci.any((i) => i < 0)) throw l10n.varNotFound;

    final y = <double>[];
    final a = <String>[];
    final bList = <String>[];
    final covs = {for (final n in _selectedVars) n: <double>[]};
    for (final row in ds.cases) {
      // 逐个变量应用「用户缺失值」规则；任一变量缺失即整行剔除（完全案例）
      final yraw = yi < row.length ? row[yi] : null;
      final araw = ai < row.length ? row[ai] : null;
      final braw = bi >= 0 && bi < row.length ? row[bi] : null;
      if (ds.variables[yi].isMissing(yraw) || ds.variables[ai].isMissing(araw)) {
        continue;
      }
      if (bi >= 0 && ds.variables[bi].isMissing(braw)) continue;
      final vals = <double>[];
      var ok = yraw is num;
      if (ok) {
        for (final j in ci) {
          final raw = j < row.length ? row[j] : null;
          if (ds.variables[j].isMissing(raw) || raw is! num) {
            ok = false;
            break;
          }
          vals.add(raw.toDouble());
        }
      }
      if (!ok) continue;
      y.add((yraw as num).toDouble());
      a.add(ds.variables[ai].displayValue(araw));
      bList.add(bi >= 0 ? ds.variables[bi].displayValue(braw) : '—');
      for (var k = 0; k < ci.length; k++) {
        covs[_selectedVars[k]]!.add(vals[k]);
      }
    }
    if (y.isEmpty) throw l10n.noValidData;
    final r = ancova(
      y: y,
      a: a,
      b: bi >= 0 ? bList : null,
      covariates: covs,
      yName: _yVar!,
      aName: _groupVar!,
      bName: _factorB ?? 'B',
    );

    _report = AnalysisReport(
      title: l10n.ancovaTitle,
      subtitle: '${variableLabel(ds, r.yName)} ~ '
          '${r.factorNames.map((n) => variableLabel(ds, n)).join(' * ')}'
          '${r.covariateNames.isEmpty ? '' : ' + ${r.covariateNames.map((n) => variableLabel(ds, n)).join(' + ')}'}',
      sections: [
        ReportSection(
          heading: l10n.typeIiiSs,
          tables: [
            ReportTable(
              headers: [
                l10n.source,
                'SS',
                'df',
                'MS',
                'F',
                'p',
                l10n.partialEta2,
              ],
              rows: [
                for (final t in r.terms)
                  [
                    t.isCovariate
                        ? '${variableLabel(ds, t.name)} (cov)'
                        : variableLabel(ds, t.name),
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
          notes: mergeNotes(
            l10n.ancovaNote(formatNum(r.r2), formatNum(r.adjR2), r.n),
            variableLabelNote(l10n, ds, [
              _yVar!,
              _groupVar!,
              if (_factorB != null && _factorB!.isNotEmpty) _factorB!,
            ]),
          ),
        ),
        ReportSection(
          heading: l10n.covariateSlopes,
          tables: [
            ReportTable(
              headers: [l10n.term, 'B', 'SE', 't', 'p', l10n.ci95],
              rows: [
                for (final s in r.slopes)
                  [
                    variableLabel(ds, s.name),
                    formatNum(s.b),
                    formatNum(s.se),
                    formatNum(s.t),
                    formatP(s.p),
                    '[${formatNum(s.ciLower95)}, ${formatNum(s.ciUpper95)}]',
                  ],
              ],
            ),
          ],
        ),
        ReportSection(
          heading: l10n.adjustedMeans,
          tables: [
            ReportTable(
              headers: [
                l10n.factorWord,
                l10n.group,
                'N',
                l10n.rawMean,
                l10n.adjustedMean,
                'SE',
                l10n.ci95,
              ],
              rows: [
                for (final m in r.means)
                  [
                    m.factor,
                    m.level,
                    '${m.n}',
                    formatNum(m.raw),
                    formatNum(m.adjusted),
                    formatNum(m.se),
                    '[${formatNum(m.ciLower95)}, ${formatNum(m.ciUpper95)}]',
                  ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 多项 logistic 回归（softmax，参考类别 = 最高类别）。
  void _runMultinomial() {
    if (_yVar == null) throw l10n.pleaseSelectDepVar;
    if (_selectedVars.isEmpty) throw l10n.pleaseSelectVars;
    final labels = _orderedLevels(_yVar!);
    if (labels.length < 3) throw l10n.noValidData;
    final vi = ds.indexOf(_yVar!);
    final xi = [for (final n in _selectedVars) ds.indexOf(n)];
    if (vi < 0 || xi.any((i) => i < 0)) throw l10n.varNotFound;
    final code = {for (var i = 0; i < labels.length; i++) labels[i]: i + 1};

    final xs = [for (var j = 0; j < xi.length; j++) <double>[]];
    final y = <int>[];
    for (final row in ds.cases) {
      final yraw = vi < row.length ? row[vi] : null;
      if (ds.variables[vi].isMissing(yraw)) continue;
      final c = code[ds.variables[vi].displayValue(yraw)];
      if (c == null) continue;
      final vals = <double>[];
      var ok = true;
      for (final j in xi) {
        final raw = j < row.length ? row[j] : null;
        if (ds.variables[j].isMissing(raw) || raw is! num) {
          ok = false;
          break;
        }
        vals.add(raw.toDouble());
      }
      if (!ok) continue;
      y.add(c);
      for (var j = 0; j < vals.length; j++) {
        xs[j].add(vals[j]);
      }
    }
    if (y.length < 3) throw l10n.noValidData;
    // 只把实际出现的类别传给显示名（按类别码升序，与库内的类别顺序一致）
    final present = y.toSet().toList()..sort();
    if (present.length < 3) throw l10n.noValidData;
    final display = [
      for (final c in present) labels[c - 1],
    ];
    final r = multinomialLogistic(
      xs,
      y,
      names: _selectedVars,
      levelLabels: display,
    );

    _report = AnalysisReport(
      title: l10n.multinomialTitle,
      subtitle: '${variableLabel(ds, _yVar!)} ~ '
          '${_selectedVars.map((v) => variableLabel(ds, v)).join(' + ')}',
      sections: [
        ReportSection(
          heading: l10n.waldCoefficients,
          tables: [
            ReportTable(
              headers: [l10n.term, 'B', 'SE', 'Wald', 'p', 'OR', 'OR 95%CI'],
              rows: [
                for (final c in r.coefficients)
                  [
                    '${c.level} · ${variableLabel(ds, c.name)}',
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
          notes: mergeNotes(
            l10n.multinomialNote(
              r.reference,
              formatNum(r.pseudoR2),
              r.n,
            ),
            variableLabelNote(l10n, ds, [_yVar!, ..._selectedVars]),
          ),
        ),
        ReportSection(
          heading: l10n.multinomialFit,
          tables: [
            ReportTable(
              headers: [
                l10n.pseudoR2Mcfadden,
                l10n.lrChiSquare,
                'df',
                'p',
                'N',
                l10n.accuracy,
              ],
              rows: [
                [
                  formatNum(r.pseudoR2),
                  formatNum(r.lrChi),
                  '${r.dfModel}',
                  formatP(r.lrP),
                  '${r.n}',
                  '${(r.accuracy * 100).toStringAsFixed(1)}%',
                ],
              ],
            ),
            ReportTable(
              caption: l10n.confusionMatrix,
              headers: [
                l10n.actualClass,
                for (final l in r.levelLabels) '$l (${l10n.predictedClass})',
              ],
              rows: [
                for (var i = 0; i < r.confusion.length; i++)
                  [r.levelLabels[i], for (final v in r.confusion[i]) '$v'],
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _runStepwise() {
    if (_selectedVars.length < 2) throw l10n.pleaseSelectPredictors;
    if (_yVar == null) throw l10n.pleaseSelectDepVar;
    final names = List<String>.from(_selectedVars);
    // 规则 B：完全案例（因变量 + 全部自变量按个案对齐）
    final cols = MissingAware.alignedNumeric(ds, [...names, _yVar!]);
    final r = stepwiseRegression(
      cols.sublist(0, names.length),
      cols.last,
      names: names,
      method: StepwiseMethod.both,
    );
    _report = AnalysisReport(
      title: l10n.stepwiseTitle,
      subtitle: '${variableLabel(ds, _yVar!)} ~ stepwise',
      sections: [
        ReportSection(
          heading: l10n.enteredVars,
          body: r.selected.isEmpty
              ? l10n.noneEntered
              : r.selected.map((v) => variableLabel(ds, v)).join(', '),
          tables: [
            ReportTable(
              headers: [l10n.step, l10n.action, l10n.reportVar, 'R²', l10n.adjR2],
              rows: [
                for (var i = 0; i < r.steps.length; i++)
                  [
                    '${i + 1}',
                    r.steps[i].action == 'enter' ? l10n.enter : l10n.remove,
                    variableLabel(ds, r.steps[i].variable),
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
    // 规则 E：用户缺失值不计入类别（记为缺失）
    final rowKeys = MissingAware.raw(ds, _yVar!);
    final colKeys = MissingAware.raw(ds, _xVar!);
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
      subtitle: '${variableLabel(ds, _yVar!)} × ${variableLabel(ds, _xVar!)}',
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

  /// 按分组变量拆组（规则 D + 规则 A：分组变量或分析变量缺失的个案不入任何组）
  Map<String, List<double>> _splitByGroup(String valueVar, String groupVar) {
    final vi = ds.indexOf(valueVar);
    final gi = ds.indexOf(groupVar);
    if (vi < 0 || gi < 0) throw l10n.varNotFound;
    return MissingAware.groups(ds, valueVar, groupVar);
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




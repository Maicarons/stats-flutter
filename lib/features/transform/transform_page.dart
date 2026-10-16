/// 数据变换 UI（COMPUTE / RECODE / AUTORECODE / COUNT / RANK / SORT / SAMPLE /
/// SELECT / MRSETS / AGGREGATE / FLIP）
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/models/mrset.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/transforms/transforms.dart';
import '../../shared/dataset_store.dart';
import '../../shared/ui/ui.dart';

class TransformPage extends StatefulWidget {
  final dynamic project;
  final bool embedded;
  const TransformPage({super.key, this.project, this.embedded = false});

  @override
  State<TransformPage> createState() => _TransformPageState();
}

class _TransformPageState extends State<TransformPage> {
  String _op = 'compute';
  final _targetCtrl = TextEditingController();
  final _exprCtrl = TextEditingController();
  final _condCtrl = TextEditingController();
  final _matchCtrl = TextEditingController(text: '1');
  final _ntilesCtrl = TextEditingController(text: '4');
  final _arcTargetCtrl = TextEditingController();
  final _fracCtrl = TextEditingController(text: '0.5');
  final _nCtrl = TextEditingController(text: '5');
  final _fromCtrl = TextEditingController(text: '10');
  final _seedCtrl = TextEditingController(text: '20261016');
  bool _sampleByFraction = true;
  _MrMode _mrMode = _MrMode.define;
  MrSetType _mrType = MrSetType.md;
  MrCategorySource _mrCat = MrCategorySource.varLabels;
  final _mrNameCtrl = TextEditingController(text: r'$m');
  final _mrLabelCtrl = TextEditingController();
  final _mrValueCtrl = TextEditingController(text: '1');
  String? _mrSetName;
  String? _mrBy;
  String? _sourceVar;
  String? _groupVar;
  List<String> _selected = [];
  bool _desc = false;
  RankFunction _rankFunction = RankFunction.rank;
  RankTies _rankTies = RankTies.mean;

  /// 执行结果：null 表示未执行；true 成功；false 失败。
  bool? _ok;
  String? _log;

  Dataset get ds => datasetStore.data;

  List<String> get _varNames => ds.variables.map((v) => v.name).toList();

  @override
  void dispose() {
    _targetCtrl.dispose();
    _exprCtrl.dispose();
    _condCtrl.dispose();
    _matchCtrl.dispose();
    _ntilesCtrl.dispose();
    _arcTargetCtrl.dispose();
    _fracCtrl.dispose();
    _nCtrl.dispose();
    _fromCtrl.dispose();
    _seedCtrl.dispose();
    _mrNameCtrl.dispose();
    _mrLabelCtrl.dispose();
    _mrValueCtrl.dispose();
    super.dispose();
  }

  static String _rankFunctionLabel(AppLocalizations l10n, RankFunction f) =>
      switch (f) {
        RankFunction.rank => l10n.trRankFRank,
        RankFunction.n => l10n.trRankFN,
        RankFunction.rFraction => l10n.trRankFRFraction,
        RankFunction.proportion => l10n.trRankFProportion,
        RankFunction.percent => l10n.trRankFPercent,
        RankFunction.normal => l10n.trRankFNormal,
        RankFunction.ntiles => l10n.trRankFNtiles,
      };

  static String _rankTiesLabel(AppLocalizations l10n, RankTies t) =>
      switch (t) {
        RankTies.mean => l10n.trRankTiesMean,
        RankTies.low => l10n.trRankTiesLow,
        RankTies.high => l10n.trRankTiesHigh,
        RankTies.condense => l10n.trRankTiesCondense,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                l10n.trTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: ConstrainedContent(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.x3,
            bottom: AppSpacing.x6,
          ),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trType,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Wrap(
                    spacing: AppSpacing.x2,
                    runSpacing: AppSpacing.x2,
                    children: [
                      for (final op in _ops(l10n))
                        ChoiceChip(
                          avatar: Icon(
                            op.icon,
                            size: 16,
                            color: _op == op.id
                                ? scheme.onSecondaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          label: Text(op.label),
                          selected: _op == op.id,
                          onSelected: (_) => setState(() => _op = op.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  ..._buildParams(l10n, scheme),
                  const SizedBox(height: AppSpacing.x5),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _run,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.trRun),
                    ),
                  ),
                ],
              ),
            ),
            if (_log != null) ...[
              const SizedBox(height: AppSpacing.x3),
              _ResultCard(
                ok: _ok ?? true,
                log: _log!,
                title: l10n.trResult,
              ),
            ],
            const SizedBox(height: AppSpacing.x3),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trCurrentData,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Wrap(
                    spacing: AppSpacing.x2,
                    runSpacing: AppSpacing.x2,
                    children: [
                      StatChip(
                        icon: Icons.dataset_outlined,
                        label: l10n.cases,
                        value: '${ds.nCases}',
                      ),
                      StatChip(
                        icon: Icons.view_column_outlined,
                        label: l10n.variables,
                        value: '${ds.nVars}',
                      ),
                      StatChip(
                        icon: Icons.table_chart_outlined,
                        label: l10n.trDataset,
                        value: ds.name,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    _varNames.join(' · '),
                    style: TextStyle(
                      fontSize: AppFontSize.bodySm,
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Op> _ops(AppLocalizations l10n) => [
        _Op('compute', l10n.trOpCompute, Icons.calculate_outlined),
        _Op('recode', l10n.trOpRecode, Icons.swap_calls),
        _Op('autorecode', l10n.trOpAutorecode, Icons.tag),
        _Op('count', l10n.trOpCount, Icons.numbers),
        _Op('rank', l10n.trOpRank, Icons.format_list_numbered),
        _Op('sort', l10n.trOpSort, Icons.sort),
        _Op('sample', l10n.trOpSample, Icons.percent),
        _Op('mrsets', l10n.trOpMrsets, Icons.checklist),
        _Op('select', l10n.trOpSelect, Icons.filter_alt_outlined),
        _Op('aggregate', l10n.trOpAggregate, Icons.functions),
        _Op('flip', l10n.trOpFlip, Icons.swap_horiz),
      ];

  List<Widget> _buildParams(AppLocalizations l10n, ColorScheme scheme) {
    Widget gap = const SizedBox(height: AppSpacing.x3);
    switch (_op) {
      case 'compute':
        return [
          _dropdown(
            l10n.trTargetVar,
            _targetCtrl.text.isEmpty ? null : _targetCtrl.text,
            [..._varNames, l10n.trNewVar],
            (v) {
              if (v != null && v != l10n.trNewVar) {
                setState(() => _targetCtrl.text = v);
              }
            },
          ),
          gap,
          TextField(
            controller: _targetCtrl,
            decoration: InputDecoration(
              labelText: l10n.trTargetName,
              hintText: l10n.trTargetHint,
            ),
          ),
          gap,
          TextField(
            controller: _exprCtrl,
            decoration: InputDecoration(
              labelText: l10n.trExpr,
              hintText: l10n.trExprHint,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          _hint(l10n.trComputeHelp, scheme),
        ];
      case 'recode':
        return [
          _dropdown(l10n.trSourceVar, _sourceVar, _varNames,
              (v) => setState(() => _sourceVar = v)),
          gap,
          TextField(
            controller: _targetCtrl,
            decoration: InputDecoration(
              labelText: l10n.trTargetName,
              hintText: l10n.trRecodeTargetHint,
            ),
          ),
          gap,
          TextField(
            controller: _exprCtrl,
            decoration: InputDecoration(
              labelText: l10n.trRules,
              hintText: l10n.trRulesHint,
            ),
          ),
        ];
      case 'count':
        return [
          TextField(
            controller: _targetCtrl,
            decoration: InputDecoration(
              labelText: l10n.trTargetName,
              hintText: l10n.trCountTargetHint,
            ),
          ),
          gap,
          _multiSelect(l10n.trCountVars),
          gap,
          TextField(
            controller: _matchCtrl,
            decoration: InputDecoration(labelText: l10n.trMatchValue),
          ),
        ];
      case 'autorecode':
        return [
          _multiSelect(l10n.trAutorecodeVars),
          gap,
          TextField(
            controller: _arcTargetCtrl,
            decoration: InputDecoration(
              labelText: l10n.trAutorecodeTargets,
              hintText: l10n.trAutorecodeTargetHint,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.trAutorecodeDescending),
            value: _desc,
            onChanged: (v) => setState(() => _desc = v),
          ),
          const SizedBox(height: AppSpacing.x2),
          _hint(l10n.trAutorecodeHelp, scheme),
        ];
      case 'rank':
        return [
          _dropdown(l10n.trSourceVar, _sourceVar, _varNames,
              (v) => setState(() => _sourceVar = v)),
          gap,
          _dropdownOf<RankFunction>(
            l10n.trRankFunction,
            _rankFunction,
            RankFunction.values,
            (f) => _rankFunctionLabel(l10n, f),
            (v) {
              if (v != null) setState(() => _rankFunction = v);
            },
          ),
          if (_rankFunction == RankFunction.ntiles) ...[
            gap,
            TextField(
              controller: _ntilesCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.trRankNtiles,
                hintText: '4',
              ),
            ),
          ],
          gap,
          _dropdownOf<RankTies>(
            l10n.trRankTies,
            _rankTies,
            RankTies.values,
            (t) => _rankTiesLabel(l10n, t),
            (v) {
              if (v != null) setState(() => _rankTies = v);
            },
          ),
          const SizedBox(height: AppSpacing.x1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.trRankDescending),
            value: _desc,
            onChanged: (v) => setState(() => _desc = v),
          ),
          const SizedBox(height: AppSpacing.x2),
          _hint(l10n.trRankHelp, scheme),
        ];
      case 'sort':
        return [
          _multiSelect(l10n.trSortKeys),
          const SizedBox(height: AppSpacing.x1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.trSortDescending),
            value: _desc,
            onChanged: (v) => setState(() => _desc = v),
          ),
        ];
      case 'select':
        return [
          TextField(
            controller: _condCtrl,
            decoration: InputDecoration(
              labelText: l10n.trCondition,
              hintText: l10n.trConditionHint,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          _hint(l10n.trConditionHelp, scheme),
        ];
      case 'sample':
        return [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(l10n.trSampleFraction),
                icon: const Icon(Icons.percent),
              ),
              ButtonSegment(
                value: false,
                label: Text(l10n.trSampleNFromN),
                icon: const Icon(Icons.format_list_numbered),
              ),
            ],
            selected: {_sampleByFraction},
            onSelectionChanged: (s) =>
                setState(() => _sampleByFraction = s.first),
          ),
          gap,
          if (_sampleByFraction)
            TextField(
              controller: _fracCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.trSampleFractionLabel,
                hintText: '0.5',
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.trSampleN,
                      hintText: '5',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.trSampleFrom,
                      hintText: '10',
                    ),
                  ),
                ),
              ],
            ),
          gap,
          TextField(
            controller: _seedCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.trSampleSeed,
              hintText: '20261016',
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          _hint(l10n.trSampleHelp, scheme),
        ];
      case 'aggregate':
        return [
          _dropdown(l10n.trGroupVar, _groupVar, _varNames,
              (v) => setState(() => _groupVar = v)),
          gap,
          _multiSelect(l10n.trAggVars),
        ];
      case 'mrsets':
        final setNames = [for (final s in ds.mrSets) s.name];
        return [
          _dropdownOf<_MrMode>(
            l10n.trMrMode,
            _mrMode,
            _MrMode.values,
            (m) => switch (m) {
              _MrMode.define => l10n.trMrDefine,
              _MrMode.delete => l10n.trMrDelete,
              _MrMode.display => l10n.trMrDisplay,
              _MrMode.frequencies => l10n.trMrFrequencies,
              _MrMode.crosstabs => l10n.trMrCrosstabs,
            },
            (m) => setState(() => _mrMode = m ?? _MrMode.define),
          ),
          gap,
          if (_mrMode == _MrMode.define) ...[
            TextField(
              controller: _mrNameCtrl,
              decoration: InputDecoration(
                labelText: l10n.trMrName,
                hintText: r'$m',
              ),
            ),
            gap,
            TextField(
              controller: _mrLabelCtrl,
              decoration: InputDecoration(labelText: l10n.trMrLabel),
            ),
            gap,
            _dropdownOf<MrSetType>(
              l10n.trMrType,
              _mrType,
              MrSetType.values,
              (t) => t == MrSetType.md ? l10n.trMrTypeMd : l10n.trMrTypeMc,
              (t) => setState(() => _mrType = t ?? MrSetType.md),
            ),
            gap,
            _multiSelect(l10n.trMrVars),
            gap,
            if (_mrType == MrSetType.md) ...[
              TextField(
                controller: _mrValueCtrl,
                decoration: InputDecoration(
                  labelText: l10n.trMrValue,
                  hintText: '1',
                ),
              ),
              gap,
              _dropdownOf<MrCategorySource>(
                l10n.trMrCategoryLabels,
                _mrCat,
                MrCategorySource.values,
                (c) => c == MrCategorySource.varLabels
                    ? l10n.trMrCatVarLabels
                    : l10n.trMrCatCounted,
                (c) => setState(() => _mrCat = c ?? MrCategorySource.varLabels),
              ),
            ],
          ] else ...[
            _dropdown(
              l10n.trMrSet,
              _mrSetName,
              [
                if (_mrMode == _MrMode.delete || _mrMode == _MrMode.display)
                  'ALL',
                ...setNames,
              ],
              (v) => setState(() => _mrSetName = v),
            ),
            if (_mrMode == _MrMode.crosstabs) ...[
              gap,
              _dropdown(l10n.trMrBy, _mrBy, _varNames,
                  (v) => setState(() => _mrBy = v)),
            ],
          ],
          const SizedBox(height: AppSpacing.x2),
          _hint(l10n.trMrHelp, scheme),
        ];
      case 'flip':
        return [
          Text(
            l10n.trFlipNote,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
          ),
        ];
    }
    return const [];
  }

  /// MRSETS：定义 / 删除 / 显示定义 / 频数表 / 交叉表
  TransformResult _runMrsets(AppLocalizations l10n) {
    switch (_mrMode) {
      case _MrMode.define:
        if (_selected.length < 2) throw l10n.trMrNeedVars2;
        final s = MRSets.define(
          ds,
          name: _mrNameCtrl.text.trim(),
          type: _mrType,
          variables: List.of(_selected),
          label: _mrLabelCtrl.text.trim(),
          counted: _mrType == MrSetType.md ? _mrCounted() : null,
          categoryLabels: _mrCat,
        );
        return TransformResult(
          message: 'MRSETS /${s.type.verb} ${s.name} defined '
              '(${s.variables.length} variables'
              '${s.type == MrSetType.md ? ', VALUE=${s.counted}' : ''})',
          dataset: ds,
          changed: 0,
        );
      case _MrMode.delete:
        final names = _mrTargets();
        if (names.isEmpty) throw l10n.trMrNeedSet;
        final n = MRSets.delete(ds, names);
        return TransformResult(
          message: 'MRSETS /DELETE removed $n set(s); '
              '${ds.mrSets.length} remaining',
          dataset: ds,
          changed: 0,
        );
      case _MrMode.display:
        return TransformResult(
            message: MRSetsText.display(_mrSetsToShow()),
            dataset: ds,
            changed: 0);
      case _MrMode.frequencies:
        final sets = _mrSetsToShow();
        if (sets.isEmpty) throw l10n.trMrNeedSet;
        return TransformResult(
          message: [
            for (final s in sets)
              MRSetsText.frequencies(MRSets.frequencies(ds, s)),
          ].join('\n\n'),
          dataset: ds,
          changed: 0,
        );
      case _MrMode.crosstabs:
        if (_mrBy == null) throw l10n.trMrNeedBy;
        final sets = _mrSetsToShow();
        if (sets.isEmpty) throw l10n.trMrNeedSet;
        return TransformResult(
          message: [
            for (final s in sets)
              MRSetsText.crosstab(MRSets.crosstab(ds, s, _mrBy!)),
          ].join('\n\n'),
          dataset: ds,
          changed: 0,
        );
    }
  }

  /// 当前选择的多选集（`ALL` 或未选择时返回全部）
  List<MrSet> _mrSetsToShow() {
    final names = _mrTargets();
    if (names.isEmpty) return List.of(ds.mrSets);
    return [
      for (final n in names)
        if (MRSets.lookup(ds, n) != null) MRSets.lookup(ds, n)!,
    ];
  }

  List<String> _mrTargets() {
    final v = _mrSetName;
    if (v == null) return const [];
    if (v == 'ALL') return [for (final s in ds.mrSets) s.name];
    return [v];
  }

  /// MDGROUP 的选中值：成员为数值变量时按数字解析，否则按字符串
  Object _mrCounted() {
    final text = _mrValueCtrl.text.trim();
    final i = _selected.isEmpty ? -1 : ds.indexOf(_selected.first);
    final numeric = i >= 0 && ds.variables[i].type == VarType.numeric;
    return numeric ? (num.tryParse(text) ?? text) : text;
  }

  Widget _hint(String text, ColorScheme scheme) => Text(
        text,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      );

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  /// 枚举下拉：显示用 [label] 本地化，取值是枚举本身。
  Widget _dropdownOf<T>(
    String label,
    T value,
    List<T> values,
    String Function(T) labelOf,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in values)
          DropdownMenuItem(value: v, child: Text(labelOf(v))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _multiSelect(String label) {
    return ParamVarPicker(
      label: label,
      names: _varNames,
      selected: _selected,
      onChanged: (v) => setState(() => _selected = v),
    );
  }

  void _run() {
    final l10n = AppLocalizations.of(context);
    try {
      final TransformResult r;
      switch (_op) {
        case 'compute':
          if (_targetCtrl.text.trim().isEmpty ||
              _exprCtrl.text.trim().isEmpty) {
            throw l10n.trNeedTargetExpr;
          }
          r = Transforms.compute(
            ds,
            targetVar: _targetCtrl.text.trim(),
            expression: _exprCtrl.text.trim(),
          );
          break;
        case 'recode':
          if (_sourceVar == null) throw l10n.trNeedSource;
          final rules = <String, String>{};
          for (final part in _exprCtrl.text.split(',')) {
            final kv = part.split('=');
            if (kv.length == 2) {
              rules[kv[0].trim()] = kv[1].trim();
            }
          }
          r = Transforms.recode(
            ds,
            sourceVar: _sourceVar!,
            targetVar: _targetCtrl.text.trim().isEmpty
                ? 'R_${_sourceVar!}'
                : _targetCtrl.text.trim(),
            rules: rules,
          );
          break;
        case 'count':
          if (_selected.isEmpty) throw l10n.trNeedVars;
          r = Transforms.count(
            ds,
            targetVar: _targetCtrl.text.trim().isEmpty
                ? 'n_match'
                : _targetCtrl.text.trim(),
            sourceVars: _selected,
            matchValue: _matchCtrl.text.trim(),
          );
          break;
        case 'autorecode':
          if (_selected.isEmpty) throw l10n.trNeedVars;
          final targets = _arcTargetCtrl.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (targets.isNotEmpty && targets.length != _selected.length) {
            throw l10n.trAutorecodeCountMismatch;
          }
          r = Transforms.autorecode(
            ds,
            sourceVars: List.of(_selected),
            targetVars: targets.isEmpty ? null : targets,
            descending: _desc,
          );
          break;
        case 'rank':
          if (_sourceVar == null) throw l10n.trNeedSource;
          r = Transforms.rank(
            ds,
            sourceVar: _sourceVar!,
            descending: _desc,
            function: _rankFunction,
            ties: _rankTies,
            ntiles: int.tryParse(_ntilesCtrl.text.trim()) ?? 4,
          );
          break;
        case 'sort':
          if (_selected.isEmpty) throw l10n.trNeedSortKeys;
          r = Transforms.sortCases(ds,
              keys: List.of(_selected), descending: _desc);
          break;
        case 'select':
          if (_condCtrl.text.trim().isEmpty) throw l10n.trNeedCondition;
          r = Transforms.selectIf(ds, condition: _condCtrl.text.trim());
          break;
        case 'sample':
          final seed = int.tryParse(_seedCtrl.text.trim()) ?? 20261016;
          if (_sampleByFraction) {
            final p = double.tryParse(_fracCtrl.text.trim());
            if (p == null || p <= 0 || p >= 1) {
              throw l10n.trSampleNeedInput;
            }
            r = Transforms.sample(ds, fraction: p, seed: seed);
          } else {
            final n = int.tryParse(_nCtrl.text.trim());
            final from = int.tryParse(_fromCtrl.text.trim());
            if (n == null || from == null || n < 1 || from < n + 1) {
              throw l10n.trSampleNeedInput;
            }
            r = Transforms.sample(ds, n: n, from: from, seed: seed);
          }
          break;
        case 'aggregate':
          if (_groupVar == null || _selected.isEmpty) {
            throw l10n.trNeedGroupAndVars;
          }
          r = Transforms.aggregateMean(ds,
              groupVar: _groupVar!, valueVars: List.of(_selected));
          break;
        case 'flip':
          r = Transforms.flip(ds);
          break;
        case 'mrsets':
          r = _runMrsets(l10n);
          break;
        default:
          throw l10n.trUnknownOp;
      }
      datasetStore.replace(r.dataset);
      setState(() {
        _ok = true;
        _log = r.message;
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _log = l10n.trError('$e');
      });
    }
  }
}

class _Op {
  final String id;
  final String label;
  final IconData icon;
  const _Op(this.id, this.label, this.icon);
}

/// MRSETS 面板上的操作
enum _MrMode { define, delete, display, frequencies, crosstabs }

/// 执行结果卡片：成功/失败用语义色 + 图标双重表达。
class _ResultCard extends StatelessWidget {
  final bool ok;
  final String log;
  final String title;

  const _ResultCard({
    required this.ok,
    required this.log,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = context.appColors;
    final color = ok ? app.success : scheme.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.rLg,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_outline : Icons.error_outline,
                size: 18,
                color: color,
              ),
              const SizedBox(width: AppSpacing.x2),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          SelectableText(
            log,
            style: TextStyle(
              fontSize: AppFontSize.bodySm,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

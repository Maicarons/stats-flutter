/// 数据变换 UI（COMPUTE / RECODE / RANK / SORT / SELECT / WEIGHT / AGGREGATE）
library;

import 'package:flutter/material.dart';

import '../../core/models/dataset.dart';
import '../../core/transforms/transforms.dart';
import '../../shared/dataset_store.dart';

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
  String? _sourceVar;
  String? _groupVar;
  final List<String> _selected = [];
  bool _desc = false;
  String? _log;

  Dataset get ds => datasetStore.data;

  List<String> get _varNames => ds.variables.map((v) => v.name).toList();

  @override
  void dispose() {
    _targetCtrl.dispose();
    _exprCtrl.dispose();
    _condCtrl.dispose();
    _matchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('数据变换')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('变换类型',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (id, label) in [
                        ('compute', 'COMPUTE 计算'),
                        ('recode', 'RECODE 重编码'),
                        ('count', 'COUNT 计数'),
                        ('rank', 'RANK 秩次'),
                        ('sort', 'SORT 排序'),
                        ('select', 'SELECT IF 筛选'),
                        ('aggregate', 'AGGREGATE 汇总'),
                        ('flip', 'FLIP 转置'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _op == id,
                          onSelected: (_) => setState(() => _op = id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._buildParams(scheme),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _run,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('执行变换'),
                  ),
                ],
              ),
            ),
          ),
          if (_log != null) ...[
            const SizedBox(height: 12),
            Card(
              color: scheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SelectableText(_log!,
                    style: TextStyle(color: scheme.onTertiaryContainer)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前数据',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    '${ds.name} · ${ds.nCases} 个案 × ${ds.nVars} 变量\n'
                    '变量：${_varNames.join(", ")}',
                    style: TextStyle(color: scheme.outline, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParams(ColorScheme scheme) {
    switch (_op) {
      case 'compute':
        return [
          _dropdown('目标变量', _targetCtrl.text.isEmpty ? null : _targetCtrl.text,
              [..._varNames, '（新建）'], (v) {
            if (v != null && v != '（新建）') _targetCtrl.text = v;
          }),
          const SizedBox(height: 10),
          TextField(
            controller: _targetCtrl,
            decoration: const InputDecoration(
              labelText: '目标变量名',
              hintText: '例如 total_score',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _exprCtrl,
            decoration: const InputDecoration(
              labelText: '表达式',
              hintText: '例如 pre + post 或 sqrt(hours) * 2',
            ),
          ),
          const SizedBox(height: 6),
          Text('支持 + - * / ( ) 与 abs sqrt ln exp log10 sin cos tan round trunc',
              style: TextStyle(fontSize: 11, color: scheme.outline)),
        ];
      case 'recode':
        return [
          _dropdown('源变量', _sourceVar, _varNames,
              (v) => setState(() => _sourceVar = v)),
          const SizedBox(height: 10),
          TextField(
            controller: _targetCtrl,
            decoration: const InputDecoration(
              labelText: '目标变量名',
              hintText: '例如 method_lab',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _exprCtrl,
            decoration: const InputDecoration(
              labelText: '规则（旧值=新值，逗号分隔）',
              hintText: '1=讲授, 2=探究, 3=混合',
            ),
          ),
        ];
      case 'count':
        return [
          TextField(
            controller: _targetCtrl,
            decoration: const InputDecoration(
              labelText: '目标变量名',
              hintText: '例如 n_pass',
            ),
          ),
          const SizedBox(height: 10),
          _multiSelect('参与计数的变量'),
          const SizedBox(height: 10),
          TextField(
            controller: _matchCtrl,
            decoration: const InputDecoration(labelText: '匹配值'),
          ),
        ];
      case 'rank':
        return [
          _dropdown('源变量', _sourceVar, _varNames,
              (v) => setState(() => _sourceVar = v)),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('降序排名'),
            value: _desc,
            onChanged: (v) => setState(() => _desc = v),
          ),
        ];
      case 'sort':
        return [
          _multiSelect('排序键（按顺序）'),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('降序'),
            value: _desc,
            onChanged: (v) => setState(() => _desc = v),
          ),
        ];
      case 'select':
        return [
          TextField(
            controller: _condCtrl,
            decoration: const InputDecoration(
              labelText: '条件表达式',
              hintText: '例如 post >= 70 && method == 2',
            ),
          ),
          const SizedBox(height: 6),
          Text('支持 > < >= <= == != 与 && ||',
              style: TextStyle(fontSize: 11, color: scheme.outline)),
        ];
      case 'aggregate':
        return [
          _dropdown('分组变量', _groupVar, _varNames,
              (v) => setState(() => _groupVar = v)),
          const SizedBox(height: 10),
          _multiSelect('汇总的数值变量（求均值）'),
        ];
      case 'flip':
        return [
          const Text('将行与列互换（转置），生成新数据集。',
              style: TextStyle(color: Colors.grey)),
        ];
    }
    return const [];
  }

  Widget _dropdown(
      String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _multiSelect(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _varNames
              .map((n) => FilterChip(
                    label: Text(n),
                    selected: _selected.contains(n),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selected.add(n);
                      } else {
                        _selected.remove(n);
                      }
                    }),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _run() {
    try {
      final TransformResult r;
      switch (_op) {
        case 'compute':
          if (_targetCtrl.text.trim().isEmpty || _exprCtrl.text.trim().isEmpty) {
            throw '请填写目标变量与表达式';
          }
          r = Transforms.compute(
            ds,
            targetVar: _targetCtrl.text.trim(),
            expression: _exprCtrl.text.trim(),
          );
          break;
        case 'recode':
          if (_sourceVar == null) throw '请选择源变量';
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
          if (_selected.isEmpty) throw '请选择变量';
          r = Transforms.count(
            ds,
            targetVar: _targetCtrl.text.trim().isEmpty
                ? 'n_match'
                : _targetCtrl.text.trim(),
            sourceVars: _selected,
            matchValue: _matchCtrl.text.trim(),
          );
          break;
        case 'rank':
          if (_sourceVar == null) throw '请选择源变量';
          r = Transforms.rank(ds,
              sourceVar: _sourceVar!, descending: _desc);
          break;
        case 'sort':
          if (_selected.isEmpty) throw '请选择排序键';
          r = Transforms.sortCases(ds,
              keys: List.of(_selected), descending: _desc);
          break;
        case 'select':
          if (_condCtrl.text.trim().isEmpty) throw '请填写条件';
          r = Transforms.selectIf(ds, condition: _condCtrl.text.trim());
          break;
        case 'aggregate':
          if (_groupVar == null || _selected.isEmpty) {
            throw '请选择分组变量与汇总变量';
          }
          r = Transforms.aggregateMean(ds,
              groupVar: _groupVar!, valueVars: List.of(_selected));
          break;
        case 'flip':
          r = Transforms.flip(ds);
          break;
        default:
          throw '未知操作';
      }
      datasetStore.replace(r.dataset);
      setState(() => _log = r.message);
    } catch (e) {
      setState(() => _log = '错误：$e');
    }
  }
}

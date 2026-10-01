import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';
import '../syntax/syntax_editor_page.dart';
import '../transform/transform_page.dart';
import 'csv_io.dart';
import 'sav_import.dart';
import 'editable_data_grid.dart';
import 'missing_values_dialog.dart';
import 'value_labels_dialog.dart';

class DataEditorPage extends StatefulWidget {
  /// true：作为工作区 Tab，不画外层 AppBar
  final bool embedded;
  const DataEditorPage({super.key, this.embedded = true});

  @override
  State<DataEditorPage> createState() => _DataEditorPageState();
}

class _DataEditorPageState extends State<DataEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _search = TextEditingController();
  bool _showValueLabels = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    datasetStore.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    datasetStore.removeListener(_onStore);
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  Dataset get ds => datasetStore.data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final tabs = TabBar(
      controller: _tab,
      tabs: [
        Tab(text: l10n.dataView),
        Tab(text: l10n.variableView),
      ],
    );

    final column = Column(
      children: [
        if (widget.embedded) tabs,
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _StatChip(
                label: l10n.cases,
                value: '${ds.nCases}',
                color: scheme.primaryContainer,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: l10n.variables,
                value: '${ds.nVars}',
                color: scheme.tertiaryContainer,
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.undo,
                onPressed:
                    datasetStore.canUndo ? () => datasetStore.undo() : null,
                icon: const Icon(Icons.undo, size: 20),
              ),
              IconButton(
                tooltip: l10n.redo,
                onPressed:
                    datasetStore.canRedo ? () => datasetStore.redo() : null,
                icon: const Icon(Icons.redo, size: 20),
              ),
              IconButton(
                tooltip: l10n.showValueLabels,
                onPressed: () =>
                    setState(() => _showValueLabels = !_showValueLabels),
                icon: Icon(
                  _showValueLabels ? Icons.label : Icons.label_off,
                  size: 20,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _onMenu(v, l10n),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'demo', child: Text(l10n.loadDemo)),
                  PopupMenuItem(
                      value: 'addvar', child: Text(l10n.addVariable)),
                  PopupMenuItem(value: 'addcase', child: Text(l10n.addCase)),
                  PopupMenuItem(
                      value: 'transform', child: Text(l10n.transformMenu)),
                  PopupMenuItem(
                      value: 'syntax', child: Text(l10n.syntaxEditor)),
                  PopupMenuItem(value: 'weight', child: Text(l10n.weightCases)),
                  PopupMenuItem(value: 'split', child: Text(l10n.splitFile)),
                  PopupMenuItem(value: 'find', child: Text(l10n.findCase)),
                ],
              ),
            ],
          ),
        ),
        // 显式导入导出工具条
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onMenu('import', l10n),
                  icon: const Icon(Icons.file_open, size: 18),
                  label: Text(l10n.importData),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onMenu('import_sav', l10n),
                  icon: const Icon(Icons.table_rows, size: 18),
                  label: const Text('SAV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _onMenu('export', l10n),
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: Text(l10n.exportData),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              EditableDataGrid(
                showValueLabels: _showValueLabels,
                filter: _search.text,
              ),
              _VarSheet(filter: _search.text),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(ds.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              bottom: tabs,
            ),
      body: column,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCase(l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCase),
      ),
    );
  }

  Future<void> _onMenu(String v, AppLocalizations l10n) async {
    switch (v) {
      case 'demo':
        datasetStore.resetDemo();
        break;
      case 'import':
        await importCsvInteractive(context, l10n, excelToo: true);
        break;
      case 'import_sav':
        await importSavInteractive(context);
        break;
      case 'export':
        await exportCsvInteractive(context, l10n);
        break;
      case 'addvar':
        _addVar(l10n);
        break;
      case 'addcase':
        _addCase(l10n);
        break;
      case 'syntax':
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SyntaxEditorPage()),
          );
        }
        break;
      case 'transform':
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransformPage()),
          );
        }
        break;
      case 'weight':
        await _pickWeight(l10n);
        break;
      case 'split':
        await _pickSplit(l10n);
        break;
      case 'find':
        await _findCase(l10n);
        break;
    }
  }

  void _addCase(AppLocalizations l10n) {
    datasetStore.history.checkpoint(ds);
    ds.addCase();
    datasetStore.touch();
  }

  void _addVar(AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: 'V${ds.nVars + 1}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addVariable),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l10n.variableName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              datasetStore.history.checkpoint(ds);
              ds.addVariable(Variable(name: nameCtrl.text.trim()));
              datasetStore.touch();
              Navigator.pop(ctx);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWeight(AppLocalizations l10n) async {
    final names = ds.variables.map((v) => v.name).toList();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('WEIGHT CASES'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l10n.notWeighted),
          ),
          for (final n in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text(n),
            ),
        ],
      ),
    );
    if (v == null) return;
    ds.weightVariable = v.isEmpty ? null : v;
    datasetStore.touch();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                v.isEmpty ? l10n.weightOff : l10n.weightedBy(v))),
      );
    }
  }

  Future<void> _pickSplit(AppLocalizations l10n) async {
    final names = ds.variables.map((v) => v.name).toList();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('SPLIT FILE'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l10n.noSplit),
          ),
          for (final n in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text(n),
            ),
        ],
      ),
    );
    if (v == null) return;
    ds.splitVariable = v.isEmpty ? null : v;
    datasetStore.touch();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(v.isEmpty ? l10n.splitOff : l10n.splitBy(v))),
      );
    }
  }

  Future<void> _findCase(AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    final q = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.find),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.findHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l10n.find),
          ),
        ],
      ),
    );
    if (q == null || q.trim().isEmpty) return;
    final key = q.trim().toLowerCase();
    final hits = <int>[];
    for (var i = 0; i < ds.nCases; i++) {
      final hay = ds.cases[i].map((e) => e?.toString() ?? '').join(' ');
      if (hay.toLowerCase().contains(key)) hits.add(i + 1);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hits.isEmpty
              ? l10n.notFound(q)
              : l10n.foundN(
                  hits.length,
                  hits.take(12).join(', '),
                  hits.length > 12 ? '…' : '',
                ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label $value',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _VarSheet extends StatelessWidget {
  final String filter;
  const _VarSheet({required this.filter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = datasetStore.data;
    final vars = ds.variables
        .where((v) =>
            filter.isEmpty ||
            v.name.toLowerCase().contains(filter.toLowerCase()) ||
            v.label.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: vars.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final v = vars[i];
        return Card(
          child: ExpansionTile(
            shape: const Border(),
            title: Text(v.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${v.type.zh} · ${v.measure.zh} · ${l10n.decimals} ${v.decimals}'
              '${v.label.isEmpty ? '' : ' · ${v.label}'}',
              style: const TextStyle(fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: v.label,
                            decoration:
                                InputDecoration(labelText: l10n.label),
                            onChanged: (s) {
                              v.label = s;
                              datasetStore.touch();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<MeasureLevel>(
                            initialValue: v.measure,
                            decoration:
                                InputDecoration(labelText: l10n.measure),
                            items: MeasureLevel.values
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m.zh),
                                    ))
                                .toList(),
                            onChanged: (m) {
                              if (m != null) {
                                v.measure = m;
                                datasetStore.touch();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<VarType>(
                            initialValue: v.type,
                            decoration:
                                InputDecoration(labelText: l10n.type),
                            items: VarType.values
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.zh),
                                    ))
                                .toList(),
                            onChanged: (t) {
                              if (t != null) {
                                v.type = t;
                                datasetStore.touch();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: '${v.decimals}',
                            decoration:
                                InputDecoration(labelText: l10n.decimals),
                            keyboardType: TextInputType.number,
                            onChanged: (s) {
                              v.decimals = int.tryParse(s) ?? 2;
                              datasetStore.touch();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.valueLabels,
                          style:
                              Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (v.valueLabels.isEmpty)
                            Text(l10n.noValueLabels,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline))
                          else
                            ...v.valueLabels.entries.map((e) => Chip(
                                  label: Text('${e.key} = ${e.value}'),
                                  visualDensity: VisualDensity.compact,
                                  onDeleted: () {
                                    v.valueLabels.remove(e.key);
                                    datasetStore.touch();
                                  },
                                )),
                          ActionChip(
                            avatar: const Icon(Icons.edit, size: 16),
                            label: Text(l10n.editValueLabels),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => ValueLabelsDialog(variable: v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.block, size: 16),
                            label: Text(l10n.missingValues),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  MissingValuesDialog(variable: v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: Text(l10n.deleteVariable),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              final idx = ds.indexOf(v.name);
                              if (idx >= 0) {
                                datasetStore.history.checkpoint(ds);
                                ds.removeVariable(idx);
                                datasetStore.touch();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

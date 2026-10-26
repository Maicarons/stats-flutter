import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';
import '../../shared/locale_util.dart';
import '../../shared/ui/ui.dart';
import '../syntax/syntax_editor_page.dart';
import '../transform/transform_page.dart';
import 'csv_io.dart';
import 'sav_import.dart';
import 'editable_data_grid.dart';
import 'missing_values_dialog.dart';
import 'value_labels_dialog.dart';

/// 依当前语言取枚举的本地化名称。
String _localeName(BuildContext context, String en, String zh) =>
    Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

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

    final body = Column(
      children: [
        if (widget.embedded) tabs,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x2,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.cancel,
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
              const SizedBox(width: AppSpacing.x1),
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
                isSelected: _showValueLabels,
                onPressed: () =>
                    setState(() => _showValueLabels = !_showValueLabels),
                icon: Icon(
                  _showValueLabels ? Icons.label : Icons.label_off,
                  size: 20,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.more,
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
        // 导入 / 导出
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onMenu('import', l10n),
                  icon: const Icon(Icons.file_open, size: 18),
                  label: Text(l10n.importData),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onMenu('import_sav', l10n),
                  icon: const Icon(Icons.table_rows, size: 18),
                  label: const Text('SAV'),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickExport(l10n),
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: Text(l10n.exportData),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x2),
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
              title: Text(
                ds.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              bottom: tabs,
            ),
      body: widget.embedded
          ? body
          : ConstrainedContent(child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCase,
        icon: const Icon(Icons.add),
        label: Text(l10n.addCase),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
    );
  }

  /// 导出格式选择：CSV 或 SPSS 系统文件（.sav）。
  Future<void> _pickExport(AppLocalizations l10n) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(l10n.exportCsv),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.table_rows),
              title: Text(l10n.exportSav),
              onTap: () => Navigator.pop(ctx, 'sav'),
            ),
            ListTile(
              leading: const Icon(Icons.stairs),
              title: Text(l10n.importDta),
              onTap: () => Navigator.pop(ctx, 'dta'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'csv') {
      await exportCsvInteractive(context, l10n);
    } else if (choice == 'sav') {
      await exportSavInteractive(context, l10n);
    }
  }

  Future<void> _onMenu(String v, AppLocalizations l10n) async {
    switch (v) {
      case 'demo':
        datasetStore.resetDemo(zh: isZhUi(context));
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
      case 'export_sav':
        await exportSavInteractive(context, l10n);
        break;
      case 'addvar':
        _addVar(l10n);
        break;
      case 'addcase':
        _addCase();
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

  void _addCase() {
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
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.variableName),
          onSubmitted: (_) => Navigator.pop(ctx),
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
        title: Text(l10n.weightCases),
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
        title: Text(l10n.splitFile),
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
          onSubmitted: (s) => Navigator.pop(ctx, s),
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

/// 变量视图：每个变量一张卡片，展开后编辑标签/尺度/类型/值标签/缺失值。
class _VarSheet extends StatelessWidget {
  final String filter;
  const _VarSheet({required this.filter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ds = datasetStore.data;
    final q = filter.toLowerCase();
    final vars = ds.variables
        .where((v) =>
            filter.isEmpty ||
            v.name.toLowerCase().contains(q) ||
            v.label.toLowerCase().contains(q))
        .toList();

    if (vars.isEmpty) {
      return EmptyState(
        icon: Icons.view_column_outlined,
        title: l10n.noVariablesMatch,
        message: l10n.searchHint,
        compact: true,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        AppSpacing.x7,
      ),
      itemCount: vars.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
      itemBuilder: (context, i) {
        final v = vars[i];
        final typeName = _localeName(context, v.type.en, v.type.zh);
        final measureName = _localeName(context, v.measure.en, v.measure.zh);
        return AppCard(
          // 稳定 key：搜索过滤 / 删除变量后，展开状态跟着变量走
          key: ValueKey('var-${v.name}'),
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    v.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: AppRadius.rSm,
                  ),
                  child: Text(
                    v.isNumeric ? '#' : 'A',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '$typeName · $measureName · ${l10n.decimals} ${v.decimals}'
              '${v.label.isEmpty ? '' : ' · ${v.label}'}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              0,
              AppSpacing.x4,
              AppSpacing.x3,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: v.label,
                      decoration: InputDecoration(labelText: l10n.label),
                      onChanged: (s) {
                        v.label = s;
                        datasetStore.touch();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: DropdownButtonFormField<MeasureLevel>(
                      initialValue: v.measure,
                      decoration: InputDecoration(labelText: l10n.measure),
                      items: MeasureLevel.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                    _localeName(context, m.en, m.zh)),
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
              const SizedBox(height: AppSpacing.x2),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<VarType>(
                      initialValue: v.type,
                      decoration: InputDecoration(labelText: l10n.type),
                      items: VarType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                    _localeName(context, t.en, t.zh)),
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
                  const SizedBox(width: AppSpacing.x2),
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
              const SizedBox(height: AppSpacing.x3),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.valueLabels,
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: AppSpacing.x1),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.x1,
                  runSpacing: AppSpacing.x1,
                  children: [
                    if (v.valueLabels.isEmpty)
                      Text(
                        l10n.noValueLabels,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...v.valueLabels.entries.map((e) => Chip(
                            label: Text('${e.key} = ${e.value}'),
                            visualDensity: VisualDensity.compact,
                            deleteButtonTooltipMessage: l10n.delete,
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
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.block, size: 16),
                      label: Text(l10n.missingValues),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => MissingValuesDialog(variable: v),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(l10n.deleteVariable),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
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
        );
      },
    );
  }
}

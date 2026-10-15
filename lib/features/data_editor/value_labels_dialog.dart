/// 值标签编辑器：增 / 删 / 改
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';

class ValueLabelsDialog extends StatefulWidget {
  final Variable variable;
  const ValueLabelsDialog({super.key, required this.variable});

  @override
  State<ValueLabelsDialog> createState() => _ValueLabelsDialogState();
}

class _ValueLabelsDialogState extends State<ValueLabelsDialog> {
  late Map<num, String> _labels;
  final _valCtrl = TextEditingController();
  final _labCtrl = TextEditingController();
  num? _editKey;

  Variable get v => widget.variable;

  @override
  void initState() {
    super.initState();
    _labels = Map.of(v.valueLabels);
  }

  @override
  void dispose() {
    _valCtrl.dispose();
    _labCtrl.dispose();
    super.dispose();
  }

  void _addOrUpdate() {
    final val = num.tryParse(_valCtrl.text.trim());
    final lab = _labCtrl.text.trim();
    if (val == null || lab.isEmpty) return;
    setState(() {
      _labels[val] = lab;
      _valCtrl.clear();
      _labCtrl.clear();
      _editKey = null;
    });
  }

  void _startEdit(num key) {
    setState(() {
      _editKey = key;
      _valCtrl.text = key.toString();
      _labCtrl.text = _labels[key] ?? '';
    });
  }

  void _remove(num key) {
    setState(() {
      _labels.remove(key);
      if (_editKey == key) {
        _editKey = null;
        _valCtrl.clear();
        _labCtrl.clear();
      }
    });
  }

  void _clearAll() {
    setState(() {
      _labels.clear();
      _editKey = null;
      _valCtrl.clear();
      _labCtrl.clear();
    });
  }

  void _save() {
    v.valueLabels
      ..clear()
      ..addAll(_labels);
    datasetStore.touch();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final entries = _labels.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return AlertDialog(
      title: Text(l10n.vlTitle(v.name)),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            // 输入区
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _valCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.value,
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: TextField(
                    controller: _labCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.label,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addOrUpdate(),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                IconButton.filled(
                  onPressed: _addOrUpdate,
                  icon: Icon(_editKey == null ? Icons.add : Icons.check),
                  tooltip: _editKey == null ? l10n.add : l10n.update,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2 + 2),
            Row(
              children: [
                Text(
                  l10n.vlCount(_labels.length),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: AppFontSize.label,
                  ),
                ),
                const Spacer(),
                if (_labels.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(l10n.vlClearAll),
                  ),
              ],
            ),
            const Divider(height: 12),
            // 列表
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        l10n.vlEmptyHint,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final isEditing = _editKey == e.key;
                        return ListTile(
                          dense: true,
                          selected: isEditing,
                          leading: Container(
                            width: 48,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: AppRadius.rSm,
                            ),
                            child: Text(
                              '${e.key}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: AppFontSize.label,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          title: Text(e.value),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: l10n.edit,
                                onPressed: () => _startEdit(e.key),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    size: 18, color: scheme.error),
                                tooltip: l10n.delete,
                                onPressed: () => _remove(e.key),
                              ),
                            ],
                          ),
                          onTap: () => _startEdit(e.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

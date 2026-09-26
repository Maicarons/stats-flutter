/// 值标签编辑器：增 / 删 / 改
library;

import 'package:flutter/material.dart';

import '../../core/models/dataset.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final entries = _labels.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return AlertDialog(
      title: Text('值标签 · ${v.name}'),
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
                    decoration: const InputDecoration(
                      labelText: '值',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _labCtrl,
                    decoration: const InputDecoration(
                      labelText: '标签',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addOrUpdate(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addOrUpdate,
                  icon: Icon(_editKey == null ? Icons.add : Icons.check),
                  tooltip: _editKey == null ? '添加' : '更新',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('共 ${_labels.length} 条',
                    style: TextStyle(color: scheme.outline, fontSize: 12)),
                const Spacer(),
                if (_labels.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('清空全部'),
                  ),
              ],
            ),
            const Divider(height: 12),
            // 列表
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text('暂无值标签，先在上方添加',
                          style: TextStyle(color: scheme.outline)),
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
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${e.key}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          title: Text(e.value),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: '编辑',
                                onPressed: () => _startEdit(e.key),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    size: 18, color: scheme.error),
                                tooltip: '删除',
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

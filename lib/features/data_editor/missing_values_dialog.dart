/// 缺失值编辑对话框
library;

import 'package:flutter/material.dart';

import '../../core/models/dataset.dart';
import '../../shared/dataset_store.dart';

class MissingValuesDialog extends StatefulWidget {
  final Variable variable;
  const MissingValuesDialog({super.key, required this.variable});

  @override
  State<MissingValuesDialog> createState() => _MissingValuesDialogState();
}

class _MissingValuesDialogState extends State<MissingValuesDialog> {
  final _discrete = TextEditingController();
  final _rangeLow = TextEditingController();
  final _rangeHigh = TextEditingController();

  Variable get v => widget.variable;

  @override
  void initState() {
    super.initState();
    _discrete.text = v.missingValues.map((e) => e.toString()).join(', ');
    _rangeLow.text = v.missingRangeLow?.toString() ?? '';
    _rangeHigh.text = v.missingRangeHigh?.toString() ?? '';
  }

  @override
  void dispose() {
    _discrete.dispose();
    _rangeLow.dispose();
    _rangeHigh.dispose();
    super.dispose();
  }

  void _save() {
    v.missingValues
      ..clear()
      ..addAll(_discrete.text
          .split(',')
          .map((e) => num.tryParse(e.trim()))
          .whereType<num>());
    v.missingRangeLow = num.tryParse(_rangeLow.text.trim());
    v.missingRangeHigh = num.tryParse(_rangeHigh.text.trim());
    datasetStore.touch();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('缺失值 · ${v.name}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _discrete,
              decoration: const InputDecoration(
                labelText: '离散缺失值（逗号分隔）',
                hintText: '例如 -99, -98',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rangeLow,
                    decoration:
                        const InputDecoration(labelText: '范围下限（可选）'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rangeHigh,
                    decoration:
                        const InputDecoration(labelText: '范围上限（可选）'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '空白单元格始终视为缺失。范围与离散值可同时使用。',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            v.missingValues.clear();
            v.missingRangeLow = null;
            v.missingRangeHigh = null;
            datasetStore.touch();
            Navigator.pop(context, true);
          },
          child: const Text('清除'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

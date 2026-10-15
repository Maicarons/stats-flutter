/// 缺失值编辑对话框
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
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

  void _clear() {
    v.missingValues.clear();
    v.missingRangeLow = null;
    v.missingRangeHigh = null;
    datasetStore.touch();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.mvTitle(v.name)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _discrete,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.mvDiscrete,
                hintText: l10n.mvDiscreteHint,
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rangeLow,
                    decoration: InputDecoration(labelText: l10n.mvRangeLow),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: TextField(
                    controller: _rangeHigh,
                    decoration: InputDecoration(labelText: l10n.mvRangeHigh),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2 + 2),
            Text(
              l10n.mvNote,
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _clear, child: Text(l10n.clear)),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

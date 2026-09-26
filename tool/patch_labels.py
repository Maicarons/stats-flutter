from pathlib import Path

# 1) Default showValueLabels = false
p = Path(r"F:\workspace\stats-flutter\lib\features\data_editor\data_editor_page.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("bool _showValueLabels = true;", "bool _showValueLabels = false;")
if "value_labels_dialog" not in t:
    t = t.replace(
        "import 'editable_data_grid.dart';",
        "import 'editable_data_grid.dart';\nimport 'missing_values_dialog.dart';\nimport 'value_labels_dialog.dart';",
    )
p.write_text(t, encoding="utf-8")
print("data_editor default labels off")

# 2) Enhance variable sheet with value labels / missing / delete buttons
# We'll rewrite the VarSheet tile actions via patching ExpansionTile children
old_actions = """                    if (v.valueLabels.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l10n.valueLabels,
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: v.valueLabels.entries
                            .map((e) => Chip(
                                  label: Text('${e.key} → ${e.value}'),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],"""

new_actions = """                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.valueLabels,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (v.valueLabels.isEmpty)
                            Text('尚未定义值标签',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.outline))
                          else
                            ...v.valueLabels.entries.map((e) => Chip(
                                  label: Text('\${e.key} = \${e.value}'),
                                  visualDensity: VisualDensity.compact,
                                  onDeleted: () {
                                    v.valueLabels.remove(e.key);
                                    datasetStore.touch();
                                  },
                                )),
                          ActionChip(
                            avatar: const Icon(Icons.edit, size: 16),
                            label: const Text('编辑值标签'),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  ValueLabelsDialog(variable: v),
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
                            label: const Text('缺失值'),
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
                            label: const Text('删除变量'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              final idx = ds.indexOf(v.name);
                              if (idx >= 0) {
                                ds.removeVariable(idx);
                                datasetStore.touch();
                              }
                            },
                          ),
                        ),
                      ],
                    ],"""

t = p.read_text(encoding="utf-8")
if old_actions in t:
    t = t.replace(old_actions, new_actions)
    p.write_text(t, encoding="utf-8")
    print("var sheet enhanced")
else:
    print("WARN: var sheet anchor not found")

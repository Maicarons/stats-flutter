/// 报告里的变量标签 / 值标签（v1.5.0 M4.3）。
///
/// 规则：报告表里的变量优先显示 `Variable.label`（标签），没有标签时回落变量名；
/// 变量名与标签不一致时，注释给出一一对应关系，避免读者对不上号。
/// 屏幕 / HTML / Markdown / PDF 四种输出渲染同一份报告模型，因此一处生效即四处生效。
library;

import '../../core/models/dataset.dart';
import '../../l10n/app_localizations.dart';

/// 变量显示名：有标签用标签，否则用变量名（变量不存在时原样返回）。
String variableLabel(Dataset ds, String name) {
  final i = ds.indexOf(name);
  if (i < 0) return name;
  final label = ds.variables[i].label.trim();
  return label.isEmpty ? name : label;
}

/// 变量 → 标签的映射（喂给 `reportDescriptives` / `reportCorrelation` 的 `labels`）。
Map<String, String> variableLabels(Dataset ds, Iterable<String> names) => {
      for (final n in names)
        if (variableLabel(ds, n) != n) n: variableLabel(ds, n),
    };

/// 值标签（直接喂给 statkit 的 `Frequencies.compute`；变量不存在时为空）。
Map<num, String> valueLabelsOf(Dataset ds, String name) {
  final i = ds.indexOf(name);
  return i < 0 ? const <num, String>{} : ds.variables[i].valueLabels;
}

/// 「标签 = 变量名」对应关系注释；没有带标签的变量时返回 null。
String? variableLabelNote(
  AppLocalizations l10n,
  Dataset ds,
  Iterable<String> names,
) {
  final pairs = <String>[];
  for (final n in names) {
    final l = variableLabel(ds, n);
    if (l != n) pairs.add('$l = $n');
  }
  if (pairs.isEmpty) return null;
  // 分隔符随界面语言：中文用全角逗号，英文用半角（英文界面出现「，」很怪）
  final sep = l10n.localeName.startsWith('zh') ? '，' : ', ';
  return l10n.variableLabelNote(pairs.join(sep));
}

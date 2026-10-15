/// 变量选择器：可搜索、可分组、单选/多选，替代平铺 FilterChip。
library;

import 'package:flutter/material.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/theme/design_tokens.dart';

class ParamVarPicker extends StatefulWidget {
  final String label;
  final List<String> names;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool single;
  final int? max;
  final bool enabled;

  /// 可选分组：返回分组名（同组变量聚合显示）。
  final String? Function(String name)? groupOf;

  /// 分组顺序（可选）。
  final List<String>? groupOrder;

  const ParamVarPicker({
    super.key,
    required this.label,
    required this.names,
    required this.selected,
    required this.onChanged,
    this.single = false,
    this.max,
    this.enabled = true,
    this.groupOf,
    this.groupOrder,
  });

  @override
  State<ParamVarPicker> createState() => _ParamVarPickerState();
}

class _ParamVarPickerState extends State<ParamVarPicker> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String n, bool on) {
    final list = List<String>.from(widget.selected);
    if (widget.single || widget.max == 1) {
      if (on) {
        list
          ..clear()
          ..add(n);
      } else {
        list.remove(n);
      }
    } else if (on) {
      if (!list.contains(n)) list.add(n);
      if (widget.max != null && list.length > widget.max!) {
        list.removeRange(0, list.length - widget.max!);
      }
    } else {
      list.remove(n);
    }
    widget.onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final query = _q.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.names
        : widget.names.where((n) => n.toLowerCase().contains(query)).toList();

    // 分组
    final groups = <String, List<String>>{};
    for (final n in filtered) {
      final g = widget.groupOf?.call(n) ?? '';
      groups.putIfAbsent(g, () => []).add(n);
    }
    final orderedKeys = <String>[
      if (groups.containsKey('')) '',
      ...?widget.groupOrder?.where(groups.containsKey),
      ...groups.keys.where(
        (k) => k != '' && !(widget.groupOrder?.contains(k) ?? false),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: text.labelLarge),
            const SizedBox(width: AppSpacing.x2),
            if (widget.selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.selected.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            const Spacer(),
            if (widget.selected.isNotEmpty && widget.enabled)
              TextButton.icon(
                onPressed: () => widget.onChanged(const []),
                icon: const Icon(Icons.close, size: 15),
                label: Text(l10n.clearSelection),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
                ),
              ),
          ],
        ),
        if (widget.names.length > 6) ...[
          const SizedBox(height: AppSpacing.x2),
          TextField(
            controller: _search,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: l10n.searchVariables,
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x2,
                vertical: AppSpacing.x2,
              ),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _search.clear();
                        setState(() => _q = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ],
        const SizedBox(height: AppSpacing.x3),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
            child: Text(
              l10n.noVariablesMatch,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final key in orderedKeys)
            if (key.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.x1,
                  bottom: AppSpacing.x2,
                ),
                child: Text(
                  key,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              _chips(context, groups[key]!),
              const SizedBox(height: AppSpacing.x2),
            ] else
              _chips(context, groups[key]!),
      ],
    );
  }

  Widget _chips(BuildContext context, List<String> items) {
    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final n in items)
          FilterChip(
            label: Text(n),
            selected: widget.selected.contains(n),
            onSelected:
                widget.enabled ? (v) => _toggle(n, v) : null,
            showCheckmark: false,
            avatar: widget.selected.contains(n)
                ? const Icon(Icons.check, size: 15)
                : null,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

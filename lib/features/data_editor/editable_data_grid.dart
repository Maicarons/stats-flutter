/// 可编辑数据表格：吸顶表头、斑马纹、悬停高亮、双击编辑、键盘导航、撤销/重做。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';

class EditableDataGrid extends StatefulWidget {
  final bool showValueLabels;
  final String filter;

  const EditableDataGrid({
    super.key,
    this.showValueLabels = true,
    this.filter = '',
  });

  @override
  State<EditableDataGrid> createState() => _EditableDataGridState();
}

class _EditableDataGridState extends State<EditableDataGrid> {
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();

  /// 正在编辑 (row, col)；null 表示未编辑
  (int, int)? _editing;
  final _editCtrl = TextEditingController();
  final _editFocus = FocusNode(debugLabel: 'cellEdit');
  final _gridFocus = FocusNode(debugLabel: 'gridKeys');
  FocusNode? _keyNode;

  /// 编辑前的原始值快照（用于取消）
  Object? _snapshot;

  /// 鼠标悬停行（桌面端高亮）
  int? _hoverRow;

  static const double _rowH = 34;
  static const double _headH = 46;
  static const double _rowNumW = 48;
  static const double _minColW = 72;

  Dataset get ds => datasetStore.data;

  @override
  void initState() {
    super.initState();
    datasetStore.addListener(_onStore);
    _editFocus.addListener(_onEditFocus);
  }

  void _onStore() {
    if (!mounted) return;
    final loc = _editing;
    if (loc != null) {
      if (loc.$1 >= ds.nCases || loc.$2 >= ds.nVars) {
        _abortEdit();
      }
    }
    setState(() {});
  }

  void _onEditFocus() {
    // 仅在失焦且仍处于编辑态时提交，避免 rebuild 误清数据
    if (!_editFocus.hasFocus && _editing != null) {
      Future.microtask(() {
        if (_editing != null && !_editFocus.hasFocus) {
          _commitEdit();
        }
      });
    }
  }

  @override
  void dispose() {
    datasetStore.removeListener(_onStore);
    _hCtrl.dispose();
    _vCtrl.dispose();
    _editCtrl.dispose();
    _editFocus.dispose();
    _gridFocus.dispose();
    _keyNode?.dispose();
    super.dispose();
  }

  /// 自适应：窄屏等分填满，宽屏按内容宽度
  List<double> _colWidths(double available) {
    final n = ds.nVars;
    if (n == 0) return const [];
    final byContent = List.generate(n, (i) {
      final v = ds.variables[i];
      final nameW = v.name.length * 8.0 + 34;
      final labelW = v.label.isEmpty ? 0 : v.label.length * 6.0;
      return (nameW + labelW).clamp(_minColW, 200.0);
    });
    final contentSum = byContent.fold<double>(0, (a, b) => a + b);
    final availForCols = (available - _rowNumW).clamp(0.0, double.infinity);
    if (contentSum < availForCols) {
      final extra = (availForCols - contentSum) / n;
      return [for (final w in byContent) w + extra];
    }
    return byContent;
  }

  void _startEdit(int r, int c) {
    if (r < 0 || r >= ds.nCases || c < 0 || c >= ds.nVars) return;
    if (_editing != null) _commitEdit();

    final row = ds.cases[r];
    final raw = c < row.length ? row[c] : null;
    _snapshot = raw;
    _editing = (r, c);
    _editCtrl.text = raw?.toString() ?? '';
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editing != (r, c)) return;
      _editFocus.requestFocus();
      _editCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editCtrl.text.length,
      );
    });
  }

  void _abortEdit() {
    final loc = _editing;
    if (loc != null) {
      final row = ds.cases[loc.$1];
      while (row.length <= loc.$2) {
        row.add(null);
      }
      row[loc.$2] = _snapshot;
    }
    _editing = null;
    _editCtrl.clear();
    _snapshot = null;
    _gridFocus.requestFocus();
    if (mounted) setState(() {});
  }

  void _commitEdit() {
    final loc = _editing;
    if (loc == null) return;
    final (r, c) = loc;
    if (r < ds.nCases && c < ds.nVars) {
      final v = ds.variables[c];
      final raw = _editCtrl.text.trim();
      Object? val;
      if (raw.isEmpty) {
        val = null;
      } else if (v.isNumeric) {
        val = double.tryParse(raw) ?? num.tryParse(raw);
      } else {
        val = raw;
      }
      final row = ds.cases[r];
      while (row.length <= c) {
        row.add(null);
      }
      datasetStore.recordCellEdit(r, c, _snapshot, val);
      row[c] = val;
    }
    _editing = null;
    _snapshot = null;
    _gridFocus.requestFocus();
    datasetStore.touch();
  }

  void _move(int dr, int dc) {
    final loc = _editing;
    if (loc == null) return;
    _commitEdit();
    final nr = loc.$1 + dr;
    final nc = loc.$2 + dc;
    if (nr >= 0 && nr < ds.nCases && nc >= 0 && nc < ds.nVars) {
      _startEdit(nr, nc);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _abortEdit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _move(1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _move(0, HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 未编辑状态下的全局快捷键（Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z）
  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _editing != null) {
      return KeyEventResult.ignored;
    }
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (!ctrl) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        datasetStore.redo();
      } else {
        datasetStore.undo();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyY) {
      datasetStore.redo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows();
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Focus(
      focusNode: _gridFocus,
      onKeyEvent: _onGridKey,
      child: LayoutBuilder(
        builder: (context, box) {
          final colW = _colWidths(box.maxWidth);
          final contentW = _rowNumW + colW.fold<double>(0, (a, b) => a + b);

          return Column(
            children: [
              _toolbar(l10n, scheme, rows.length),
              Expanded(
                child: Scrollbar(
                  controller: _hCtrl,
                  thumbVisibility: true,
                  notificationPredicate: (n) => n.depth == 1,
                  child: SingleChildScrollView(
                    controller: _hCtrl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentW,
                      child: Column(
                        children: [
                          // 吸顶表头
                          SizedBox(
                            height: _headH,
                            child: Row(
                              children: [
                                _headCell(
                                  '#',
                                  _rowNumW,
                                  scheme,
                                  pinned: true,
                                  align: TextAlign.center,
                                ),
                                for (var c = 0; c < ds.nVars; c++)
                                  _headCell(
                                    ds.variables[c].name,
                                    colW[c],
                                    scheme,
                                    sub: _varSub(ds.variables[c]),
                                  ),
                              ],
                            ),
                          ),
                          // 数据区
                          Expanded(
                            child: Scrollbar(
                              controller: _vCtrl,
                              thumbVisibility: true,
                              child: ListView.builder(
                                controller: _vCtrl,
                                itemExtent: _rowH,
                                itemCount: rows.length,
                                itemBuilder: (context, i) =>
                                    _row(rows[i], i, colW, scheme),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _toolbar(AppLocalizations l10n, ColorScheme scheme, int rowCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.x1 + 2),
          Expanded(
            child: Text(
              '${l10n.doubleClickEdit} · ${l10n.cellEditHint}',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: scheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadius.rSm,
            ),
            child: Text(
              '$rowCount × ${ds.nVars}',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 表头副标题：类型 + 测量尺度 + 标签
  String _varSub(Variable v) {
    final type = v.isNumeric ? '#' : 'A';
    final measure = switch (v.measure) {
      MeasureLevel.nominal => 'N',
      MeasureLevel.ordinal => 'O',
      MeasureLevel.scale => 'S',
    };
    final parts = <String>['$type·$measure'];
    if (v.label.isNotEmpty) parts.add(v.label);
    return parts.join('  ');
  }

  List<int> _filteredRows() {
    final f = widget.filter.toLowerCase();
    final out = <int>[];
    for (var i = 0; i < ds.nCases; i++) {
      if (f.isEmpty) {
        out.add(i);
        continue;
      }
      final hay = ds.cases[i].map((e) => e?.toString() ?? '').join(' ');
      if (hay.toLowerCase().contains(f)) out.add(i);
    }
    return out;
  }

  Widget _headCell(
    String text,
    double w,
    ColorScheme scheme, {
    bool pinned = false,
    String? sub,
    TextAlign align = TextAlign.left,
  }) {
    return Tooltip(
      message: sub == null ? text : '$text\n$sub',
      waitDuration: const Duration(milliseconds: 600),
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
        decoration: BoxDecoration(
          color: pinned
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHigh,
          border: Border(
            right: BorderSide(color: scheme.outlineVariant),
            bottom: BorderSide(color: scheme.outlineVariant, width: 1.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: align,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: pinned ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
            if (sub != null)
              Text(
                sub,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9.5,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(int ri, int displayIndex, List<double> colW, ColorScheme scheme) {
    final row = ds.cases[ri];
    final isEditingRow = _editing?.$1 == ri;
    final zebra = displayIndex.isOdd;

    Color? bg;
    if (isEditingRow) {
      bg = scheme.primaryContainer.withValues(alpha: 0.30);
    } else if (_hoverRow == ri) {
      bg = scheme.surfaceContainerHigh.withValues(alpha: 0.7);
    } else if (zebra) {
      bg = scheme.surfaceContainerLow.withValues(alpha: 0.55);
    }

    return MouseRegion(
      onEnter: (_) {
        if (_hoverRow != ri) setState(() => _hoverRow = ri);
      },
      onExit: (_) {
        if (_hoverRow == ri) setState(() => _hoverRow = null);
      },
      child: Material(
        color: bg ?? Colors.transparent,
        child: SizedBox(
          height: _rowH,
          child: Row(
            children: [
              // 行号
              GestureDetector(
                onDoubleTap: () => _startEdit(ri, 0),
                child: Container(
                  width: _rowNumW,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: isEditingRow ? 0.6 : 0.95,
                    ),
                    border: Border(
                      right: BorderSide(color: scheme.outlineVariant),
                      bottom: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Text(
                    '${ri + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              for (var c = 0; c < ds.nVars; c++)
                _cell(ri, c, row, colW[c], scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(int ri, int c, List<Object?> row, double w, ColorScheme scheme) {
    final v = ds.variables[c];
    final isEdit = _editing != null && _editing!.$1 == ri && _editing!.$2 == c;
    final raw = c < row.length ? row[c] : null;
    final display = widget.showValueLabels
        ? v.displayValue(raw)
        : (raw?.toString() ?? '');
    final missing = v.isMissing(raw);

    return Container(
      width: w,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: isEdit
          ? _editor(v, scheme)
          : _viewer(ri, c, v, display, missing, scheme),
    );
  }

  Widget _viewer(int ri, int c, Variable v, String display, bool missing,
      ColorScheme scheme) {
    final touchPlatform = switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        true,
      _ => false,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: touchPlatform ? () => _startEdit(ri, c) : null,
      onDoubleTap: () => _startEdit(ri, c),
      onLongPress: () => _startEdit(ri, c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
        alignment: v.align == VarAlign.left
            ? Alignment.centerLeft
            : v.align == VarAlign.center
                ? Alignment.center
                : Alignment.centerRight,
        child: Text(
          missing ? '·' : display,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12.5,
            color: missing ? scheme.onSurfaceVariant.withValues(alpha: 0.55) : null,
            fontStyle: missing ? FontStyle.italic : null,
            fontFeatures:
                v.isNumeric ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ),
    );
  }

  Widget _editor(Variable v, ColorScheme scheme) {
    _keyNode ??= FocusNode(onKeyEvent: _onKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: KeyboardListener(
        focusNode: _keyNode!,
        child: TextField(
          controller: _editCtrl,
          focusNode: _editFocus,
          autofocus: true,
          style: const TextStyle(fontSize: 12.5),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
            filled: true,
            fillColor: scheme.surface,
          ),
          keyboardType:
              v.isNumeric ? TextInputType.number : TextInputType.text,
          inputFormatters: v.isNumeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))]
              : null,
          onSubmitted: (_) => _move(1, 0),
        ),
      ),
    );
  }
}

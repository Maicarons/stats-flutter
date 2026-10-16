/// 可编辑数据表格：吸顶表头、斑马纹、悬停高亮、双击编辑、键盘导航、撤销/重做。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stats_flutter/l10n/app_localizations.dart';

import '../../core/models/dataset.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/dataset_store.dart';
import '../../shared/ui/responsive.dart';

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

  /// 冻结区（行号 + 首个变量列）的纵向滚动，与 [_vCtrl] 逐像素同步。
  final ScrollController _vCtrlFrozen = ScrollController();
  bool _syncingV = false;

  /// 正在编辑 (row, col)；null 表示未编辑
  (int, int)? _editing;

  /// 选中单元格 (row, col)：未编辑时方向键移动它，Enter / F2 从这里开始编辑。
  /// 行号为原始行号（非过滤后的显示序号）。
  (int, int)? _sel;

  /// 最近一次布局宽度（用于把选中单元格滚进视口）。
  double _boxW = 0;

  final _editCtrl = TextEditingController();

  /// 编辑框焦点节点，同时承担 Esc / Enter / Tab 的按键处理。
  ///
  /// 注意：按键处理必须挂在**这个**节点上（TextField 自己用的就是它），
  /// 不能再包一层 `KeyboardListener`——`KeyboardListener` 会用自己的包装
  /// 覆盖 `focusNode.onKeyEvent`，导致处理器永远收不到按键。
  late final FocusNode _editFocus =
      FocusNode(debugLabel: 'cellEdit', onKeyEvent: _onKey);
  final _gridFocus = FocusNode(debugLabel: 'gridKeys');

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
    // 两区行高与行数一致，偏移量一一对应，直接镜像即可
    _vCtrl.addListener(() => _mirrorV(_vCtrl, _vCtrlFrozen));
    _vCtrlFrozen.addListener(() => _mirrorV(_vCtrlFrozen, _vCtrl));
  }

  /// 把 [from] 的纵向偏移镜像到 [to]（重入保护，避免互相触发）。
  void _mirrorV(ScrollController from, ScrollController to) {
    if (_syncingV || !from.hasClients || !to.hasClients) return;
    _syncingV = true;
    to.jumpTo(from.offset.clamp(0.0, to.position.maxScrollExtent));
    _syncingV = false;
  }

  /// 冻结的变量列数：宽屏冻结首个变量列，窄屏只冻结行号列。
  int _frozenVarCount(double available) =>
      available >= AppBreakpoints.compact && ds.nVars > 0 ? 1 : 0;

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
    _vCtrlFrozen.dispose();
    _editCtrl.dispose();
    _editFocus.dispose();
    _gridFocus.dispose();
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
    _sel = (r, c);
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

  /// 未编辑状态下的快捷键：方向键移动选中单元格、Enter/F2 进入编辑、
  /// Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z 撤销重做。
  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _editing != null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final move = switch (key) {
      LogicalKeyboardKey.arrowUp => (-1, 0),
      LogicalKeyboardKey.arrowDown => (1, 0),
      LogicalKeyboardKey.arrowLeft => (0, -1),
      LogicalKeyboardKey.arrowRight => (0, 1),
      _ => null,
    };
    if (move != null) {
      _moveSelection(move.$1, move.$2);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.f2) {
      final sel = _sel;
      if (sel != null) {
        _startEdit(sel.$1, sel.$2);
        return KeyEventResult.handled;
      }
    }
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (!ctrl) return KeyEventResult.ignored;
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

  /// 方向键移动选中单元格；无选中态时先落到首个可见行。
  void _moveSelection(int dr, int dc) {
    final rows = _filteredRows();
    if (rows.isEmpty) return;
    final cur = _sel;
    if (cur == null || !rows.contains(cur.$1)) {
      setState(() => _sel = (rows.first, dc < 0 ? ds.nVars - 1 : 0));
      _scrollSelIntoView();
      return;
    }
    final rIdx = rows.indexOf(cur.$1);
    final nr = (rIdx + dr).clamp(0, rows.length - 1);
    final nc = (cur.$2 + dc).clamp(0, ds.nVars - 1);
    setState(() => _sel = (rows[nr], nc));
    _scrollSelIntoView();
  }

  /// 把选中单元格滚进视口（纵向两区同步镜像，横向仅滚动非冻结列）。
  void _scrollSelIntoView() {
    final sel = _sel;
    if (sel == null || _boxW <= 0) return;

    final rows = _filteredRows();
    final idx = rows.indexOf(sel.$1);
    if (idx >= 0 && _vCtrl.hasClients) {
      final pos = _vCtrl.position;
      final top = idx * _rowH;
      final bottom = top + _rowH;
      if (top < pos.pixels) {
        _vCtrl.jumpTo(top.clamp(0.0, pos.maxScrollExtent));
      } else if (bottom > pos.pixels + pos.viewportDimension) {
        _vCtrl.jumpTo(
          (bottom - pos.viewportDimension).clamp(0.0, pos.maxScrollExtent),
        );
      }
    }

    final frozen = _frozenVarCount(_boxW);
    if (sel.$2 < frozen || !_hCtrl.hasClients) return;
    final colW = _colWidths(_boxW);
    var left = 0.0;
    for (var c = frozen; c < sel.$2 && c < colW.length; c++) {
      left += colW[c];
    }
    final right = left + (sel.$2 < colW.length ? colW[sel.$2] : 0);
    final pos = _hCtrl.position;
    if (left < pos.pixels) {
      _hCtrl.jumpTo(left.clamp(0.0, pos.maxScrollExtent));
    } else if (right > pos.pixels + pos.viewportDimension) {
      _hCtrl.jumpTo(
        (right - pos.viewportDimension).clamp(0.0, pos.maxScrollExtent),
      );
    }
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
          _boxW = box.maxWidth;
          final colW = _colWidths(box.maxWidth);
          final frozen = _frozenVarCount(box.maxWidth);
          final frozenW =
              _rowNumW + colW.take(frozen).fold<double>(0, (a, b) => a + b);
          final restW = colW.skip(frozen).fold<double>(0, (a, b) => a + b);

          return Column(
            children: [
              _toolbar(l10n, scheme, rows.length),
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 冻结区：行号列（宽屏再加首个变量列），不参与横向滚动
                        SizedBox(
                          width: frozenW,
                          child: Column(
                            children: [
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
                                      frozenEdge: frozen == 0,
                                    ),
                                    for (var c = 0; c < frozen; c++)
                                      _headCell(
                                        ds.variables[c].name,
                                        colW[c],
                                        scheme,
                                        pinned: true,
                                        frozenEdge: c == frozen - 1,
                                        sub: _varSub(ds.variables[c]),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: _vCtrlFrozen,
                                  itemExtent: _rowH,
                                  itemCount: rows.length,
                                  itemBuilder: (context, i) => _rowFrozen(
                                      rows[i], i, colW, scheme, frozen),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 可横向滚动区：其余变量列
                        Expanded(
                          child: Scrollbar(
                            controller: _hCtrl,
                            thumbVisibility: true,
                            notificationPredicate: (n) =>
                                n.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _hCtrl,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: restW,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: _headH,
                                      child: Row(
                                        children: [
                                          for (var c = frozen;
                                              c < ds.nVars;
                                              c++)
                                            _headCell(
                                              ds.variables[c].name,
                                              colW[c],
                                              scheme,
                                              sub: _varSub(ds.variables[c]),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Scrollbar(
                                        controller: _vCtrl,
                                        thumbVisibility: true,
                                        notificationPredicate: (n) =>
                                            n.metrics.axis == Axis.vertical,
                                        child: ListView.builder(
                                          controller: _vCtrl,
                                          itemExtent: _rowH,
                                          itemCount: rows.length,
                                          itemBuilder: (context, i) =>
                                              _rowScroll(rows[i], i, colW,
                                                  scheme, frozen),
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
                    ),
                    // 冻结边界阴影（覆盖在右区之上，不占布局宽度）
                    if (frozen > 0)
                      Positioned(
                        left: frozenW,
                        top: 0,
                        bottom: 0,
                        width: 10,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  scheme.shadow.withValues(alpha: 0.16),
                                  scheme.shadow.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
    bool frozenEdge = false,
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
            // 冻结区右边界加粗，作为「已冻结」的视觉提示
            right: BorderSide(
              color: frozenEdge ? scheme.outline : scheme.outlineVariant,
              width: frozenEdge ? 1.2 : 1,
            ),
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

  /// 行背景：编辑中 > 悬停 > 斑马纹（两侧共用，避免冻结区与滚动区出现色差）。
  Color? _rowBg(int ri, int displayIndex, ColorScheme scheme) {
    if (_editing?.$1 == ri) {
      return scheme.primaryContainer.withValues(alpha: 0.30);
    }
    if (_hoverRow == ri) {
      return scheme.surfaceContainerHigh.withValues(alpha: 0.7);
    }
    if (displayIndex.isOdd) {
      return scheme.surfaceContainerLow.withValues(alpha: 0.55);
    }
    return null;
  }

  Widget _rowMouse(int ri, Widget child) => MouseRegion(
        onEnter: (_) {
          if (_hoverRow != ri) setState(() => _hoverRow = ri);
        },
        onExit: (_) {
          if (_hoverRow == ri) setState(() => _hoverRow = null);
        },
        child: child,
      );

  /// 冻结区行：行号列 + 冻结变量列（不参与横向滚动）。
  Widget _rowFrozen(
    int ri,
    int displayIndex,
    List<double> colW,
    ColorScheme scheme,
    int frozen,
  ) {
    final row = ds.cases[ri];
    return _rowMouse(
      ri,
      Material(
        color: _rowBg(ri, displayIndex, scheme) ?? Colors.transparent,
        child: SizedBox(
          height: _rowH,
          child: Row(
            children: [
              _rowHeader(ri, scheme, frozenEdge: frozen == 0),
              for (var c = 0; c < frozen; c++)
                _cell(ri, c, row, colW[c], scheme, frozenEdge: c == frozen - 1),
            ],
          ),
        ),
      ),
    );
  }

  /// 滚动区行：其余变量列。
  Widget _rowScroll(
    int ri,
    int displayIndex,
    List<double> colW,
    ColorScheme scheme,
    int frozen,
  ) {
    final row = ds.cases[ri];
    return _rowMouse(
      ri,
      Material(
        color: _rowBg(ri, displayIndex, scheme) ?? Colors.transparent,
        child: SizedBox(
          height: _rowH,
          child: Row(
            children: [
              for (var c = frozen; c < ds.nVars; c++)
                _cell(ri, c, row, colW[c], scheme),
            ],
          ),
        ),
      ),
    );
  }

  /// 行号单元格
  Widget _rowHeader(int ri, ColorScheme scheme, {bool frozenEdge = false}) {
    final isEditingRow = _editing?.$1 == ri;
    return GestureDetector(
      onDoubleTap: () => _startEdit(ri, 0),
      child: Container(
        width: _rowNumW,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: isEditingRow ? 0.6 : 0.95,
          ),
          border: Border(
            right: BorderSide(
              color: frozenEdge ? scheme.outline : scheme.outlineVariant,
              width: frozenEdge ? 1.2 : 1,
            ),
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
    );
  }

  Widget _cell(int ri, int c, List<Object?> row, double w, ColorScheme scheme,
      {bool frozenEdge = false}) {
    final v = ds.variables[c];
    final isEdit = _editing != null && _editing!.$1 == ri && _editing!.$2 == c;
    final isSel = !isEdit && _sel != null && _sel!.$1 == ri && _sel!.$2 == c;
    final raw = c < row.length ? row[c] : null;
    final display = widget.showValueLabels
        ? v.displayValue(raw)
        : (raw?.toString() ?? '');
    final missing = v.isMissing(raw);

    return Container(
      width: w,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: frozenEdge ? scheme.outline : scheme.outlineVariant,
            width: frozenEdge ? 1.2 : 1,
          ),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      // 选中态用前景描边（不占布局，不引起列宽/行高变化）
      foregroundDecoration: isSel
          ? BoxDecoration(
              border: Border.all(color: scheme.primary, width: 1.6),
            )
          : null,
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
    return Listener(
      // 用原始指针事件选中单元格：不受「双击」手势竞技场延迟影响，
      // 点击后立即可用方向键（单击在桌面端仍不进入编辑）。
      onPointerDown: (_) {
        if (_sel?.$1 != ri || _sel?.$2 != c) {
          setState(() => _sel = (ri, c));
        }
        if (!_gridFocus.hasFocus) _gridFocus.requestFocus();
      },
      child: GestureDetector(
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
              color:
                  missing ? scheme.onSurfaceVariant.withValues(alpha: 0.55) : null,
              fontStyle: missing ? FontStyle.italic : null,
              fontFeatures:
                  v.isNumeric ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor(Variable v, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
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
        keyboardType: v.isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: v.isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))]
            : null,
        onSubmitted: (_) => _move(1, 0),
      ),
    );
  }
}

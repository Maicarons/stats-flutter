/// 编辑历史：撤销 / 重做栈
///
/// 两类条目：
/// - 单元格级增量（轻量，可合并连续编辑）
/// - 全量快照（结构操作：增删变量/个案、变换、导入等）
library;

import '../core/models/dataset.dart';

sealed class _UndoEntry {
  void apply(Dataset ds);
}

class _CellEdit extends _UndoEntry {
  final int row;
  final int col;
  final Object? before;
  Object? after;
  _CellEdit(this.row, this.col, this.before, this.after);

  @override
  void apply(Dataset ds) {
    if (row < 0 || row >= ds.cases.length) return;
    final r = ds.cases[row];
    while (r.length <= col) {
      r.add(null);
    }
    r[col] = after;
  }
}

class _Snapshot extends _UndoEntry {
  final Dataset state;
  _Snapshot(this.state);

  @override
  void apply(Dataset ds) {
    ds.variables
      ..clear()
      ..addAll([for (final v in state.variables) v.copy()]);
    ds.cases
      ..clear()
      ..addAll([for (final r in state.cases) List<Object?>.of(r)]);
    ds.name = state.name;
    ds.weightVariable = state.weightVariable;
    ds.splitVariable = state.splitVariable;
  }
}

class EditHistory {
  /// 栈深上限（快照可能较大）
  final int maxEntries;

  final List<_UndoEntry> _undo = [];
  final List<_UndoEntry> _redo = [];

  EditHistory({this.maxEntries = 25});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void clear() {
    _undo.clear();
    _redo.clear();
  }

  /// 单元格编辑：同一单元格的连续编辑自动合并
  void recordCellEdit(int row, int col, Object? before, Object? after) {
    if (_sameValue(before, after)) return;
    if (_undo.isNotEmpty && _undo.last is _CellEdit) {
      final last = _undo.last as _CellEdit;
      if (last.row == row && last.col == col) {
        last.after = after;
        _redo.clear();
        return;
      }
    }
    _push(_CellEdit(row, col, before, after));
  }

  /// 结构操作前调用：快照当前状态
  void checkpoint(Dataset ds) => _push(_Snapshot(ds.copy()));

  void undo(Dataset ds) {
    if (_undo.isEmpty) return;
    final e = _undo.removeLast();
    if (e is _CellEdit) {
      _redo.add(_CellEdit(e.row, e.col, e.before, e.after));
      _CellEdit(e.row, e.col, e.after, e.before).apply(ds);
    } else if (e is _Snapshot) {
      _redo.add(_Snapshot(ds.copy()));
      e.apply(ds);
    }
  }

  void redo(Dataset ds) {
    if (_redo.isEmpty) return;
    final e = _redo.removeLast();
    if (e is _CellEdit) {
      _undo.add(_CellEdit(e.row, e.col, e.before, e.after));
      e.apply(ds);
    } else if (e is _Snapshot) {
      _undo.add(_Snapshot(ds.copy()));
      e.apply(ds);
    }
  }

  void _push(_UndoEntry e) {
    _undo.add(e);
    if (_undo.length > maxEntries) _undo.removeAt(0);
    _redo.clear();
  }

  static bool _sameValue(Object? a, Object? b) {
    if (a == null && b == null) return true;
    if (a is num && b is num) return (a - b).abs() < 1e-12;
    return a == b;
  }
}

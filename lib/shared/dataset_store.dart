/// 全局数据集状态 — 现在代理到当前工程
library;

import 'package:flutter/foundation.dart';

import '../core/models/dataset.dart';
import 'project_store.dart';

class DatasetStore extends ChangeNotifier {
  String? _lastAnalysis;

  String? get lastAnalysis => _lastAnalysis;

  /// 当前数据集（来自打开的工程；无工程时给空白）
  Dataset get data {
    final ds = projectStore.currentDataset;
    if (ds != null) return ds;
    _fallback ??= Dataset(name: 'Untitled');
    return _fallback!;
  }

  Dataset? _fallback;

  bool get hasProject => projectStore.current != null;

  void replace(Dataset d) {
    final p = projectStore.current;
    if (p != null) {
      // 在工程内替换内容
      p.dataset.variables
        ..clear()
        ..addAll(d.variables);
      p.dataset.cases
        ..clear()
        ..addAll(d.cases);
      p.dataset.name = d.name;
      projectStore.markDirty();
    } else {
      _fallback = d;
    }
    _lastAnalysis = null;
    notifyListeners();
    projectStore.markDirty();
  }

  void touch() {
    if (projectStore.current != null) {
      projectStore.markDirty();
    }
    notifyListeners();
  }

  void setLastAnalysis(String name) {
    _lastAnalysis = name;
    notifyListeners();
  }

  void resetDemo() {
    replace(Dataset.demoScores());
  }

  /// 工程切换时重置
  void onProjectChanged() {
    _fallback = null;
    _lastAnalysis = null;
    notifyListeners();
  }
}

final datasetStore = DatasetStore();

/// 工程仓库：列表 + 磁盘持久化
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/models/dataset.dart';
import '../core/models/project.dart';

class ProjectStore extends ChangeNotifier {
  final List<ProjectMeta> _metas = [];
  Project? _current;
  bool _loaded = false;
  Directory? _root;

  List<ProjectMeta> get projects => List.unmodifiable(_metas);
  Project? get current => _current;
  bool get loaded => _loaded;
  String get rootPath => _root?.path ?? '';

  /// 初始化：扫描工程目录
  Future<void> load() async {
    if (_loaded) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _root = Directory('${docs.path}/stats_flutter_projects');
      if (!await _root!.exists()) {
        await _root!.create(recursive: true);
      }
      await _scan();
    } catch (e) {
      debugPrint('ProjectStore.load error: $e');
      _root = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _scan() async {
    _metas.clear();
    if (_root == null) return;
    await for (final f in _root!.list()) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await f.readAsString());
        if (json is Map<String, dynamic> && json['meta'] != null) {
          final p = Project.fromJson(json);
          _metas.add(p.meta);
        }
      } catch (_) {
        // skip corrupt
      }
    }
    _metas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  String _fileOf(String id) => '${_root!.path}/$id.json';

  /// 新建工程（可选内置示例数据）
  Future<Project> create({
    required String name,
    String? description,
    bool withDemo = false,
  }) async {
    final ds = withDemo ? Dataset.demoScores() : Dataset(name: name);
    final p = Project.create(
      name: name,
      description: description,
      dataset: ds,
    );
    p.touch();
    await _persist(p);
    _metas.insert(0, p.meta);
    _current = p;
    notifyListeners();
    return p;
  }

  /// 打开工程
  Future<Project?> open(String id) async {
    if (_root == null) await load();
    if (_root == null) return null;
    final file = File(_fileOf(id));
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      final p = Project.fromJson(Map<String, dynamic>.from(json as Map));
      _current = p;
      notifyListeners();
      return p;
    } catch (e) {
      debugPrint('ProjectStore.open error: $e');
      return null;
    }
  }

  /// 保存当前工程
  Future<void> saveCurrent() async {
    final p = _current;
    if (p == null || _root == null) return;
    p.touch();
    await _persist(p);
    // 更新列表元数据
    final i = _metas.indexWhere((m) => m.id == p.meta.id);
    if (i >= 0) {
      _metas[i] = p.meta;
    } else {
      _metas.insert(0, p.meta);
    }
    _metas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> _persist(Project p) async {
    if (_root == null) return;
    final file = File(_fileOf(p.meta.id));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(p.toJson()),
    );
  }

  /// 重命名
  Future<void> rename(String id, String newName) async {
    final i = _metas.indexWhere((m) => m.id == id);
    if (i < 0) return;
    _metas[i].name = newName;
    _metas[i].updatedAt = DateTime.now();
    if (_current?.meta.id == id) {
      _current!.meta.name = newName;
      _current!.dataset.name = newName;
      await saveCurrent();
    } else if (_root != null) {
      final file = File(_fileOf(id));
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        final p = Project.fromJson(Map<String, dynamic>.from(json as Map));
        p.meta.name = newName;
        p.touch();
        await _persist(p);
      }
    }
    notifyListeners();
  }

  /// 复制工程
  Future<void> duplicate(String id, String newName) async {
    Project? src;
    if (_current?.meta.id == id) {
      src = _current;
    } else if (_root != null) {
      final file = File(_fileOf(id));
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        src = Project.fromJson(Map<String, dynamic>.from(json as Map));
      }
    }
    if (src == null) return;
    final copy = src.copyAs(newName);
    await _persist(copy);
    _metas.insert(0, copy.meta);
    notifyListeners();
  }

  /// 删除工程
  Future<void> delete(String id) async {
    _metas.removeWhere((m) => m.id == id);
    if (_current?.meta.id == id) _current = null;
    if (_root != null) {
      final file = File(_fileOf(id));
      if (await file.exists()) await file.delete();
    }
    notifyListeners();
  }

  /// 关闭当前（不丢数据，仅退出工作区）
  void closeCurrent() {
    _current = null;
    notifyListeners();
  }

  /// 当前数据集（供分析层使用）
  Dataset? get currentDataset => _current?.dataset;

  /// 标脏保存（编辑后调用）
  Future<void> markDirty() => saveCurrent();
}

/// 全局单例
final projectStore = ProjectStore();

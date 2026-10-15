/// 分析中心的本地偏好：收藏与最近使用（持久化到 SharedPreferences）。
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisPrefs extends ChangeNotifier {
  static const _kFavorites = 'analysis.favorites';
  static const _kRecents = 'analysis.recents';
  static const _maxRecents = 6;

  List<String> _favorites = [];
  List<String> _recents = [];
  bool _loaded = false;

  List<String> get favorites => List.unmodifiable(_favorites);
  List<String> get recents => List.unmodifiable(_recents);
  bool get loaded => _loaded;

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> load() async {
    if (_loaded) return;
    final sp = await SharedPreferences.getInstance();
    _favorites = sp.getStringList(_kFavorites) ?? [];
    _recents = sp.getStringList(_kRecents) ?? [];
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kFavorites, _favorites);
  }

  Future<void> markUsed(String id) async {
    _recents.remove(id);
    _recents.insert(0, id);
    if (_recents.length > _maxRecents) {
      _recents = _recents.sublist(0, _maxRecents);
    }
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kRecents, _recents);
  }
}

final analysisPrefs = AnalysisPrefs();

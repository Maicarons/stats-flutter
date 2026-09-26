/// 应用设置（主题 / 语言 / 持久化）
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF2F6FED);
  Locale? _locale; // null = follow system

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  Locale? get locale => _locale;

  static const _kThemeMode = 'settings.themeMode';
  static const _kSeed = 'settings.seedColor';
  static const _kLocale = 'settings.locale';

  /// 主题色预设
  static const presetColors = <Color>[
    Color(0xFF2F6FED), // 蓝
    Color(0xFF6C5CE7), // 紫
    Color(0xFF00B894), // 青绿
    Color(0xFFE17055), // 珊瑚
    Color(0xFFD63031), // 红
    Color(0xFF0984E3), // 亮蓝
    Color(0xFFE84393), // 品红
    Color(0xFF2D3436), // 石墨
  ];

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final tm = sp.getString(_kThemeMode);
    if (tm != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == tm,
        orElse: () => ThemeMode.system,
      );
    }
    final seed = sp.getInt(_kSeed);
    if (seed != null) _seedColor = Color(seed);
    final loc = sp.getString(_kLocale);
    if (loc != null && loc.isNotEmpty) {
      _locale = Locale(loc);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemeMode, mode.name);
  }

  Future<void> setSeedColor(Color c) async {
    _seedColor = c;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSeed, c.toARGB32());
  }

  Future<void> setLocale(Locale? loc) async {
    _locale = loc;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    if (loc == null) {
      await sp.remove(_kLocale);
    } else {
      await sp.setString(_kLocale, loc.languageCode);
    }
  }

  Future<void> reset() async {
    _themeMode = ThemeMode.system;
    _seedColor = const Color(0xFF2F6FED);
    _locale = null;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kThemeMode);
    await sp.remove(_kSeed);
    await sp.remove(_kLocale);
  }
}

final appSettings = AppSettings();

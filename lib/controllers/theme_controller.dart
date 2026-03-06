import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider global para el tema
final themeProvider = NotifierProvider<ThemeController, ThemeMode>(() {
  return ThemeController();
});

class ThemeController extends Notifier<ThemeMode> {
  late Box _box;

  @override
  ThemeMode build() {
    _box = Hive.box('settingsBox');
    final themeIndex = _box.get('themeMode');
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.system;
  }

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await _box.put('themeMode', state.index);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _box.put('themeMode', mode.index);
  }
}

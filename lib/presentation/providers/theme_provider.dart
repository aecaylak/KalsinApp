import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _themeBoxName = 'settings';
const _themeKey = 'themeMode';

/// Kullanıcının seçtiği tema modu — system/light/dark.
/// Hive settings box üzerinden kalıcı.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_load());

  static ThemeMode _load() {
    final box = Hive.box(_themeBoxName);
    final val = box.get(_themeKey, defaultValue: 'dark') as String;
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(_themeBoxName);
    final val = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await box.put(_themeKey, val);
  }

  void cycle() {
    switch (state) {
      case ThemeMode.system:
        setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setTheme(ThemeMode.light);
        break;
      case ThemeMode.light:
        setTheme(ThemeMode.system);
        break;
    }
  }

  String get label {
    switch (state) {
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.dark:
        return 'Koyu';
      case ThemeMode.light:
        return 'Açık';
    }
  }

  String get emoji {
    switch (state) {
      case ThemeMode.system:
        return '🌓';
      case ThemeMode.dark:
        return '🌙';
      case ThemeMode.light:
        return '☀️';
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

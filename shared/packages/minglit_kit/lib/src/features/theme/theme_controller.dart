import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_controller.g.dart';

/// ThemeController manages theme mode with SharedPreferences persistence.
@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  static const _key = 'minglit_theme_mode';

  @override
  ThemeMode build() {
    unawaited(_loadSaved());
    return ThemeMode.system;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// Sets and persists [mode] to SharedPreferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

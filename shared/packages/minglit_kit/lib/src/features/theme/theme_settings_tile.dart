import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/theme/theme_controller.dart';

/// Tile widget for selecting app theme mode (system/light/dark).
class ThemeSettingsTile extends ConsumerWidget {
  /// Creates a [ThemeSettingsTile].
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeControllerProvider);
    return ListTile(
      leading: Icon(
        currentMode == ThemeMode.dark
            ? Icons.dark_mode
            : currentMode == ThemeMode.light
            ? Icons.light_mode
            : Icons.brightness_auto,
      ),
      title: const Text('테마'),
      subtitle: Text(
        currentMode == ThemeMode.dark
            ? '다크 모드'
            : currentMode == ThemeMode.light
            ? '라이트 모드'
            : '시스템 설정',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        unawaited(_showThemePicker(context, ref, currentMode));
      },
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('테마 설정'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                unawaited(
                  ref.read(themeControllerProvider.notifier).setThemeMode(v),
                );
              }
              Navigator.pop(ctx);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(
                      mode == ThemeMode.system
                          ? '시스템 설정'
                          : mode == ThemeMode.light
                          ? '라이트 모드'
                          : '다크 모드',
                    ),
                    value: mode,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

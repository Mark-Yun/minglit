import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Tile widget for selecting app theme mode (system/light/dark).
class ThemeSettingsTile extends ConsumerWidget {
  /// Creates a [ThemeSettingsTile].
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeControllerProvider);
    // Fix #139: When system mode, show icon matching actual current brightness
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    final icon = currentMode == ThemeMode.dark
        ? Icons.dark_mode_outlined
        : currentMode == ThemeMode.light
        ? Icons.light_mode_outlined
        : systemBrightness == Brightness.dark
        ? Icons.dark_mode_outlined
        : Icons.light_mode_outlined;

    final subtitle = currentMode == ThemeMode.dark
        ? '다크 모드'
        : currentMode == ThemeMode.light
        ? '라이트 모드'
        : '시스템 설정';

    return MinglitSettingsTile(
      leading: icon,
      title: '테마',
      subtitle: subtitle,
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
    // Standard M3 SimpleDialog for now,
    // but could be improved to MinglitBottomSheet or MinglitAlert.
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('테마 설정'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('시스템 설정'),
            value: ThemeMode.system,
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                unawaited(
                  ref.read(themeControllerProvider.notifier).setThemeMode(v),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('라이트 모드'),
            value: ThemeMode.light,
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                unawaited(
                  ref.read(themeControllerProvider.notifier).setThemeMode(v),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('다크 모드'),
            value: ThemeMode.dark,
            groupValue: current,
            onChanged: (v) {
              if (v != null) {
                unawaited(
                  ref.read(themeControllerProvider.notifier).setThemeMode(v),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

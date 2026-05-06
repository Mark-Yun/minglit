import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';

/// A standardized dialog widget for Minglit applications.
/// Use [show] or [showConfirm] for easier usage.
class MinglitAlert extends StatelessWidget {
  /// Creates a standardized alert dialog.
  const MinglitAlert({
    required this.title,
    this.content,
    this.actions,
    this.type = MinglitAlertType.info,
    super.key,
  });

  /// Dialog title text.
  final String title;

  /// Optional dialog body text.
  final String? content;

  /// Optional action buttons for the dialog.
  final List<Widget>? actions;

  /// Visual style for the alert.
  final MinglitAlertType type;

  /// Shows a generic dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    List<Widget>? actions,
    MinglitAlertType type = MinglitAlertType.info,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => MinglitAlert(
        title: title,
        content: content,
        actions: actions,
        type: type,
      ),
    );
  }

  /// Shows a confirmation dialog with "Cancel" and "Confirm" buttons.
  /// Returns `true` if confirmed, `false` otherwise.
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    String? content,
    String confirmText = '확인',
    String cancelText = '취소',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MinglitAlert(
        title: title,
        content: content,
        type: isDestructive
            ? MinglitAlertType.destructive
            : MinglitAlertType.info,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      // M3 mobile 톤 (2026-05-01) — spec 권장 일치:
      //   외부 16 H · 24 V · 내부 24 padding
      //   title↔content 16 / content↔actions 24 (M3 표준)
      //   destructive 톤은 확인 버튼만 빨강 — 아이콘 / 빨강 타이틀 제거
      //   (industry 표준 — iOS / Linear / GitHub).
      insetPadding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.large,
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.medium,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.zero,
        MinglitSpacing.large,
        MinglitSpacing.large,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.sm,
        MinglitSpacing.zero,
        MinglitSpacing.large,
        MinglitSpacing.large,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: content != null
          ? Text(
              content!,
              style: theme.textTheme.bodyMedium,
            )
          : null,
      actions: actions,
    );
  }
}

/// Visual variants for [MinglitAlert].
enum MinglitAlertType {
  /// Neutral informational alert.
  info,

  /// Destructive alert with warning emphasis.
  destructive,
}

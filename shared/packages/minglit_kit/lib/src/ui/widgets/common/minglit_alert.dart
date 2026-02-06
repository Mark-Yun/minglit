import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A standardized dialog widget for Minglit applications.
/// Use [show] or [showConfirm] for easier usage.
class MinglitAlert extends StatelessWidget {
  const MinglitAlert({
    required this.title,
    this.content,
    this.actions,
    this.type = MinglitAlertType.info,
    super.key,
  });

  final String title;
  final String? content;
  final List<Widget>? actions;
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
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface.withValues(
        alpha: 0,
      ), // Remove standardized tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.medium,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        0,
        MinglitSpacing.large,
        MinglitSpacing.large,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        0,
        MinglitSpacing.medium,
        MinglitSpacing.medium,
      ),

      title: Row(
        children: [
          if (type == MinglitAlertType.destructive) ...[
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(width: MinglitSpacing.small),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: content != null
          ? Text(
              content!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      actions: actions,
    );
  }
}

enum MinglitAlertType {
  info,
  destructive,
}

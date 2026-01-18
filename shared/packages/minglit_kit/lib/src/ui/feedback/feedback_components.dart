import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

enum MinglitFeedbackType {
  success,
  info,
  warning,
  error,
}

/// **Minglit Feedback UI Builder**
///
/// Provides standardized SnackBar and Dialog configurations.
class MinglitFeedbackUI {
  static SnackBar buildSnackBar({
    required BuildContext context,
    required String message,
    required MinglitFeedbackType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);

    // Determine colors based on type
    final (bgColor, icon, iconColor) = switch (type) {
      MinglitFeedbackType.success => (
        theme.colorScheme.primary,
        Icons.check_circle_outline,
        Colors.white,
      ),
      MinglitFeedbackType.info => (
        theme.colorScheme.onSurface,
        Icons.info_outline,
        theme.colorScheme.surface,
      ),
      MinglitFeedbackType.warning => (
        theme.colorScheme.secondary,
        Icons.warning_amber_rounded,
        Colors.white,
      ),
      MinglitFeedbackType.error => (
        theme.colorScheme.error,
        Icons.error_outline,
        theme.colorScheme.onError,
      ),
    };

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: MinglitIconSize.small),
          const SizedBox(width: MinglitSpacing.medium),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: iconColor),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      duration: duration,
      margin: const EdgeInsets.all(MinglitSpacing.medium),
    );
  }

  static Widget buildDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isConfirm = false,
    MinglitFeedbackType type = MinglitFeedbackType.info,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      title: Text(title, style: theme.textTheme.titleLarge),
      content: Text(message, style: theme.textTheme.bodyMedium),
      actions: [
        if (isConfirm)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel ?? '취소',
              style: TextStyle(color: colorScheme.outline),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel ?? '확인',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static MaterialBanner buildBanner({
    required BuildContext context,
    required String message,
    required VoidCallback onAction,
    String actionLabel = '확인',
    MinglitFeedbackType type = MinglitFeedbackType.info,
  }) {
    final theme = Theme.of(context);
    return MaterialBanner(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}

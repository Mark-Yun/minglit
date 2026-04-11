import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A standardized dialog widget for Minglit applications
/// that supports custom content.
class MinglitDialog extends StatelessWidget {
  /// Creates a standardized dialog with custom content.
  const MinglitDialog({
    required this.title,
    required this.content,
    this.actions,
    super.key,
  });

  /// Dialog title text.
  final String title;

  /// Main content widget displayed in the dialog.
  final Widget content;

  /// Optional action buttons for the dialog.
  final List<Widget>? actions;

  /// Shows a standardized dialog with custom content.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) =>
          MinglitDialog(title: title, content: content, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface.withValues(
        alpha: MinglitOpacity.none,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.medium,
      ),
      contentPadding: const EdgeInsets.only(
        left: MinglitSpacing.large,
        right: MinglitSpacing.large,
        bottom: MinglitSpacing.large,
      ),
      actionsPadding: const EdgeInsets.only(
        left: MinglitSpacing.medium,
        right: MinglitSpacing.medium,
        bottom: MinglitSpacing.medium,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: content,
      actions: actions,
    );
  }
}

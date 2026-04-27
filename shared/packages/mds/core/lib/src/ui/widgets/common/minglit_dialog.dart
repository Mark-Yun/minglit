import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';

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

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.large,
        MinglitSpacing.small,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.zero,
        MinglitSpacing.large,
        MinglitSpacing.xsmall,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.sm,
        MinglitSpacing.zero,
        MinglitSpacing.large,
        MinglitSpacing.large,
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

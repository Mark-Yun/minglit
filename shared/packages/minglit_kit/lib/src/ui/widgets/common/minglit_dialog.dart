import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A standardized dialog widget for Minglit applications
/// that supports custom content.
class MinglitDialog extends StatelessWidget {
  const MinglitDialog({
    required this.title,
    required this.content,
    this.actions,
    super.key,
  });

  final String title;
  final Widget content;
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
      builder: (context) => MinglitDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface.withValues(alpha: 0),
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

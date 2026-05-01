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
      // M3 mobile 톤 (2026-05-01) — spec 권장 일치:
      //   외부 16 H · 24 V · 내부 24 padding
      //   title↔content 16 / content↔actions 24 (M3 표준)
      //   title은 bodyLarge(18) bold — titleMedium(16)보다 시각 임팩트 강화.
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
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: content,
      actions: actions,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_button.dart';

/// A standardized dialog widget for Minglit applications.
/// Use [show] or [showConfirm] for easier usage.
class MinglitAlert extends StatelessWidget {
  /// Creates a standardized alert dialog.
  const MinglitAlert({
    required this.title,
    this.content,
    this.contentWidget,
    this.actions,
    this.type = MinglitAlertType.info,
    super.key,
  });

  /// Dialog title text.
  final String title;

  /// Optional dialog body text.
  final String? content;

  /// Optional custom widget for the dialog content.
  /// If provided, [content] text is ignored.
  final Widget? contentWidget;

  /// Optional action buttons for the dialog.
  final List<Widget>? actions;

  /// Visual style for the alert.
  final MinglitAlertType type;

  /// Shows a generic dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    MinglitAlertType type = MinglitAlertType.info,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => MinglitAlert(
        title: title,
        content: content,
        contentWidget: contentWidget,
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
    Widget? contentWidget,
    String confirmText = '확인',
    String cancelText = '취소',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MinglitAlert(
        title: title,
        content: content,
        contentWidget: contentWidget,
        type: isDestructive
            ? MinglitAlertType.destructive
            : MinglitAlertType.info,
        actions: [
          MinglitButton.text(
            label: cancelText,
            onPressed: () => Navigator.pop(context, false),
            // Use secondary color for cancel to avoid visual clutter
          ),
          const SizedBox(width: MinglitSpacing.small),
          if (isDestructive)
            MinglitButton.destructive(
              label: confirmText,
              onPressed: () => Navigator.pop(context, true),
              expand: false,
              size: MinglitButtonSize.medium,
            )
          else
            MinglitButton(
              label: confirmText,
              onPressed: () => Navigator.pop(context, true),
              expand: false,
              size: MinglitButtonSize.medium,
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
      surfaceTintColor: Colors.transparent,
      // Fix #1518: Add soft shadow for premium "lifted" feel
      elevation: 8,
      shadowColor: colorScheme.shadow.withValues(
        alpha: MinglitOpacity.shadowSm,
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
      actionsPadding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.zero,
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
      content: contentWidget ??
          (content != null
              ? Text(
                  content!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null),
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

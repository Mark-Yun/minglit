import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Bottom Sheet**
///
/// A themed bottom sheet content widget for the Minglit design system.
/// Provides a consistent structure with optional drag handle, title header,
/// and content padding using Minglit design tokens.
///
/// Use [showMinglitBottomSheet] to display this as a modal bottom sheet.
///
/// {@tool snippet}
/// ```dart
/// showMinglitBottomSheet(
///   context: context,
///   title: '옵션 선택',
///   child: Column(
///     children: [
///       ListTile(title: Text('옵션 1')),
///       ListTile(title: Text('옵션 2')),
///     ],
///   ),
/// );
/// ```
/// {@end-tool}
class MinglitBottomSheet extends StatelessWidget {
  /// Creates a bottom sheet content widget with optional [title] and [child].
  const MinglitBottomSheet({
    required this.child,
    this.title,
    this.showHandle = true,
    this.padding,
    super.key,
  });

  /// The main content of the bottom sheet.
  final Widget child;

  /// Optional title displayed below the handle.
  final String? title;

  /// Whether to show the drag handle at the top.
  final bool showHandle;

  /// Custom padding for the content.
  /// Defaults to horizontal screenEdge + vertical medium.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            const SizedBox(height: MinglitSpacing.small),
            _DragHandle(color: colorScheme.onSurfaceVariant),
            const SizedBox(height: MinglitSpacing.small),
          ],
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.screenEdge,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: MinglitSpacing.sm),
          ],
          Flexible(
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.only(
                    left: MinglitSpacing.screenEdge,
                    right: MinglitSpacing.screenEdge,
                    bottom: MinglitSpacing.medium,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: MinglitOpacity.muted),
          borderRadius: BorderRadius.circular(MinglitRadius.chip),
        ),
        child: const SizedBox(width: 32, height: 4),
      ),
    );
  }
}

/// Shows a Minglit-styled modal bottom sheet.
///
/// Wraps [showModalBottomSheet] with consistent Minglit design tokens
/// (border radius, background color, handle, title).
Future<T?> showMinglitBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool showHandle = true,
  EdgeInsets? padding,
  bool isScrollControlled = false,
  BoxConstraints? constraints,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    constraints: constraints,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MinglitRadius.card),
      ),
    ),
    builder: (ctx) => MinglitBottomSheet(
      title: title,
      showHandle: showHandle,
      padding: padding,
      child: child,
    ),
  );
}

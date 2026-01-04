import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Minglit Editable Section**
///
/// A wrapper widget that provides a consistent layout for editable sections.
/// The entire area (including title) is clickable.
class MinglitEditableSection extends StatelessWidget {
  const MinglitEditableSection({
    required this.title,
    required this.child,
    this.onTap,
    this.isEditable = true,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          // Subtle background instead of border
          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Title + Edit Icon)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEditable && onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: MinglitSpacing.small),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.small),

            // Content
            child,
          ],
        ),
      ),
    );
  }
}

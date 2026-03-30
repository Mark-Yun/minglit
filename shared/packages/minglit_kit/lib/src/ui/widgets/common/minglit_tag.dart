import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Size variants for [MinglitTag].
enum MinglitTagSize {
  /// Compact tag size.
  small,

  /// Default tag size.
  medium,
}

/// **Minglit Tag**
///
/// A read-only tag widget for the Minglit design system.
/// Displays a colored label with an optional leading icon,
/// suitable for category or status indicators.
///
/// Unlike `MinglitChip`, this widget is **never interactive** and focuses
/// on color customization. Unlike `MinglitBadge`, it supports an optional
/// icon and size variants.
///
/// {@tool snippet}
/// ```dart
/// MinglitTag(
///   label: '음악',
///   color: MinglitColors.primary,
/// )
/// ```
/// {@end-tool}
class MinglitTag extends StatelessWidget {
  /// Creates a read-only tag with [label] and [color].
  const MinglitTag({
    required this.label,
    required this.color,
    this.icon,
    this.size = MinglitTagSize.medium,
    super.key,
  });

  /// Text displayed inside the tag.
  final String label;

  /// Tag color used for background tint and text/icon color.
  final Color color;

  /// Optional leading icon.
  final IconData? icon;

  /// Tag size variant.
  final MinglitTagSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = color.withValues(alpha: MinglitOpacity.subtle);

    final (padding, textStyle, iconSize) = switch (size) {
      MinglitTagSize.small => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        theme.textTheme.labelSmall!.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        12.0,
      ),
      MinglitTagSize.medium => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall,
        ),
        theme.textTheme.labelMedium!.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        14.0,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: color),
              const SizedBox(width: MinglitSpacing.xsmall),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}

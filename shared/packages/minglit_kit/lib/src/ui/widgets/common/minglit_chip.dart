import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Size variants for [MinglitChip].
enum MinglitChipSize {
  /// Compact chip size.
  small,

  /// Default chip size.
  medium,

  /// Large chip size.
  large,
}

/// **Minglit Chip**
///
/// A standardized chip component for the Minglit design system.
/// Supports multiple sizes and color themes.
class MinglitChip extends StatelessWidget {
  /// Creates a standardized chip.
  const MinglitChip({
    required this.label,
    this.icon,
    this.size = MinglitChipSize.medium,
    this.color,
    this.onTap,
    super.key,
  });

  /// Text label displayed inside the chip.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Chip size variant.
  final MinglitChipSize size;

  /// Optional background color override.
  final Color? color;

  /// Optional tap handler for interactive chips.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fix #474: Determine padding, text style, icon size based on MinglitChipSize
    // small(10px)은 M3 슬롯 없음 — 극소 디버그용, fontSize 유지
    final (padding, labelStyle, iconSize) = switch (size) {
      MinglitChipSize.small => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        theme.textTheme.labelSmall!.copyWith(fontSize: 10),
        12.0,
      ),
      MinglitChipSize.medium => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xsmall,
        ),
        theme.textTheme.labelMedium!,
        14.0,
      ),
      MinglitChipSize.large => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall2,
        ),
        theme.textTheme.labelLarge!,
        16.0,
      ),
    };

    final bgColor =
        color ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final textColor = color != null
        ? (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface)
        : colorScheme.onSurfaceVariant;

    final widget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fix #136: Add vertical separator between icon and text for medium/large sizes
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            if (size == MinglitChipSize.small)
              const SizedBox(width: MinglitSpacing.xxsmall)
            else ...[
              const SizedBox(width: 4),
              Container(
                width: 1,
                height: iconSize - 2,
                color: colorScheme.outlineVariant,
              ),
              const SizedBox(width: 4),
            ],
          ],
          Text(
            label,
            style: labelStyle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        child: widget,
      );
    }

    return widget;
  }
}

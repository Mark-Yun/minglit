import 'package:flutter/material.dart';

enum MinglitChipSize {
  small,
  medium,
  large,
}

/// **Minglit Chip**
///
/// A standardized chip component for the Minglit design system.
/// Supports multiple sizes and color themes.
class MinglitChip extends StatelessWidget {
  const MinglitChip({
    required this.label,
    this.icon,
    this.size = MinglitChipSize.medium,
    this.color,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final MinglitChipSize size;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine padding and font size based on MinglitChipSize
    final (padding, fontSize, iconSize) = switch (size) {
      MinglitChipSize.small => (
        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        10.0,
        12.0,
      ),
      MinglitChipSize.medium => (
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        12.0,
        14.0,
      ),
      MinglitChipSize.large => (
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        14.0,
        16.0,
      ),
    };

    final bgColor =
        color ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final textColor = color != null
        ? (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
              ? Colors.white
              : Colors.black87)
        : colorScheme.onSurfaceVariant;

    final widget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
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
        borderRadius: BorderRadius.circular(100),
        child: widget,
      );
    }

    return widget;
  }
}

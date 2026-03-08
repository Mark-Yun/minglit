import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip.dart';

/// **Minglit Filter Chip**
///
/// A selectable chip for filtering and sorting in the Minglit design system.
/// Supports selected/unselected states with optional leading icons.
///
/// Use this for:
/// - Sort chips (single-select, with icon)
/// - Toggle filter chips (multi-toggle, with icon)
///
/// For read-only display chips, use [MinglitChip] instead.
class MinglitFilterChip extends StatelessWidget {
  /// Creates a selectable filter chip.
  const MinglitFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.size = MinglitChipSize.large,
    super.key,
  });

  /// Text label displayed inside the chip.
  final String label;

  /// Whether this chip is currently selected.
  final bool isSelected;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  /// Optional leading icon.
  /// If null, no icon is shown (text-only style).
  final IconData? icon;

  /// Chip size variant. Defaults to [MinglitChipSize.large].
  final MinglitChipSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // YouTube-style chip sizing
    // YT: font-size 1.4rem(14px), line-height 2rem(20px), weight 500
    final (padding, fontSize, iconSize) = switch (size) {
      MinglitChipSize.small => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        12.0,
        12.0,
      ),
      MinglitChipSize.medium => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall2,
        ),
        13.0,
        14.0,
      ),
      MinglitChipSize.large => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall,
        ),
        14.0,
        15.0,
      ),
    };

    // YouTube-style color inversion:
    // Unselected: light gray bg + dark text
    // Selected: dark bg + white text
    // YouTube-style color inversion (light mode):
    // Unselected: rgba(0,0,0,0.05) bg + #0f0f0f text
    // Selected: #0f0f0f bg + #fff text
    final bgColor = isSelected
        ? MinglitColors.textPrimary
        : MinglitColors.textPrimary.withValues(alpha: 0.05);

    final fgColor = isSelected
        ? MinglitColors.background
        : MinglitColors.textSecondary;

    final hasIcon = icon != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon) ...[
              Icon(icon, size: iconSize, color: fgColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: fontSize,
                height: 20 / fontSize, // YT line-height: 2rem
                color: fgColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_text_theme_extension.dart';
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

    // Fix #474: YouTube-style chip sizing — fontSize를 TextTheme/Extension 참조로 변경
    final ext = Theme.of(context).extension<MinglitTextThemeExtension>()!;
    final (padding, labelStyle, iconSize) = switch (size) {
      MinglitChipSize.small => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        theme.textTheme.labelMedium!, // 12px
        12.0,
      ),
      MinglitChipSize.medium => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall2,
        ),
        ext.chipLabel, // 13px
        14.0,
      ),
      MinglitChipSize.large => (
        const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall,
        ),
        theme.textTheme.labelLarge!, // 14px
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
        : MinglitColors.textPrimary.withValues(alpha: MinglitOpacity.tintFill);

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
              const SizedBox(width: MinglitSpacing.xsmall),
            ],
            Text(
              label,
              style: labelStyle.copyWith(
                height: 20 / (labelStyle.fontSize ?? 14),
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

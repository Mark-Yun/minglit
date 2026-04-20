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

    // Fix #1376: 다크모드 대응 — 하드코딩 색상 → colorScheme 시맨틱 컬러
    // YouTube-style color inversion (light/dark mode 공통):
    // Unselected: tinted surface bg + secondary text
    // Selected: onSurface bg + surface text
    final colorScheme = theme.colorScheme;
    final bgColor = isSelected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: MinglitOpacity.tintFill);

    final fgColor = isSelected
        ? colorScheme.surface
        : colorScheme.onSurfaceVariant;

    final hasIcon = icon != null;

    // Fix #1376: A11Y — 최소 터치 영역 48dp 보장 (WCAG / Material 가이드라인)
    // 시각적 칩 크기는 유지하고 투명 영역으로 터치 타겟만 확장
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
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
          ),
        ),
      ),
    );
  }
}

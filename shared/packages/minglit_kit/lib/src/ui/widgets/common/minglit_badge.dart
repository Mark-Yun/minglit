import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Badge**
///
/// A unified status badge widget for the Minglit design system.
/// Displays a colored label with rounded corners, suitable for
/// status indicators across the app (settlement, party, event, etc.).
///
/// Replaces ad-hoc badge implementations such as `SettlementStatusBadge`,
/// `PartyListItem._buildStatusBadge`, and other inline status badges.
///
/// {@tool snippet}
/// ```dart
/// MinglitBadge(
///   label: '승인됨',
///   color: Colors.green,
/// )
/// ```
/// {@end-tool}
class MinglitBadge extends StatelessWidget {
  /// Creates a status badge with [label] text and [color] tint.
  ///
  /// Set [compact] to `true` for a smaller variant with reduced padding
  /// and font size.
  const MinglitBadge({
    required this.label,
    required this.color,
    this.compact = false,
    super.key,
  });

  /// Text displayed inside the badge.
  final String label;

  /// Badge color used for background tint.
  /// The background uses a low-opacity version of this color,
  /// while the text uses the full color for contrast.
  final Color color;

  /// When `true`, renders a smaller badge with reduced padding and font size.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = color.withValues(alpha: MinglitOpacity.subtle);

    final padding = compact
        ? const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.small,
            vertical: MinglitSpacing.xxsmall,
          )
        : const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.sm,
            vertical: MinglitSpacing.xsmall,
          );

    final textStyle = compact
        ? theme.textTheme.labelSmall!.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          )
        : theme.textTheme.labelMedium!.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Padding(
        padding: padding,
        child: Text(label, style: textStyle),
      ),
    );
  }
}

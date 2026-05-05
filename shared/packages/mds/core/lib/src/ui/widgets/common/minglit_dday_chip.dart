import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';

/// D-day tier classification for [MinglitDDayChip].
enum _DDayTier { today, soon, later }

_DDayTier _tier(int daysUntil) {
  if (daysUntil <= 0) return _DDayTier.today;
  if (daysUntil <= 7) return _DDayTier.soon;
  return _DDayTier.later;
}

/// A chip widget that shows how many days until an event, with automatic
/// color-tier branching based on proximity.
///
/// - **today** (D-0 or past): warning amber text, 12% bg tint
/// - **soon** (D-1 to D-7): partner purple text, 10% bg tint
/// - **later** (D-8+): secondary text color, divider bg
///
/// {@tool snippet}
/// ```dart
/// MinglitDDayChip(daysUntil: 3)
/// MinglitDDayChip(daysUntil: 0, label: '오늘 마감')
/// ```
/// {@end-tool}
class MinglitDDayChip extends StatelessWidget {
  const MinglitDDayChip({
    required this.daysUntil,
    this.label,
    super.key,
  });

  /// Days remaining until the event. 0 = today, negative = past.
  final int daysUntil;

  /// Override label. When null: D-0 shows "오늘", D-N shows "D-$daysUntil".
  final String? label;

  String _defaultLabel() {
    if (daysUntil <= 0) return '오늘';
    return 'D-$daysUntil';
  }

  ({Color text, Color bg}) _colors(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (_tier(daysUntil)) {
      case _DDayTier.today:
        final textColor = isDark
            ? MinglitColorsDark.warning
            : MinglitColors.warning;
        return (
          text: textColor,
          bg: textColor.withValues(alpha: MinglitOpacity.skeletonBase),
        );
      case _DDayTier.soon:
        final textColor = isDark
            ? MinglitPartnerColorsDark.primary
            : MinglitPartnerColors.primary;
        return (
          text: textColor,
          bg: textColor.withValues(alpha: MinglitOpacity.highlight),
        );
      case _DDayTier.later:
        return (
          text: isDark
              ? MinglitColorsDark.textSecondary
              : MinglitColors.textSecondary,
          bg: isDark ? MinglitColorsDark.divider : MinglitColors.divider,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (:text, :bg) = _colors(theme);
    final displayLabel = label ?? _defaultLabel();

    // Fix #2216: Semantics label uses the caller-supplied label override first.
    // ExcludeSemantics prevents the inner Text node from appending a duplicate
    // label to the merged accessibility tree.
    return Semantics(
      label: label ?? (daysUntil <= 0 ? '오늘 진행' : '이벤트까지 $daysUntil일 남음'),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(MinglitRadius.chip),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
              vertical: MinglitSpacing.xxsmall,
            ),
            child: Text(
              displayLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: text,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
